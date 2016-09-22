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
    , position : LatLng
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
    , userLocation : Maybe LatLng
    , fakeLocation : Maybe LatLng
    , suggestions : Maybe (List Suggestion)
    , results : Maybe (List Facility)
    , facility : Maybe Facility
    }
