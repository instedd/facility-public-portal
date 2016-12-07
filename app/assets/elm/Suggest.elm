module Suggest
    exposing
        ( Config
        , Model
        , Msg(..)
        , PrivateMsg
        , init
        , empty
        , update
        , subscriptions
        , hasContent
        , viewInput
        , viewInputWith
        , viewBody
        , advancedSearch
        , mobileAdvancedSearch
        , expandedView
        )

import AdvancedSearch
import Api
import Array
import Debounce
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import I18n exposing (..)
import InfScroll
import Layout
import List
import Models exposing (MapViewport, SearchSpec, FacilitySummary, FacilityType, Ownership, Sorting(..), emptySearch, querySearch)
import Return
import SelectList exposing (include, iff)
import Shared exposing (icon)
import String
import String
import Svg
import Svg.Attributes
import Utils exposing (perform)


type alias Config =
    { mapViewport : MapViewport }


type alias Model =
    { query : String
    , advancedSearch : AdvancedSearch.Model
    , suggestions : Maybe (List Models.Suggestion)
    , d : Debounce.State
    , advanced : Bool
    , expandedResults : Maybe Models.SearchResult
    , infScrollPendingUrl : Bool
    , downloadLink : String
    , apiLink : String
    }


type PrivateMsg
    = Input String
    | ApiSug Api.SuggestionsMsg
    | FetchSuggestions
    | Deb (Debounce.Msg Msg)
    | AdvancedSearchMsg AdvancedSearch.Msg
    | ExpandedApiSearch Bool Api.SearchMsg
    | InfScrollMsg InfScroll.Msg
    | ExpandedSearchLoadMore
    | SortingChanged Sorting


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search SearchSpec
    | Private PrivateMsg
    | UnhandledError String


hasContent : Model -> Bool
hasContent model =
    model.advanced || (model.query /= "") && (model.suggestions /= Nothing)


empty : Models.Settings -> MapViewport -> ( Model, Cmd Msg )
empty settings mapViewport =
    init settings mapViewport emptySearch


init : Models.Settings -> MapViewport -> SearchSpec -> ( Model, Cmd Msg )
init settings mapViewport search =
    let
        ( advancedSearchModel, advancedSearchCmd ) =
            AdvancedSearch.init settings.facilityTypes settings.ownerships search
    in
        Return.singleton
            { query = Maybe.withDefault "" search.q
            , advancedSearch = advancedSearchModel
            , suggestions = Nothing
            , d = Debounce.init
            , advanced = False
            , expandedResults = Nothing
            , infScrollPendingUrl = False
            , downloadLink = Utils.buildPath "/api/dump" (Models.searchParams search)
            , apiLink = Utils.buildPath "/api/search" (Models.searchParams search)
            }
            |> Return.command (Cmd.map (Private << AdvancedSearchMsg) advancedSearchCmd)
            |> Return.command (searchFirstPageStartingFrom (AdvancedSearch.search advancedSearchModel) mapViewport.center)


clear : Model -> Model
clear model =
    { model
        | query = ""
        , suggestions = Nothing
        , d = Debounce.init
        , advanced = False
    }


searchSuggestions : Config -> Model -> ( Model, Cmd Msg )
searchSuggestions config model =
    ( { model | suggestions = Nothing }, Api.getSuggestions (Private << ApiSug) (Just config.mapViewport.center) model.query )


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        Private msg ->
            case msg of
                Input query ->
                    if query == "" then
                        Return.singleton (clear model)
                    else
                        ( { model | query = query, suggestions = Nothing }, debCmd (Private FetchSuggestions) )

                FetchSuggestions ->
                    searchSuggestions config model

                ApiSug msg ->
                    case msg of
                        Api.SuggestionsSuccess query suggestions ->
                            if (query == model.query) then
                                ( { model | suggestions = Just suggestions }, Cmd.none )
                            else
                                -- ignore old requests
                                ( model, Cmd.none )

                        Api.SuggestionsFailed e ->
                            -- TODO
                            ( model, Cmd.none )

                Deb a ->
                    Debounce.update cfg a model

                AdvancedSearchMsg msg ->
                    case msg of
                        AdvancedSearch.Toggle ->
                            ( { model | advanced = not model.advanced }, Cmd.none )

                        AdvancedSearch.Perform search ->
                            Return.singleton model
                                |> perform (Search search)

                        AdvancedSearch.UnhandledError msg ->
                            Return.singleton model
                                |> perform (UnhandledError msg)

                        _ ->
                            AdvancedSearch.update model.advancedSearch msg
                                |> Return.mapBoth (Private << AdvancedSearchMsg) (setAdvancedSearch model)

                InfScrollMsg msg ->
                    InfScroll.update scrollCfg model msg

                ExpandedSearchLoadMore ->
                    case ( model.expandedResults, model.infScrollPendingUrl ) of
                        ( Just expandedResults, False ) ->
                            { model | infScrollPendingUrl = True }
                                ! [ Api.searchMore (Private << (ExpandedApiSearch False)) expandedResults
                                  ]

                        ( _, _ ) ->
                            ( model, Cmd.none )

                ExpandedApiSearch initial (Api.SearchSuccess results) ->
                    let
                        updatedExpandedResults =
                            if initial then
                                Just results
                            else
                                Models.extend model.expandedResults (Just results)
                    in
                        ( { model | infScrollPendingUrl = False, expandedResults = updatedExpandedResults }, Cmd.none )

                ExpandedApiSearch _ (Api.SearchFailed e) ->
                    Return.singleton model
                        |> perform (UnhandledError (toString e))

                SortingChanged sorting ->
                    AdvancedSearch.updateSorting sorting model.advancedSearch
                        |> Return.mapBoth (Private << AdvancedSearchMsg) (setAdvancedSearch model)

        _ ->
            -- public events
            ( model, Cmd.none )


