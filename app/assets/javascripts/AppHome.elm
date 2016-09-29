module AppHome exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Shared
import Api
import Html exposing (..)
import Context
import Models exposing (MapViewport)


type alias Model =
    { query : String, suggestions : Shared.Suggestions, mapViewport : MapViewport }


type Msg
    = Input String
    | Sug Api.SuggestionsMsg
    | ContextMsg Context.Msg


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    , facilityClicked : Int -> msg
    , search : String -> msg
    }


init : Host model msg -> MapViewport -> ( model, Cmd msg )
init h mapViewport =
    ( h.model <| { query = "", suggestions = Nothing, mapViewport = mapViewport }, Cmd.none )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    case msg of
        Input query ->
            if query == "" then
                ( h.model { model | query = query, suggestions = Nothing }, Cmd.none )
            else
                -- TODO change Nothing for mapViewport.center
                ( h.model { model | query = query }, Api.getSuggestions (h.msg << Sug) Nothing query )

        Sug msg ->
            case msg of
                Api.SuggestionsSuccess query suggestions ->
                    if (query == model.query) then
                        h.model { model | suggestions = Just suggestions } ! [ Cmd.none ]
                    else
                        -- ignore old requests
                        h.model model ! [ Cmd.none ]

                -- Ignore out of order results
                Api.SuggestionsFailed e ->
                    -- TODO
                    ( h.model model, Cmd.none )

        ContextMsg msg ->
            lift h <| Context.update (hostContext h) msg model


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            Shared.suggestionsView
                { facilityClicked = h.facilityClicked
                , submit = h.search model.query
                , input = h.msg << Input
                }
                model.query
                model.suggestions


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    Context.subscriptions <| hostContext h


hostContext : Host model msg -> Context.Host Model msg
hostContext h =
    { setMapViewport = \mapViewport model -> { model | mapViewport = mapViewport }
    , msg = h.msg << ContextMsg
    }


mapViewport : Model -> MapViewport
mapViewport model =
    model.mapViewport


lift : Host model msg -> ( Model, Cmd msg ) -> ( model, Cmd msg )
lift h ( m, c ) =
    ( h.model m, c )
