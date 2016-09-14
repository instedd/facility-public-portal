port module Js exposing (displayUserLocation)

import Json.Encode exposing (..)

-- PORTS

type alias Command = (String, Json.Encode.Value)

port commands : Command -> Cmd msg

displayUserLocation : (Float, Float) -> Cmd msg
displayUserLocation (lat, lng) = commands ("displayUserLocation", object [ ("lat", float lat)
                                                                         , ("lng", float lng)
                                                                         ])
