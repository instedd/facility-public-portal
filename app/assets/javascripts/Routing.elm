module Routing exposing (..)

import String
import Navigation
import UrlParser exposing (..)

type Route
    = MapRoute
    | FacilityRoute Int
    | NotFoundRoute

matchers : Parser (Route -> a) a
matchers = oneOf [ format MapRoute (s "")
                 , format MapRoute (s "map")
                 , format FacilityRoute (s "facilities" </> int)
                 ]

navigate : Route -> Cmd msg
navigate route = let url = case route of
                             MapRoute -> "#/"
                             FacilityRoute id -> "#/facilities/" ++ (toString id)
                             NotFoundRoute -> "#/not-found"
                 in
                     Navigation.newUrl url

hashParser : Navigation.Location -> Result String Route
hashParser location = location.hash
                    |> String.dropLeft 2
                    |> parse identity matchers

parser : Navigation.Parser (Result String Route)
parser = Navigation.makeParser hashParser

routeFromResult : Result String Route -> Route
routeFromResult result = case result of
                           Ok route ->
                               route
                           Err string ->
                               NotFoundRoute
