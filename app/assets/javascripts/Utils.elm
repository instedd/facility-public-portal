module Utils exposing (..)

import Models exposing (..)


(&>) : Maybe a -> (a -> Maybe b) -> Maybe b
(&>) =
    Maybe.andThen


stringToQuery : String -> Maybe String
stringToQuery q =
    if q == "" then
        Nothing
    else
        Just q


isSearchEmpty : SearchSpec -> Bool
isSearchEmpty spec =
    spec.q == Nothing && spec.s == Nothing && spec.latLng == Nothing
