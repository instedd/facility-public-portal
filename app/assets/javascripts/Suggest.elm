module Suggest exposing (Config, Model, Msg(..), PrivateMsg, init, empty, update, hasSuggestionsToShow, viewInput, viewInputWith, viewSuggestions, advancedSearchWindow)

import Shared exposing (icon)
import Api
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Models exposing (MapViewport, SearchSpec, FacilityType)
import String
import Debounce
import I18n exposing (..)


type alias Config =
    { mapViewport : MapViewport }


type alias Model =
    { query : SearchSpec, suggestions : Maybe (List Models.Suggestion), d : Debounce.State, advanced : Bool }


type PrivateMsg
    = Input String
    | ApiSug Api.SuggestionsMsg
    | FetchSuggestions
    | Deb (Debounce.Msg Msg)
    | ToggleAdvancedSearch
    | SetAdvancedSearchName String
    | SetAdvancedSearchType Int


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search String
    | Private PrivateMsg
    | FullSearch SearchSpec


hasSuggestionsToShow : Model -> Bool
hasSuggestionsToShow model =
    let
        a =
            Maybe.withDefault "" model.query.q
    in
        (a /= "") && (model.suggestions /= Nothing)


empty : Model
empty =
    init ""


init : String -> Model
init query =
    { query = initSearch query, suggestions = Nothing, d = Debounce.init, advanced = False }


initSearch : String -> SearchSpec
initSearch q =
    { q = Just q
    , s = Nothing
    , l = Nothing
    , latLng = Nothing
    , fType = Nothing
    }


searchSuggestions : Config -> String -> Model -> ( Model, Cmd Msg )
searchSuggestions config query model =
    ( { model | query = initSearch query, suggestions = Nothing }, Api.getSuggestions (Private << ApiSug) (Just config.mapViewport.center) query )


update : Config -> Msg -> Model -> ( Model, Cmd Msg )
update config msg model =
    case msg of
        Private msg ->
            case msg of
                Input query ->
                    if query == "" then
                        ( empty, Cmd.none )
                    else
                        ( { model | query = initSearch query, suggestions = Nothing }, debCmd (Private FetchSuggestions) )

                FetchSuggestions ->
                    let
                        a =
                            Maybe.withDefault "" model.query.q
                    in
                        searchSuggestions config a model

                ApiSug msg ->
                    case msg of
                        Api.SuggestionsSuccess query suggestions ->
                            let
                                a =
                                    Maybe.withDefault "" model.query.q
                            in
                                if (query == a) then
                                    ( { model | suggestions = Just suggestions }, Cmd.none )
                                else
                                    -- ignore old requests
                                    ( model, Cmd.none )

                        Api.SuggestionsFailed e ->
                            -- TODO
                            ( model, Cmd.none )

                Deb a ->
                    Debounce.update cfg a model

                ToggleAdvancedSearch ->
                    if not (isAdvancedSearchOpen model) then
                        ( { model | advanced = True }, Cmd.none )
                    else
                        ( { model | advanced = False }, Cmd.none )

                SetAdvancedSearchName search ->
                    let
                        query =
                            { q = Just search, l = model.query.l, s = model.query.s, latLng = model.query.latLng, fType = model.query.fType }
                    in
                        ( { model | query = query }, Cmd.none )

                SetAdvancedSearchType search ->
                    let
                        query =
                            { q = model.query.q, l = model.query.l, s = model.query.s, latLng = model.query.latLng, fType = Just search }
                    in
                        ( { model | query = query }, Cmd.none )

        _ ->
            -- public events
            ( model, Cmd.none )


cfg : Debounce.Config Model Msg
cfg =
    Debounce.config .d (\model s -> { model | d = s }) (Private << Deb) 200


debCmd =
    Debounce.debounceCmd cfg


viewInput : Model -> Html Msg
viewInput model =
    viewInputWith identity model (icon "search")


viewInputWith : (Msg -> a) -> Model -> Html a -> Html a
viewInputWith wmsg model trailing =
    let
        a =
            Maybe.withDefault "" model.query.q
    in
        Shared.searchBar a (wmsg <| Search a) (wmsg << Private << Input) trailing


viewSuggestions : Model -> List (Html Msg)
viewSuggestions model =
    case model.suggestions of
        Nothing ->
            []

        Just s ->
            [ suggestionsContent s ] ++ advancedSearchFooter


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
        div [ class "collection results content" ] entries


suggestion : Models.Suggestion -> Html Msg
suggestion s =
    case s of
        Models.F { id, name, facilityType, adm } ->
            a
                [ class "collection-item avatar suggestion"
                , onClick <| FacilityClicked id
                ]
                [ icon "local_hospital"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text (adm |> List.drop 1 |> List.reverse |> String.join ", ") ]
                ]

        Models.S { id, name, facilityCount } ->
            a
                [ class "collection-item avatar suggestion"
                , onClick <| ServiceClicked id
                ]
                [ icon "label"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text <| t (FacilitiesCount { count = facilityCount }) ]
                ]

        Models.L { id, name, parentName } ->
            a
                [ class "collection-item avatar suggestion"
                , onClick <| LocationClicked id
                ]
                [ icon "location_on"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text <| Maybe.withDefault "" parentName ]
                ]


advancedSearchFooter =
    [ div
        [ class "footer" ]
        [ a [ href "#", Shared.onClick (Private ToggleAdvancedSearch) ] [ text "Advanced Search" ] ]
    ]


isAdvancedSearchOpen : Model -> Bool
isAdvancedSearchOpen model =
    model.advanced


advancedSearchWindow : Model -> List FacilityType -> List (Html Msg)
advancedSearchWindow model types =
    let
        query =
            Maybe.withDefault "" model.query.q

        selectedType =
            Maybe.withDefault 0 model.query.fType
    in
        if isAdvancedSearchOpen model then
            Shared.modalWindow
                [ text "Advanced Search"
                , a [ href "#", class "right", Shared.onClick (Private ToggleAdvancedSearch) ] [ Shared.icon "close" ]
                ]
                [ Html.form [ action "#", method "GET" ]
                    [ label [ for "q" ] [ text "Facility name" ]
                    , input [ id "q", type' "text", value query, onInput (Private << SetAdvancedSearchName) ] []
                    , label [] [ text "Facility type" ]
                    , Html.select [ Shared.onSelect (Private << SetAdvancedSearchType) ] (selectOptions types selectedType)
                    ]
                ]
                [ a [ href "#", class "btn-flat", Shared.onClick (FullSearch model.query) ] [ text "Search" ] ]
            -- TODO
        else
            []


selectOptions : List FacilityType -> Int -> List (Html a)
selectOptions types selectedType =
    [ Html.option [ value "0" ] [ text "" ] ]
        ++ (List.map
                (\ftype ->
                    if selectedType == ftype.id then
                        Html.option [ value (toString ftype.id), selected True ] [ text ftype.name ]
                    else
                        Html.option [ value (toString ftype.id) ] [ text ftype.name ]
                )
                types
           )
