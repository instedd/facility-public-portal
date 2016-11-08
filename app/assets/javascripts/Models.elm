module Models exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import SelectList exposing (..)
import String
import Utils exposing ((&>), discardEmpty)


type alias Settings =
    { fakeLocation : Maybe LatLng
    , contactEmail : String
    , locale : String
    , locales : List ( String, String )
    , facilityTypes : List FacilityType
    , ownerships : List Ownership
    , locations : List Location
    , services : List Service
    }


type Route
    = RootRoute
    | SearchRoute SearchSpec
    | FacilityRoute Int
    | NotFoundRoute


type alias SearchSpec =
    { q : Maybe String
    , service : Maybe Int
    , location : Maybe Int
    , latLng : Maybe LatLng
    , fType : Maybe Int
    , ownership : Maybe Int
    }


type alias LatLng =
    ( Float, Float )


type alias Facility =
    { id : Int
    , name : String
    , position : LatLng
    , facilityType : String
    , priority : Int
    , services : List String
    , adm : List String
    , contactName : Maybe String
    , contactPhone : Maybe String
    , contactEmail : Maybe String
    , reportTo : Maybe String
    , lastUpdated : Maybe Date
    }


type alias FacilityType =
    { id : Int
    , name : String
    }


type alias Ownership =
    { id : Int
    , name : String
    }


type alias FacilitySummary =
    { id : Int
    , name : String
    , position : LatLng
    , facilityType : String
    , priority : Int
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
    , parentName : Maybe String
    }


type Suggestion
    = F FacilitySummary
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


type alias MapScale =
    { label : String
    , width : Int
    }


type alias MapViewport =
    { center : LatLng
    , bounds : MapViewportBounds
    , scale : MapScale
    }


type alias SearchResult =
    { items : List FacilitySummary
    , nextUrl : Maybe String
    }


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


contains : MapViewport -> LatLng -> Bool
contains mapViewport ( lat, lng ) =
    (between mapViewport.bounds.west mapViewport.bounds.east lng) && (between mapViewport.bounds.south mapViewport.bounds.north lat)


between : Float -> Float -> Float -> Bool
between min max v =
    min <= v && v <= max


distance : LatLng -> LatLng -> Float
distance ( x1, y1 ) ( x2, y2 ) =
    sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


shouldLoadMore : SearchResult -> MapViewport -> Bool
shouldLoadMore results mapViewport =
    case Utils.last results.items of
        Nothing ->
            False

        Just furthest ->
            distance furthest.position mapViewport.center < (maxDistance mapViewport)


path : String -> SearchSpec -> String
path base params =
    let
        queryParams =
            select <|
                List.map maybe
                    [ Maybe.map (\q -> ( "q", q )) params.q
                    , Maybe.map (\s -> ( "service", toString s )) params.service
                    , Maybe.map (\l -> ( "location", toString l )) params.location
                    , Maybe.map (\( lat, _ ) -> ( "lat", toString lat )) params.latLng
                    , Maybe.map (\( _, lng ) -> ( "lng", toString lng )) params.latLng
                    , Maybe.map (\t -> ( "type", toString t )) params.fType
                    , Maybe.map (\o -> ( "ownership", toString o )) params.ownership
                    ]
    in
        Utils.buildPath base queryParams


specFromParams : Dict String String -> SearchSpec
specFromParams params =
    { q = Dict.get "q" params &> discardEmpty
    , service = intParam "service" params
    , location = intParam "location" params
    , latLng = paramsLatLng params
    , fType = intParam "type" params
    , ownership = intParam "ownership" params
    }


emptySearch : SearchSpec
emptySearch =
    { q = Nothing, service = Nothing, location = Nothing, latLng = Nothing, fType = Nothing, ownership = Nothing }


searchEquals : SearchSpec -> SearchSpec -> Bool
searchEquals s1 s2 =
    List.all identity
        [ Utils.equalMaybe (Maybe.andThen s1.q discardEmpty) (Maybe.andThen s2.q discardEmpty)
        , Utils.equalMaybe s1.service s2.service
        , Utils.equalMaybe s1.location s2.location
        , Utils.equalMaybe s1.latLng s2.latLng
        , Utils.equalMaybe s1.fType s2.fType
        , Utils.equalMaybe s1.ownership s2.ownership
        ]


isEmpty : SearchSpec -> Bool
isEmpty =
    searchEquals emptySearch



-- Private


paramsLatLng : Dict String String -> Maybe LatLng
paramsLatLng params =
    let
        mlat =
            floatParam "lat" params

        mlng =
            floatParam "lng" params
    in
        mlat &> \lat -> Maybe.map ((,) lat) mlng


intParam : String -> Dict String String -> Maybe Int
intParam key params =
    Dict.get key params
        &> (String.toInt >> Result.toMaybe)


floatParam : String -> Dict String String -> Maybe Float
floatParam key params =
    Dict.get key params
        &> (String.toFloat >> Result.toMaybe)


setQuery : String -> SearchSpec -> SearchSpec
setQuery q search =
    { search | q = Just q }


setType : Int -> SearchSpec -> SearchSpec
setType id search =
    { search | fType = Just id }


setOwnership : Int -> SearchSpec -> SearchSpec
setOwnership id search =
    { search | ownership = Just id }
