module Decoders exposing (..)

import Models exposing (..)
import Json.Decode exposing (..)


search : Decoder (List Facility)
search =
    list <| facility


suggestions : Decoder (List Suggestion)
suggestions =
    object2 (++)
        ("facilities" := list (map F facility))
        ("services" := list (map S service))


facility : Decoder Facility
facility =
    object5 (\id name kind position services -> { id = id, name = name, kind = kind, position = position, services = services })
        ("id" := int)
        ("name" := string)
        ("kind" := string)
        ("position" := latLng)
        ("services" := list string)


service : Decoder Service
service =
    object2 (\name count -> { name = name, count = count })
        ("name" := string)
        ("count" := int)


latLng : Decoder LatLng
latLng =
    object2 (\lat lng -> ( lat, lng ))
        ("lat" := float)
        ("lng" := float)
