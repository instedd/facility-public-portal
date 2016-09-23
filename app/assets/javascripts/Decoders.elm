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
    object6
        (\id name kind position services adm ->
            { id = id
            , name = name
            , kind = kind
            , position = position
            , services = services
            , adm = adm
            }
        )
        ("id" := int)
        ("name" := string)
        ("kind" := string)
        ("position" := latLng)
        ("service_names" := list string)
        ("adm" := list string)


service : Decoder Service
service =
    object3 (\id name facilityCount -> { id = id, name = name, facilityCount = facilityCount })
        ("id" := int)
        ("name" := string)
        ("facility_count" := int)


latLng : Decoder LatLng
latLng =
    object2 (\lat lng -> ( lat, lng ))
        ("lat" := float)
        ("lng" := float)
