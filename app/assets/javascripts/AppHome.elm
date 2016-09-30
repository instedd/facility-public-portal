module AppHome exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Api exposing (emptySearch)
import Commands
import Html exposing (..)
import Map
import Models exposing (MapViewport)
import Shared
import Utils exposing (mapFst)


type alias Model =
    { query : String, suggestions : Shared.Suggestions, mapViewport : MapViewport }


type Msg
    = Input String
    | Sug Api.SuggestionsMsg
    | MapViewportChanged MapViewport
    | ApiSearch Api.SearchMsg


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
    mapFst h.model <|
        ( { query = "", suggestions = Nothing, mapViewport = mapViewport }
        , Api.search (h.msg << ApiSearch) { emptySearch | latLng = Just mapViewport.center }
        )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    mapFst h.model <|
        case msg of
            Input query ->
                if query == "" then
                    ( { model | query = query, suggestions = Nothing }, Cmd.none )
                else
                    ( { model | query = query }, Api.getSuggestions (h.msg << Sug) (Just model.mapViewport.center) query )

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

            ApiSearch (Api.SearchSuccess results) ->
                let
                    addFacilities =
                        List.map Commands.addFacilityMarker results.items
                in
                    -- TODO keep loading more results until map bounds exceeded
                    model ! addFacilities

            ApiSearch _ ->
                -- TODO handle error
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
