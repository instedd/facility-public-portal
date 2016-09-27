module Decoders exposing (..)

import Models exposing (..)
import Json.Decode exposing (..)


search : Decoder SearchResult
search =
    object2 (\items nextUrl -> { items = items, nextUrl = nextUrl })
        ("items" := list facility)
        (maybe ("next_url" := string))


suggestions : Decoder (List Suggestion)
suggestions =
    object3 (\f s l -> f ++ s ++ l)
        ("facilities" := list (map F facility))
        ("services" := list (map S service))
        ("locations" := list (map L location))


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


location : Decoder Location
location =
    object3 (\id name parentName -> { id = id, name = name, parentName = parentName })
        ("id" := int)
        ("name" := string)
        ("parent_name" := string)


latLng : Decoder LatLng
latLng =
    object2 (\lat lng -> ( lat, lng ))
        ("lat" := float)
        ("lng" := float)
