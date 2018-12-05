module Routing exposing
    ( navigate
    , parser
    , routeFromResult
    , routeToPath
    , toggleExpandedParam
    )

import Browser.Navigation
import Dict exposing (Dict)
import Models exposing (..)
import String
import Url.Parser exposing (..)
import Utils exposing (..)


parser : Navigation.Parser (Result String Route)
parser =
    Navigation.makeParser locationParser


navigate : Route -> Cmd msg
navigate route =
    Navigation.newUrl <| routeToPath route


routeToPath : Route -> String
routeToPath route =
    case route of
        RootRoute { expanded } ->
            buildPath "/map" (appendExpanded expanded [])

        SearchRoute { spec, expanded } ->
            buildPath "/map/search" (appendExpanded expanded (searchParams spec))

        FacilityRoute id ->
            "/map/facilities/" ++ toString id

        NotFoundRoute ->
            "/not-found"


routeFromResult : Result String Route -> Route
routeFromResult =
    Result.withDefault NotFoundRoute



-- PRIVATE
{-
   Match against path of document location, and optionally add
   information from query string to the parsed route.
-}


matchers : Parser ((Dict String String -> Route) -> a) a
matchers =
    let
        makeRootRoute params =
            RootRoute { expanded = boolParam "expanded" params }

        makeSearchRoute params =
            SearchRoute { spec = specFromParams params, expanded = boolParam "expanded" params }

        makeFacilityRoute id params =
            FacilityRoute id
    in
    oneOf
        [ format makeSearchRoute (s "map" </> s "search")
        , format makeFacilityRoute (s "map" </> s "facilities" </> int)
        , format makeRootRoute (s "map")
        ]


locationParser : Navigation.Location -> Result String Route
locationParser location =
    location.pathname
        -- corresponds to document.location.pathname
        |> String.dropLeft 1
        -- remove / at the beginning
        |> parse identity matchers
        -- parse
        |> Result.map (\p -> p (parseQuery location.search))


specFromParams : Dict String String -> SearchSpec
specFromParams params =
    { q = Dict.get "q" params &> discardEmpty
    , category = intParam "category" params
    , location = intParam "location" params
    , latLng = paramsLatLng params
    , fType = intParam "type" params
    , ownership = intParam "ownership" params
    , size = intParam "size" params
    , sort = sortParam params
    }


intParam : String -> Dict String String -> Maybe Int
intParam key params =
    Dict.get key params
        &> (String.toInt >> Result.toMaybe)


floatParam : String -> Dict String String -> Maybe Float
floatParam key params =
    Dict.get key params
        &> (String.toFloat >> Result.toMaybe)


boolParam : String -> Dict String String -> Bool
boolParam key params =
    Dict.get key params
        |> Maybe.map
            (\s ->
                if s == "1" then
                    True

                else
                    False
            )
        |> Maybe.withDefault False


sortParam : Dict String String -> Maybe Sorting
sortParam params =
    Dict.get "sort" params
        |> Maybe.map
            (\s ->
                if s == "name" then
                    Name

                else if s == "type" then
                    Type

                else
                    Distance
            )


paramsLatLng : Dict String String -> Maybe LatLng
paramsLatLng params =
    let
        mlat =
            floatParam "lat" params

        mlng =
            floatParam "lng" params
    in
    mlat &> (\lat -> Maybe.map (Tuple.pair lat) mlng)


encodeBoolParam bool =
    case bool of
        True ->
            "1"

        False ->
            "0"


toggleExpandedParam : Route -> Cmd msg
toggleExpandedParam route =
    let
        toggledUrl =
            case route of
                RootRoute { expanded } ->
                    RootRoute { expanded = not expanded }

                SearchRoute { spec, expanded } ->
                    SearchRoute { spec = spec, expanded = not expanded }

                _ ->
                    route
    in
    navigate toggledUrl


appendExpanded : Bool -> List ( String, String ) -> List ( String, String )
appendExpanded expanded params =
    if expanded then
        params ++ [ ( "expanded", "1" ) ]

    else
        params