cfg : Debounce.Config Model Msg
cfg =
    Debounce.config .d (\model s -> { model | d = s }) (Private << Deb) 200


debCmd =
    Debounce.debounceCmd cfg


subscriptions : Sub Msg
subscriptions =
    Sub.map (Private << AdvancedSearchMsg) AdvancedSearch.subscriptions


viewInput : Model -> Html Msg
viewInput model =
    viewInputWith identity model (icon "search")


viewInputWith : (Msg -> a) -> Model -> Html a -> Html a
viewInputWith wmsg model trailing =
    let
        submitMsg =
            wmsg <| Search (querySearch model.query)

        inputMsg =
            wmsg << Private << Input

        actions =
            div [ class "actions" ]
                [ trailing
                , Html.App.map wmsg (advancedSearchIcon model)
                ]

        inputBar =
            if model.advanced then
                span [ class "single-line title" ] [ text <| t AdvancedSearch ]
            else
                Html.form [ action "#", method "GET", autocomplete False, onSubmit submitMsg ]
                    [ input
                        [ type' "search"
                        , placeholder <| t SearchHealthFacility
                        , value model.query
                        , autofocus True
                        , onInput inputMsg
                        ]
                        []
                    ]
    in
        div [ class "search-box" ]
            [ div [ class "search" ]
                [ inputBar
                , actions
                ]
            ]


expandedView : Model -> Layout.ExpandedView Msg
expandedView model =
    let
        results =
            model.expandedResults

        sideTop =
            div [ class "search-box" ]
                [ div [ class "search" ]
                    [ span [ class "single-line title" ] [ text <| t AdvancedSearch ]
                    , div [ class "actions" ] []
                    ]
                ]

        sideBottom =
            advancedSearch model

        resultList =
            results
                |> Maybe.map .items
                |> Maybe.withDefault []

        totalText =
            results
                |> Maybe.map (\{ total } -> t (FacilitiesCount { count = total }))
                |> Maybe.withDefault ""

        mainTop =
            div [ class "expanded-search-top single-line" ]
                [ div [ class "expand" ]
                    [ strong [ class "count" ] [ text <| totalText ]
                    , sortingSelector model
                    ]
                , div []
                    [ a [ href model.downloadLink ] [ Shared.icon "get_app", text <| t DownloadResult ]
                    , text "or"
                    , a [ href model.apiLink ] [ text <| t AccessTheMfrApi ]
                    ]
                ]

        mainBottom =
            [ div [ class "collection results" ]
                [ results
                    |> Maybe.map (\r -> InfScroll.view scrollCfg model r.items)
                    |> Maybe.withDefault (div [] [])
                ]
            ]
    in
        { side =
            Layout.contentWithTopBar
                sideTop
                sideBottom
        , main =
            Layout.contentWithTopBar
                mainTop
                mainBottom
        }


scrollCfg : InfScroll.Config Model Models.FacilitySummary Msg
scrollCfg =
    InfScroll.Config
        { loadMore = \m -> Private ExpandedSearchLoadMore
        , msgWrapper = Private << InfScrollMsg
        , itemView = facilityResultItem True
        , loadingIndicator = div [ class "progress" ] [ div [ class "indeterminate" ] [] ]
        , hasMore =
            \m ->
                m.expandedResults
                    |> Maybe.map (\results -> results.nextUrl /= Nothing)
                    |> Maybe.withDefault True
        }


