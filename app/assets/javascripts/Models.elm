module Models exposing (..)

import Date exposing (Date)


type Route
    = RootRoute
    | SearchRoute SearchSpec
    | FacilityRoute Int
    | NotFoundRoute


type alias SearchSpec =
    { q : Maybe String
    , s : Maybe Int
    , l : Maybe Int
    , latLng : Maybe LatLng
    }


type alias LatLng =
    ( Float, Float )


type alias Facility =
    { id : Int
    , name : String
    , position : LatLng
    , kind : String
    , services : List String
    , adm : List String
    , contactName : Maybe String
    , contactPhone : Maybe String
    , contactEmail : Maybe String
    , reportTo : Maybe String
    , lastUpdated : Date
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


type LocationState
    = NoLocation
    | Detecting
    | Detected LatLng


type alias MapViewportBounds =
    { north : Float
    , south : Float
    , east : Float
    , west : Float
    }


type alias MapViewport =
    { center : LatLng
    , bounds : MapViewportBounds
    }


type alias Model =
    { query : String
    , userLocation : LocationState
    , fakeLocation : Maybe LatLng
    , suggestions : Maybe (List Suggestion)
    , results : Maybe (List Facility)
    , facility : Maybe Facility
    , hideResults : Bool
    , mapViewport : MapViewport
    , now : Maybe Date
    , currentSearch : Maybe SearchSpec
    }


type AppModel
    = Initializing (Result String Route) (Maybe LatLng)
    | Initialized Model


type alias SearchResult =
    { items : List Facility
    , nextUrl : Maybe String
    }


userLocation : Model -> Maybe LatLng
userLocation model =
    case model.userLocation of
        Detected latLng ->
            Just latLng

        _ ->
            Just model.mapViewport.center


maxDistance : MapViewport -> Float
maxDistance mapViewport =
    case
        List.maximum <|
            List.map
                (distance mapViewport.center)
                [ ( mapViewport.bounds.north, mapViewport.bounds.east )
                , ( mapViewport.bounds.north, mapViewport.bounds.west )
                , ( mapViewport.bounds.south, mapViewport.bounds.east )
                , ( mapViewport.bounds.south, mapViewport.bounds.west )
                ]
    of
        Just d ->
            -- 20% more of the maximum distance
            d * 1.2

        _ ->
            Debug.crash "unreachable"


distance : LatLng -> LatLng -> Float
distance ( x1, y1 ) ( x2, y2 ) =
    sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
