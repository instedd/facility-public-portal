module Suggest exposing (Config, Model, Msg(..), PrivateMsg, init, empty, update, hasSuggestionsToShow, viewInput, viewInputWith, viewSuggestions)

import Shared exposing (icon)
import Api
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Models exposing (MapViewport)
import String
import Debounce


type alias Config =
    { mapViewport : MapViewport }


type alias Model =
    { query : String, suggestions : Maybe (List Models.Suggestion), d : Debounce.State }


type PrivateMsg
    = Input String
    | ApiSug Api.SuggestionsMsg
    | FetchSuggestions
    | Deb (Debounce.Msg Msg)


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search String
    | Private PrivateMsg


hasSuggestionsToShow : Model -> Bool
hasSuggestionsToShow model =
    (model.query /= "") && (model.suggestions /= Nothing)


empty : Model
empty =
    init ""


init : String -> Model
init query =
    { query = query, suggestions = Nothing, d = Debounce.init }


searchSuggestions : Config -> String -> Model -> ( Model, Cmd Msg )
searchSuggestions config query model =
    ( { model | query = query, suggestions = Nothing }, Api.getSuggestions (Private << ApiSug) (Just config.mapViewport.center) query )


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
                    searchSuggestions config model.query model

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
    Shared.searchBar model.query (wmsg <| Search model.query) (wmsg << Private << Input) trailing


viewSuggestions : Model -> List (Html Msg)
viewSuggestions model =
    case model.suggestions of
        Nothing ->
            []

        Just s ->
            [ suggestionsContent s ]


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
                    [ text <| toString facilityCount ++ " facilities" ]
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
