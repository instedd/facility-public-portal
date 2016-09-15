port module Commands exposing (..)

import Geolocation
import Json.Encode exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Process
import Task
import Time

port jsCommand : Command -> Cmd msg
type alias Command = (String, Json.Encode.Value)

displayUserLocation : (Float, Float) -> Cmd msg
displayUserLocation (lat, lng) = jsCommand ("displayUserLocation"
                                           , object [ ("lat", float lat)
                                                    , ("lng", float lng)
                                                    ])
fakeGeolocateUser : LatLng -> Cmd Msg
fakeGeolocateUser pos = Process.sleep (1.5 * Time.second)
                      |> Task.map (always pos)
                      |> Task.perform LocationFailed LocationDetected

geolocateUser : Cmd Msg
geolocateUser = Geolocation.now
              |> Task.map (\location -> (location.latitude, location.longitude))
              |> Task.perform LocationFailed LocationDetected
