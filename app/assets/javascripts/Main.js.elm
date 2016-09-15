module Main exposing (..)

import Commands exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Navigation
import Routing
import Update
import View

type alias Flags = { fakeUserPosition : Bool
                   , initialPosition : LatLng
                   }

main : Program Flags
main = Navigation.programWithFlags Routing.parser
                                   { init = init
                                   , view = View.view
                                   , update = Update.update
                                   , subscriptions = always Sub.none
                                   , urlUpdate = Update.urlUpdate
                                   }

init : Flags -> Result String Routing.Route -> (Model, Cmd Msg)
init flags route = let model = { route = (Routing.routeFromResult route)
                               , query = ""
                               , suggestions = []
                               , userLocation = Nothing
                               }
                       cmds  = [ Commands.initializeMap flags.initialPosition
                               , if flags.fakeUserPosition
                                 then Commands.fakeGeolocateUser flags.initialPosition
                                 else Commands.geolocateUser
                               ]
                   in model ! cmds
