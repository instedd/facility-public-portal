module Models exposing (CategoriesByGroup, CategoriesByGroupItem, Category, CategoryGroup, Facility, FacilitySummary, FacilityType, LatLng, Location, LocationState(..), MapScale, MapViewport, MapViewportBounds, Ownership, Route(..), SearchResult, SearchSpec, Settings, Sorting(..), Suggestion(..), between, contains, distance, emptySearch, extend, isEmpty, maxDistance, querySearch, searchEquals, searchParams, setOwnership, setQuery, setType, shouldLoadMore)

import Dict exposing (Dict)
import SelectList exposing (..)
import String
import Time
import Utils exposing (discardEmpty)


type alias Settings =
    { fakeLocation : Maybe LatLng
    , contactEmail : String
    , locale : String
    , locales : List ( String, String )
    , facilityTypes : List FacilityType
    , ownerships : List Ownership
    , categoryGroups : List CategoryGroup
    , facilityPhotos : Bool
    }


type Route
    = RootRoute { expanded : Bool }
    | SearchRoute { spec : SearchSpec, expanded : Bool }
    | FacilityRoute Int
    | NotFoundRoute


type alias SearchSpec =
    { q : Maybe String
    , category : Maybe Int
    , location : Maybe Int
    , latLng : Maybe LatLng
    , fType : Maybe Int
    , ownership : Maybe Int
    , size : Maybe Int
    , sort : Maybe Sorting
    }


type Sorting
    = Distance
    | Name
    | Type


type alias LatLng =
    ( Float, Float )


type alias Facility =
    { id : Int
    , sourceId : String
    , name : String
    , position : LatLng
    , facilityType : String
    , priority : Int
    , categoriesByGroup : CategoriesByGroup
    , adm : List String
    , ownership : String
    , address : Maybe String
    , contactName : Maybe String
    , contactPhone : Maybe String
    , contactEmail : Maybe String
    , openingHours : Maybe String
    , reportTo : Maybe String
    , photo : Maybe String
    , lastUpdated : Maybe Time.Posix
    }


type alias CategoriesByGroup =
    List CategoriesByGroupItem


type alias CategoriesByGroupItem =
    { name : String, categories : List String }


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


type alias CategoryGroup =
    { name : String
    }


type alias Category =
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
    | C Category
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
    , total : Int
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
            0


contains : MapViewport -> LatLng -> Bool
contains mapViewport ( lat, lng ) =
    between mapViewport.bounds.west mapViewport.bounds.east lng && between mapViewport.bounds.south mapViewport.bounds.north lat


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
            distance furthest.position mapViewport.center < maxDistance mapViewport


extend : Maybe SearchResult -> Maybe SearchResult -> Maybe SearchResult
extend a b =
    case ( a, b ) of
        ( Nothing, _ ) ->
            b

        ( _, Nothing ) ->
            a

        ( Just a_, Just b_ ) ->
            Just { items = a_.items ++ b_.items, nextUrl = b_.nextUrl, total = b_.total }


searchParams : SearchSpec -> List ( String, String )
searchParams search =
    let
        sortingToString sorting =
            case sorting of
                Distance ->
                    "distance"

                Name ->
                    "name"

                Type ->
                    "type"
    in
    select <|
        List.map maybe
            [ Maybe.map (\q -> ( "q", q )) search.q
            , Maybe.map (\s -> ( "category", String.fromInt s )) search.category
            , Maybe.map (\l -> ( "location", String.fromInt l )) search.location
            , Maybe.map (\( lat, _ ) -> ( "lat", String.fromFloat lat )) search.latLng
            , Maybe.map (\( _, lng ) -> ( "lng", String.fromFloat lng )) search.latLng
            , Maybe.map (\t -> ( "type", String.fromInt t )) search.fType
            , Maybe.map (\o -> ( "ownership", String.fromInt o )) search.ownership
            , Maybe.map (\size -> ( "size", String.fromInt size )) search.size
            , Maybe.map (\s -> ( "sort", sortingToString s )) search.sort
            ]


emptySearch : SearchSpec
emptySearch =
    { q = Nothing
    , category = Nothing
    , location = Nothing
    , latLng = Nothing
    , fType = Nothing
    , ownership = Nothing
    , size = Nothing
    , sort = Nothing
    }


querySearch : String -> SearchSpec
querySearch q =
    { emptySearch | q = Just q }


searchEquals : SearchSpec -> SearchSpec -> Bool
searchEquals s1 s2 =
    List.all identity
        [ Utils.equalMaybe (Maybe.andThen discardEmpty s1.q) (Maybe.andThen discardEmpty s2.q)
        , Utils.equalMaybe s1.category s2.category
        , Utils.equalMaybe s1.location s2.location
        , Utils.equalMaybe s1.latLng s2.latLng
        , Utils.equalMaybe s1.fType s2.fType
        , Utils.equalMaybe s1.ownership s2.ownership
        , Utils.equalMaybe s1.sort s2.sort
        ]


isEmpty : SearchSpec -> Bool
isEmpty =
    searchEquals emptySearch



-- Private


setQuery : String -> SearchSpec -> SearchSpec
setQuery q search =
    { search | q = Just q }


setType : Int -> SearchSpec -> SearchSpec
setType id search =
    { search | fType = Just id }


setOwnership : Int -> SearchSpec -> SearchSpec
setOwnership id search =
    { search | ownership = Just id }
