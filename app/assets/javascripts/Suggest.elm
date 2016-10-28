module Suggest exposing (Config, Model, Msg(..), PrivateMsg, init, keyboardSubscriptions, empty, update, hasSuggestionsToShow, viewInput, viewInputWith, viewSuggestions, advancedSearchWindow, handleKey)

import Shared exposing (icon)
import Api
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Models exposing (MapViewport, SearchSpec, FacilityType)
import String
import Debounce
import I18n exposing (..)
import NavegableList exposing (..)
import KeyboardControl


type alias Config =
    { mapViewport : MapViewport }


type alias Model =
    { query : String, advancedSearch : SearchSpec, suggestions : Maybe (NavegableList Models.Suggestion), d : Debounce.State, advanced : Bool }


type PrivateMsg
    = Input String
    | ApiSug Api.SuggestionsMsg
    | Key KeyboardControl.ControlKey
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
    (model.query /= "") && (model.suggestions /= Nothing)


empty : Model
empty =
    init ""


init : String -> Model
init query =
    { query = query, advancedSearch = Api.emptySearch, suggestions = Nothing, d = Debounce.init, advanced = False }


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
                        ( empty, Cmd.none )
                    else
                        ( { model | query = query, suggestions = Nothing }, debCmd (Private FetchSuggestions) )

                FetchSuggestions ->
                    searchSuggestions config model

                ApiSug msg ->
                    case msg of
                        Api.SuggestionsSuccess query suggestions ->
                            if (query == model.query) then
                                ( { model | suggestions = Just (fromList suggestions) }, Cmd.none )
                            else
                                -- ignore old requests
                                ( model, Cmd.none )

                        Api.SuggestionsFailed e ->
                            -- TODO
                            ( model, Cmd.none )

                Key k ->
                    handleKey model k

                Deb a ->
                    Debounce.update cfg a model

                ToggleAdvancedSearch ->
                    if not (isAdvancedSearchOpen model) then
                        ( { model | advanced = True }, Cmd.none )
                    else
                        ( { model | advanced = False }, Cmd.none )

                SetAdvancedSearchName search ->
                    let
                        currentSearch =
                            model.advancedSearch
                    in
                        ( { model | advancedSearch = { currentSearch | q = Just search } }, Cmd.none )

                SetAdvancedSearchType t ->
                    let
                        currentSearch =
                            model.advancedSearch
                    in
                        ( { model | advancedSearch = { currentSearch | t = Just t } }, Cmd.none )

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
    Shared.searchBar model.query (wmsg << Private << Input) trailing


viewSuggestions : Model -> List (Html Msg)
viewSuggestions model =
    case model.suggestions of
        Nothing ->
            []

        Just s ->
            [ displaySuggestions s, advancedSearchFooter ]


displaySuggestions : NavegableList Models.Suggestion -> Html Msg
displaySuggestions suggestions =
    let
        content =
            if NavegableList.isEmpty suggestions then
                [ div
                    [ class "no-results" ]
                    [ span [ class "search-icon" ] [ icon "find_in_page" ]
                    , text "No results found"
                    ]
                ]
            else
                List.map (uncurry suggestion) (toListWithFocus suggestions)
    in
        div [ class "content collection results" ] content


suggestion : Models.Suggestion -> Bool -> Html Msg
suggestion s isFocused =
    case s of
        Models.F { id, name, facilityType, adm } ->
            a
                [ classList [ ( "collection-item avatar suggestion", True ), ( "active", isFocused ) ]
                , onClick <| FacilityClicked id
                ]
                [ icon "local_hospital"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text (adm |> List.drop 1 |> List.reverse |> String.join ", ") ]
                ]

        Models.S { id, name, facilityCount } ->
            a
                [ classList [ ( "collection-item avatar suggestion", True ), ( "active", isFocused ) ]
                , onClick <| ServiceClicked id
                ]
                [ icon "label"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text <| t (FacilitiesCount { count = facilityCount }) ]
                ]

        Models.L { id, name, parentName } ->
            a
                [ classList [ ( "collection-item avatar suggestion", True ), ( "active", isFocused ) ]
                , onClick <| LocationClicked id
                ]
                [ icon "location_on"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text <| Maybe.withDefault "" parentName ]
                ]


advancedSearchFooter =
    div
        [ class "footer" ]
        [ a [ href "#", Shared.onClick (Private ToggleAdvancedSearch) ] [ text "Advanced Search" ] ]


isAdvancedSearchOpen : Model -> Bool
isAdvancedSearchOpen model =
    model.advanced


advancedSearchWindow : Model -> List FacilityType -> List (Html Msg)
advancedSearchWindow model types =
    let
        query =
            Maybe.withDefault "" model.advancedSearch.q

        selectedType =
            Maybe.withDefault 0 model.advancedSearch.t
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
                [ a [ href "#", class "btn-flat", Shared.onClick (FullSearch model.advancedSearch) ] [ text "Search" ] ]
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


enterSuggestion : Models.Suggestion -> Msg
enterSuggestion s =
    case s of
        Models.F { id } ->
            FacilityClicked id

        Models.S { id } ->
            ServiceClicked id

        Models.L { id } ->
            LocationClicked id


keyboardSubscriptions : Sub Msg
keyboardSubscriptions =
    Sub.map (Private << Key) KeyboardControl.subscriptions


handleKey : Model -> KeyboardControl.ControlKey -> ( Model, Cmd Msg )
handleKey model key =
    case model.suggestions of
        Nothing ->
            ( model, Cmd.none )

        Just entries ->
            let
                ( entries', cmds ) =
                    KeyboardControl.handleKey (Search model.query) enterSuggestion key entries
            in
                ( { model | suggestions = Just entries' }, cmds )
