module AppSearch exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Shared
import Api
import Html exposing (..)
import Context
import Models exposing (MapViewport, SearchSpec)
import Utils exposing (mapFst)


type alias Model =
    { query : SearchSpec, mapViewport : MapViewport }


type Msg
    = ContextMsg Context.Msg


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    }


init : Host model msg -> SearchSpec -> MapViewport -> ( model, Cmd msg )
init h query mapViewport =
    mapFst h.model <|
        ( { query = query, mapViewport = mapViewport }, Cmd.none )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    mapFst h.model <|
        case msg of
            ContextMsg msg ->
                -- TODO update search when viewport changes
                Context.update (hostContext h) msg model


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            Html.h3 [] [ text "Search..." ]


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
