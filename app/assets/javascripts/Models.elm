module Models exposing (..)

import Date exposing (Date)
import Utils exposing ((&>), discardEmpty)
import Dict exposing (Dict)
import String


type alias Settings =
    { fakeLocation : Maybe LatLng }


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


type alias FacilitySummary =
    { id : Int
    , name : String
    , position : LatLng
    , facilityType : String
    , priority : Int
    , adm: List String
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


type alias MapViewport =
    { center : LatLng
    , bounds : MapViewportBounds
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
            List.concat
                [ params.q
                    |> Maybe.map (\q -> [ ( "q", q ) ])
                    |> Maybe.withDefault []
                , params.s
                    |> Maybe.map (\s -> [ ( "s", toString s ) ])
                    |> Maybe.withDefault []
                , params.l
                    |> Maybe.map (\l -> [ ( "l", toString l ) ])
                    |> Maybe.withDefault []
                , params.latLng
                    |> Maybe.map (\( lat, lng ) -> [ ( "lat", toString lat ), ( "lng", toString lng ) ])
                    |> Maybe.withDefault []
                ]
    in
        Utils.buildPath base queryParams


specFromParams : Dict String String -> SearchSpec
specFromParams params =
    { q =
        Dict.get "q" params
            &> discardEmpty
    , s =
        Dict.get "s" params
            &> (String.toInt >> Result.toMaybe)
    , l =
        Dict.get "l" params
            &> (String.toInt >> Result.toMaybe)
    , latLng = paramsLatLng params
    }



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


floatParam : String -> Dict String String -> Maybe Float
floatParam key params =
    case Dict.get key params of
        Nothing ->
            Nothing

        Just v ->
            Result.toMaybe (String.toFloat v)
