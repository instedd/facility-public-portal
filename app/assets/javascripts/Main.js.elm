module Main exposing (..)

import Commands exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Navigation
import Routing
import Update
import View


type alias Flags =
    { fakeUserPosition : Bool
    , initialPosition : LatLng
    }


main : Program Flags
main =
    Navigation.programWithFlags Routing.parser
        { init = init
        , view = View.view
        , update = Update.update
        , subscriptions = subscriptions
        , urlUpdate = Update.urlUpdate
        }


init : Flags -> Result String Route -> ( AppModel, Cmd Msg )
init flags route =
    let
        fakeLocation =
            if flags.fakeUserPosition then
                Just flags.initialPosition
            else
                Nothing

        model =
            Initializing route fakeLocation

        cmds =
            [ Commands.initializeMap flags.initialPosition ]
    in
        model ! cmds


subscriptions : AppModel -> Sub Msg
subscriptions model =
    Sub.batch
        [ facilityMarkerClicked (\id -> Navigate (FacilityRoute id))
        , mapViewportChanged (\viewPort -> MapViewportChanged viewPort)
        ]
