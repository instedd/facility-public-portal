module Models exposing (..)


type alias LatLng =
    ( Float, Float )


type alias SearchSpec =
    { q : Maybe String
    , s : Maybe Int
    , l : Maybe Int
    , latLng : Maybe LatLng
    }


type alias Facility =
    { id : Int
    , name : String
    , position : LatLng
    , kind : String
    , services : List String
    , adm : List String
    }


type alias Service =
    { id : Int
    , name : String
    , facilityCount : Int
    }


type alias Location =
    { id : Int
    , name : String
    , parentName : String
    }


type Suggestion
    = F Facility
    | S Service
    | L Location


type alias Model =
    { query : String
    , userLocation : Maybe LatLng
    , fakeLocation : Maybe LatLng
    , suggestions : Maybe (List Suggestion)
    , results : Maybe (List Facility)
    , facility : Maybe Facility
    , hideResults : Bool
    }
