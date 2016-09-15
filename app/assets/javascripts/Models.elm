module Models exposing (..)

type alias LatLng = (Float, Float)

type Suggestion = Facility String String (List String)
                | Service String Int

type alias Model = { query : String
                   , suggestions : List Suggestion
                   , userLocation : Maybe LatLng
                   }