sortingSelector : Model -> Html Msg
sortingSelector model =
    let
        options =
            Array.fromList
                [ Models.Distance
                , Models.Name
                , Models.Type
                ]

        optionLabel s =
            case s of
                Models.Distance ->
                    t I18n.Distance

                Models.Name ->
                    t I18n.Name

                Models.Type ->
                    t I18n.FacilityType

        onSelect index =
            case Array.get index options of
                Just sorting ->
                    Private <| SortingChanged <| sorting

                Nothing ->
                    Debug.crash "Invalid option"

        renderOption sorting =
            option
                [ selected (sorting == AdvancedSearch.sorting model.advancedSearch) ]
                [ text <| optionLabel sorting ]
    in
        div [ class "sorting-select" ]
            [ text <| t SortBy
            , select
                [ Shared.onSelect onSelect ]
                (options |> Array.map renderOption |> Array.toList)
            ]


advancedSearchIcon : Model -> Html Msg
advancedSearchIcon model =
    a
        [ href "#"
        , Shared.onClick (Private (AdvancedSearchMsg AdvancedSearch.Toggle))
        , classList [ ( "active", not (AdvancedSearch.isEmpty model.advancedSearch) ) ]
        ]
        [ filterIcon model ]


filterIcon : Model -> Html a
filterIcon model =
    let
        class =
            (if AdvancedSearch.isEmpty model.advancedSearch then
                ""
             else
                "active"
            )
    in
        Svg.svg
            [ Svg.Attributes.class class
            , Svg.Attributes.viewBox "0 0 24 24"
            ]
            [ Svg.path [ Svg.Attributes.d "M22,4l-8,8v8H10V12L2,4Z" ] []
            ]


viewBody : Model -> List (Html Msg)
viewBody model =
    if model.advanced then
        Shared.lmap (Private << AdvancedSearchMsg) <|
            [ div [ class "hide-on-med-and-down" ] <|
                AdvancedSearch.embeddedView model.advancedSearch
            ]
    else
        case model.suggestions of
            Nothing ->
                []

            Just s ->
                [ suggestionsContent s ]


advancedSearch : Model -> List (Html Msg)
advancedSearch model =
    Shared.lmap (Private << AdvancedSearchMsg) <|
        AdvancedSearch.embeddedView model.advancedSearch


suggestionsContent : List Models.Suggestion -> Html Msg
suggestionsContent s =
    let
        entries =
            case s of
                [] ->
                    [ div
                        [ class "no-results" ]
                        [ span [ class "search-icon" ] [ icon "find_in_page" ]
                        , text "No results found"
                        ]
                    ]

                _ ->
                    List.map suggestion s
    in
        div [ class "content collection results" ] entries


suggestion : Models.Suggestion -> Html Msg
suggestion s =
    case s of
        Models.F facility ->
            facilityResultItem False facility

        Models.S { id, name, facilityCount } ->
            resultItem
                name
                [ text <| t <| FacilitiesCount { count = facilityCount } ]
                "label"
                (ServiceClicked id)

        Models.L { id, name, parentName } ->
            resultItem
                name
                [ text (Maybe.withDefault "" parentName) ]
                "location_on"
                (LocationClicked id)


facilityResultItem : Bool -> FacilitySummary -> Html Msg
facilityResultItem includeType f =
    let
        sub =
            SelectList.select <|
                [ iff includeType <|
                    p [] [ text f.facilityType ]
                , include <|
                    p [] [ text (locationLabel f) ]
                ]
    in
        resultItem
            f.name
            sub
            "local_hospital"
            (FacilityClicked f.id)


resultItem : String -> List (Html Msg) -> String -> Msg -> Html Msg
resultItem t sub iconName clickMsg =
    a
        [ class "collection-item avatar suggestion"
        , onClick <| clickMsg
        ]
        [ icon iconName
        , span [ class "title" ] [ text t ]
        , div [ class "sub" ]
            sub
        ]


locationLabel : FacilitySummary -> String
locationLabel facility =
    facility.adm
        |> List.drop 1
        |> List.reverse
        |> String.join ", "


mobileAdvancedSearch : Model -> List (Html Msg)
mobileAdvancedSearch model =
    Shared.lmap (Private << AdvancedSearchMsg) <|
        if model.advanced then
            [ div [ class "hide-on-large-only" ] <|
                AdvancedSearch.modalView model.advancedSearch
            ]
        else
            []


setAdvancedSearch : Model -> AdvancedSearch.Model -> Model
setAdvancedSearch model advancedSearch =
    { model | advancedSearch = advancedSearch }


isAdvancedSearchOpen : Model -> Bool
isAdvancedSearchOpen model =
    model.advanced


searchFirstPageStartingFrom : SearchSpec -> Models.LatLng -> Cmd Msg
searchFirstPageStartingFrom searchSpec latLng =
    Api.search (Private << (ExpandedApiSearch True)) { searchSpec | latLng = Just latLng, size = Just 50 }
