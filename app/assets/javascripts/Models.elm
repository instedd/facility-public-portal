module Models exposing (..)

import Routing

type alias LatLng = (Float, Float)

type Suggestion = Facility Int String String (List String)
                | Service String Int

type alias Model = { route : Routing.Route
                   , query : String
                   , suggestions : List Suggestion
                   , userLocation : Maybe LatLng
                   }
