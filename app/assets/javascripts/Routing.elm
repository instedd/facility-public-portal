module Routing exposing (Route(..), parser, navigate, searchPath, routeFromResult)

import Dict exposing (Dict)
import Http
import Models exposing (SearchSpec)
import Navigation
import String
import UrlParser exposing (..)

type Route
    = SearchRoute SearchSpec
    | FacilityRoute Int
    | NotFoundRoute


parser : Navigation.Parser (Result String Route)
parser = Navigation.makeParser locationParser

navigate : Route -> Cmd msg
navigate route = let url = case route of
                             SearchRoute params -> searchPath "/" params
                             FacilityRoute id -> "/facilities/" ++ (toString id)
                             NotFoundRoute -> "/not-found"
                 in
                     Navigation.newUrl url

searchPath : String -> SearchSpec -> String
searchPath base params = String.concat [ base
                                       , params.q
                                         |> Maybe.map (\ q -> "?q=" ++ q)
                                         |> Maybe.withDefault ""
                                       , params.latLng
                                         |> Maybe.map (\ (lat,lng) -> "&lat=" ++ (toString lat) ++ "&lng=" ++ (toString lng))
                                         |> Maybe.withDefault ""
                                       ]

routeFromResult : Result String Route -> Route
routeFromResult result = case result of
                           Ok route ->
                               route
                           Err string ->
                               NotFoundRoute

-- PRIVATE

{-
  Match against path of document location, and optionally add
  information from query string to the parsed route.
-}
matchers : Parser (((Dict String String) -> Route) -> a) a
matchers = let
              makeSearchRoute params      = SearchRoute { q = Dict.get "q" params
                                                        , latLng = paramsLatLng params
                                                        }
              makeFacilityRoute id params = FacilityRoute id
           in oneOf [ format makeSearchRoute (s "")
                    , format makeFacilityRoute (s "facilities" </> int)
                    ]

floatParam : String -> Dict String String -> Maybe Float
floatParam key params = case Dict.get key params of
                            Nothing -> Nothing
                            Just v  -> Result.toMaybe (String.toFloat v)

paramsLatLng : Dict String String -> Maybe Models.LatLng
paramsLatLng params = case floatParam "lat" params of
                          Nothing -> Nothing
                          Just lat ->
                              case floatParam "lng" params of
                                  Nothing -> Nothing
                                  Just lng -> Just (lat, lng)

parseQuery : String -> Dict String String
parseQuery query = query                                        -- "?a=foo&b=bar&baz"
                  |> String.dropLeft 1                          -- "a=foo&b=bar&baz"
                  |> String.split "&"                           -- ["a=foo","b=bar","baz"]
                  |> List.map (\p -> case String.split "=" p of
                                         key::value::[] ->
                                             [(key, Http.uriDecode value)]
                                         _              ->
                                             [])                -- [[("a", "foo")], [("b", "bar")], []]
                  |> List.concat                                -- [("a", "foo"), ("b", "bar")]
                  |> Dict.fromList

locationParser : Navigation.Location -> Result String Route
locationParser location = let query = parseQuery location.search
                          in location.pathname           -- corresponds to document.location.pathname
                             |> String.dropLeft 1        -- remove / at the beginning
                             |> parse identity matchers  -- parse
                             |> Result.map (\p -> p query)
