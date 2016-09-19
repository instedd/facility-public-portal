module Routing exposing (..)

import String
import Navigation
import UrlParser exposing (..)

type Route
    = SearchRoute
    | FacilityRoute Int
    | NotFoundRoute

matchers : Parser (Route -> a) a
matchers = oneOf [ format SearchRoute (s "")
                 , format FacilityRoute (s "facilities" </> int)
                 ]

navigate : Route -> Cmd msg
navigate route = let url = case route of
                             SearchRoute -> "/"
                             FacilityRoute id -> "/facilities/" ++ (toString id)
                             NotFoundRoute -> "/not-found"
                 in
                     Navigation.newUrl url

hashParser : Navigation.Location -> Result String Route
hashParser location = location.pathname         -- corresponds to document.location.pathname
                    |> String.dropLeft 1        -- remove / at the beginning
                    |> parse identity matchers  -- parse

parser : Navigation.Parser (Result String Route)
parser = Navigation.makeParser hashParser

routeFromResult : Result String Route -> Route
routeFromResult result = case result of
                           Ok route ->
                               route
                           Err string ->
                               NotFoundRoute
