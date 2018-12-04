module Decoders exposing (..)

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
        |> required "categories" (list (map C category))
        |> required "locations" (list (map L location))


facility : Decoder Facility
facility =
    decode Facility
        |> required "id" int
        |> required "source_id" string
        |> required "name" string
        |> required "position" latLng
        |> required "facility_type" string
        |> required "priority" int
        |> required "categories_by_group" categoriesByGroup
        |> required "adm" (list string)
        |> required "ownership" string
        |> required "address" (nullable string)
        |> required "contact_name" (nullable string)
        |> required "contact_phone" (nullable string)
        |> required "contact_email" (nullable string)
        |> required "opening_hours" (nullable string)
        |> required "report_to" (nullable string)
        |> required "photo" (nullable string)
        |> required "last_updated" (nullable date)

categoriesByGroup : Decoder CategoriesByGroup
categoriesByGroup =
    list categoriesByGroupItem

categoriesByGroupItem : Decoder CategoriesByGroupItem
categoriesByGroupItem =
    decode CategoriesByGroupItem
        |> required "name" string
        |> required "categories" (list string)

facilitySummary : Decoder FacilitySummary
facilitySummary =
    decode FacilitySummary
        |> required "id" int
        |> required "name" string
        |> required "position" latLng
        |> required "facility_type" string
        |> required "priority" int
        |> required "adm" (list string)


category : Decoder Category
category =
    decode Category
        |> required "id" int
        |> required "name" string
        |> required "facility_count" int


categories : Decoder (List Category)
categories =
    list category


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
