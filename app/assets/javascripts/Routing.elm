module Routing exposing (parser, navigate, routeFromResult)

import Dict exposing (Dict)
import Http
import Maybe exposing (andThen)
import Models exposing (..)
import Navigation
import Search
import String
import UrlParser exposing (..)
import Utils exposing (..)


parser : Navigation.Parser (Result String Route)
parser =
    Navigation.makeParser locationParser


navigate : Route -> Cmd msg
navigate route =
    let
        url =
            case route of
                RootRoute ->
                    "/"

                SearchRoute params ->
                    Search.path "/search" params

                FacilityRoute id ->
                    "/facilities/" ++ (toString id)

                NotFoundRoute ->
                    "/not-found"
    in
        Navigation.newUrl url


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
            SearchRoute (Search.specFromParams params)

        makeFacilityRoute id params =
            FacilityRoute id
    in
        oneOf
            [ format makeRootRoute (s "")
            , format makeSearchRoute (s "search")
            , format makeFacilityRoute (s "facilities" </> int)
            ]


parseQuery : String -> Dict String String
parseQuery query =
    query
        -- "?a=foo&b=bar&baz"
        |>
            String.dropLeft 1
        -- "a=foo&b=bar&baz"
        |>
            String.split "&"
        -- ["a=foo","b=bar","baz"]
        |>
            List.map parseParam
        -- [[("a", "foo")], [("b", "bar")], []]
        |>
            List.concat
        -- [("a", "foo"), ("b", "bar")]
        |>
            Dict.fromList


parseParam : String -> List ( String, String )
parseParam s =
    case String.split "=" s of
        k :: v :: [] ->
            [ ( k, Http.uriDecode v ) ]

        _ ->
            []


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
