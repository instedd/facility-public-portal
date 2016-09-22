module Utils exposing (..)


(&>) : Maybe a -> (a -> Maybe b) -> Maybe b
(&>) =
    Maybe.andThen


stringToQuery : String -> Maybe String
stringToQuery q =
    if q == "" then
        Nothing
    else
        Just q
