module AppHome exposing (Model, Msg, init, view, update)

import Shared
import Api
import Html exposing (..)


type alias Model =
    { query : String, suggestions : Shared.Suggestions }


type Msg
    = Search
    | Input String
    | Sug Api.SuggestionsMsg


init : (Model -> model) -> (Msg -> msg) -> ( model, Cmd msg )
init wmodel wmsg =
    ( wmodel <| { query = "", suggestions = Nothing }, Cmd.none )


update : (Model -> model) -> (Msg -> msg) -> Msg -> Model -> ( model, Cmd msg )
update wmodel wmsg msg model =
    case msg of
        Search ->
            ( wmodel model, Cmd.none )

        Input query ->
            if query == "" then
                ( wmodel { model | query = query, suggestions = Nothing }, Cmd.none )
            else
                -- TODO change Nothing for mapViewport.center
                ( wmodel { model | query = query }, Api.getSuggestions (wmsg << Sug) Nothing query )

        Sug msg ->
            case msg of
                Api.SuggestionsSuccess query suggestions ->
                    if (query == model.query) then
                        wmodel { model | suggestions = Just suggestions } ! [ Cmd.none ]
                    else
                        -- ignore old requests
                        wmodel model ! [ Cmd.none ]

                -- Ignore out of order results
                Api.SuggestionsFailed e ->
                    -- TODO
                    ( wmodel model, Cmd.none )


view : (Msg -> msg) -> Model -> Html msg
view wmsg model =
    Shared.mapWithControl <|
        Just <|
            Shared.suggestionsView model.query model.suggestions (wmsg Search) (\x -> wmsg <| Input x)
