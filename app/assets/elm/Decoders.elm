module Decoders exposing (categories, categoriesByGroup, categoriesByGroupItem, category, date, facility, facilitySummary, latLng, location, locations, search, suggestions)

import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Models exposing (..)
import Time
import Utils exposing (..)


search : Decoder SearchResult
search =
    map3 (\items nextUrl total -> { items = items, nextUrl = nextUrl, total = total })
        (field "items" (list facilitySummary))
        (maybe (field "next_url" string))
        (field "total" int)


suggestions : Decoder (List Suggestion)
suggestions =
    succeed (\f s l -> f ++ s ++ l)
        |> required "facilities" (list (map F facilitySummary))
        |> required "categories" (list (map C category))
        |> required "locations" (list (map L location))


facility : Decoder Facility
facility =
    succeed Facility
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
    succeed CategoriesByGroupItem
        |> required "name" string
        |> required "categories" (list string)


facilitySummary : Decoder FacilitySummary
facilitySummary =
    succeed FacilitySummary
        |> required "id" int
        |> required "name" string
        |> required "position" latLng
        |> required "facility_type" string
        |> required "priority" int
        |> required "adm" (list string)


category : Decoder Category
category =
    succeed Category
        |> required "id" int
        |> required "name" string
        |> required "facility_count" int


categories : Decoder (List Category)
categories =
    list category


location : Decoder Location
location =
    succeed Location
        |> required "id" int
        |> required "name" string
        |> optional "parent_name" (nullable string) Nothing


locations : Decoder (List Location)
locations =
    list location


latLng : Decoder LatLng
latLng =
    succeed Tuple.pair
        |> required "lat" float
        |> required "lng" float


date : Decoder Time.Posix
date =
    Json.Decode.map dateFromEpochSeconds float
