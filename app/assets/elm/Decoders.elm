module Decoders exposing (..)

import Date exposing (Date)
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, nullable)
import Models exposing (..)
import Utils exposing (..)


search : Decoder SearchResult
search =
    object3 (\items nextUrl total -> { items = items, nextUrl = nextUrl, total = total })
        ("items" := list facilitySummary)
        (maybe ("next_url" := string))
        ("total" := int)


suggestions : Decoder (List Suggestion)
suggestions =
    decode (\f s l -> f ++ s ++ l)
        |> required "facilities" (list (map F facilitySummary))
        |> required "services" (list (map S service))
        |> required "locations" (list (map L location))


facility : Decoder Facility
facility =
    decode Facility
        |> required "id" int
        |> required "name" string
        |> required "position" latLng
        |> required "facility_type" string
        |> required "priority" int
        |> required "service_names" (list string)
        |> required "adm" (list string)
        |> required "ownership" string
        |> required "contact_name" (nullable string)
        |> required "contact_phone" (nullable string)
        |> required "contact_email" (nullable string)
        |> required "report_to" (nullable string)
        |> required "photo" (nullable string)
        |> required "last_updated" (nullable date)


facilitySummary : Decoder FacilitySummary
facilitySummary =
    decode FacilitySummary
        |> required "id" int
        |> required "name" string
        |> required "position" latLng
        |> required "facility_type" string
        |> required "priority" int
        |> required "adm" (list string)


service : Decoder Service
service =
    decode Service
        |> required "id" int
        |> required "name" string
        |> required "facility_count" int


services : Decoder (List Service)
services =
    list service


location : Decoder Location
location =
    decode Location
        |> required "id" int
        |> required "name" string
        |> optional "parent_name" (nullable string) Nothing


locations : Decoder (List Location)
locations =
    list location


latLng : Decoder LatLng
latLng =
    decode (,)
        |> required "lat" float
        |> required "lng" float


date : Decoder Date
date =
    Json.Decode.map dateFromEpochSeconds float
