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


init : Flags -> Result String Routing.Route -> ( Model, Cmd Msg )
init flags route =
    let
        fakeLocation =
            if flags.fakeUserPosition then
                Just flags.initialPosition
            else
                Nothing

        model =
            { query = ""
            , userLocation = NoLocation
            , fakeLocation = fakeLocation
            , suggestions = Nothing
            , results = Nothing
            , facility = Nothing
            , hideResults = False
            }

        cmds =
            [ Commands.initializeMap flags.initialPosition
            , Routing.navigate (Routing.routeFromResult route)
            ]
    in
        model ! cmds


subscriptions : Model -> Sub Msg
subscriptions model =
    facilityMarkerClicked (\id -> Navigate (Routing.FacilityRoute id))
