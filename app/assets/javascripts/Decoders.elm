module Decoders exposing (search, suggestions)

import Models exposing (..)
import Json.Decode exposing (..)

search : Decoder (List Facility)
search = list <| facility

suggestions : Decoder (List Suggestion)
suggestions = object2 (++)
                      ("facilities" := list (map F facility))
                      ("services"   := list (map S service))

facility : Decoder Facility
facility = object4 (\id name kind services -> { id = id, name = name, kind = kind, services = services })
                   ("id"       := int)
                   ("name"     := string)
                   ("kind"     := string)
                   ("services" := list string)

service : Decoder Service
service = object2 (\name count -> { name = name, count = count })
                  ("name"  := string)
                  ("count" := int)
