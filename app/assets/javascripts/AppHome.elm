module AppHome exposing (Model, Msg, init, view, update, subscriptions)

import Shared
import Api
import Html exposing (..)
import Context
import Models exposing (MapViewport)


type alias Model =
    { query : String, suggestions : Shared.Suggestions, mapViewport : MapViewport }


type Msg
    = Search
    | Input String
    | Sug Api.SuggestionsMsg
    | ContextMsg Context.Msg


init : (Model -> model) -> (Msg -> msg) -> MapViewport -> ( model, Cmd msg )
init wmodel wmsg mapViewport =
    ( wmodel <| { query = "", suggestions = Nothing, mapViewport = mapViewport }, Cmd.none )


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

        ContextMsg msg ->
            let
                ( m, c ) =
                    Context.update (homeContext wmsg) msg model
            in
                ( wmodel m, c )


view : (Msg -> msg) -> Model -> Html msg
view wmsg model =
    Shared.mapWithControl <|
        Just <|
            Shared.suggestionsView model.query model.suggestions (wmsg Search) (\x -> wmsg <| Input x)


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions wmsg model =
    Context.subscriptions <| homeContext wmsg


homeContext : (Msg -> msg) -> Context.Context Model msg
homeContext wmsg =
    { setMapViewport = \mapViewport model -> { model | mapViewport = mapViewport }
    , wrapMessage = wmsg << ContextMsg
    }
