module Main exposing (..)

import Commands exposing (..)
import Html.App as App
import Messages exposing (..)
import Models exposing (..)
import Update
import View

type alias Flags = { fakeUserPosition : Bool
                   , initialPosition : LatLng
                   }

main : Program Flags
main = App.programWithFlags { init = init
                            , view = View.view
                            , update = Update.update
                            , subscriptions = always Sub.none
                            }

init : Flags -> (Model, Cmd Msg)
init flags = let model = { query = ""
                         , suggestions = []
                         , userLocation = Nothing
                         }
                 cmd =  if flags.fakeUserPosition
                        then Commands.fakeGeolocateUser flags.initialPosition
                        else Commands.geolocateUser
             in (model, cmd)
