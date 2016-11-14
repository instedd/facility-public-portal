module Routing exposing (parser, navigate, routeFromResult, routeToPath)

import Dict exposing (Dict)
import Models exposing (..)
import Navigation
import String
import UrlParser exposing (..)
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
        RootRoute ->
            "/map"

        SearchRoute params ->
            path "/map/search" params

        FacilityRoute id ->
            "/map/facilities/" ++ (toString id)

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
            RootRoute

        makeSearchRoute params =
            SearchRoute (Models.specFromParams params)

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
        |>
            String.dropLeft 1
        -- remove / at the beginning
        |>
            parse identity matchers
        -- parse
        |>
            Result.map (\p -> p (parseQuery location.search))
