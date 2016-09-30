module AppHome exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Shared
import Api
import Html exposing (..)
import Map
import Models exposing (MapViewport)
import Utils exposing (mapFst)


type alias Model =
    { query : String, suggestions : Shared.Suggestions, mapViewport : MapViewport }


type Msg
    = Input String
    | Sug Api.SuggestionsMsg
    | MapViewportChanged MapViewport


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    , facilityClicked : Int -> msg
    , serviceClicked : Int -> msg
    , locationClicked : Int -> msg
    , search : String -> msg
    }


init : Host model msg -> MapViewport -> ( model, Cmd msg )
init h mapViewport =
    ( h.model <| { query = "", suggestions = Nothing, mapViewport = mapViewport }, Cmd.none )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    mapFst h.model <|
        case msg of
            Input query ->
                if query == "" then
                    ( { model | query = query, suggestions = Nothing }, Cmd.none )
                else
                    -- TODO change Nothing for mapViewport.center
                    ( { model | query = query }, Api.getSuggestions (h.msg << Sug) Nothing query )

            Sug msg ->
                case msg of
                    Api.SuggestionsSuccess query suggestions ->
                        if (query == model.query) then
                            ( { model | suggestions = Just suggestions }, Cmd.none )
                        else
                            -- ignore old requests
                            ( model, Cmd.none )

                    -- Ignore out of order results
                    Api.SuggestionsFailed e ->
                        -- TODO
                        ( model, Cmd.none )

            MapViewportChanged mapViewport ->
                ( { model | mapViewport = mapViewport }, Cmd.none )


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            Shared.suggestionsView
                { facilityClicked = h.facilityClicked
                , serviceClicked = h.serviceClicked
                , locationClicked = h.locationClicked
                , submit = h.search model.query
                , input = h.msg << Input
                }
                model.query
                model.suggestions


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    Map.subscriptions <| hostMap h


hostMap : Host model msg -> Map.Host msg
hostMap h =
    { mapViewportChanged = h.msg << MapViewportChanged
    , facilityMarkerClicked = h.facilityClicked
    }


mapViewport : Model -> MapViewport
mapViewport model =
    model.mapViewport
