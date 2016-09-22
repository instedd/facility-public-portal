module Utils exposing (..)


(&>) : Maybe a -> (a -> Maybe b) -> Maybe b
(&>) =
    Maybe.andThen
