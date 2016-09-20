module Models exposing (..)


type alias LatLng =
    ( Float, Float )


type alias SearchSpec =
    { q : Maybe String
    , latLng : Maybe LatLng
    }


type alias Facility =
    { id : Int
    , name : String
    , kind : String
    , services : List String
    }


type alias Service =
    { name : String
    , count : Int
    }


type Suggestion
    = F Facility
    | S Service


type alias Model =
    { query : String
    , suggestions : Maybe (List Suggestion)
    , userLocation : Maybe LatLng
    , results : Maybe (List Facility)
    }
