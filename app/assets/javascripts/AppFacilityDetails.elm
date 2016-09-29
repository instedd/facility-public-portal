module AppFacilityDetails exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Models exposing (MapViewport, Facility)
import Html exposing (..)
import Shared


type Model
    = Loading MapViewport Int
    | Loaded MapViewport Facility


type Msg
    = None


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    }


init : Host model msg -> MapViewport -> Int -> ( model, Cmd msg )
init h mapViewport facilityId =
    lift h <|
        ( Loading mapViewport facilityId, Cmd.none )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    lift h <|
        ( model, Cmd.none )


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            Html.h3 [] [ text "Loading... " ]


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    Sub.none


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ ->
            mapViewport

        Loaded mapViewport _ ->
            mapViewport


lift : Host model msg -> ( Model, Cmd msg ) -> ( model, Cmd msg )
lift h ( m, c ) =
    ( h.model m, c )
