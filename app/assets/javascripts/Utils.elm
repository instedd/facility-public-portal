module Utils exposing (..)

import Http
import String


(&>) : Maybe a -> (a -> Maybe b) -> Maybe b
(&>) =
    Maybe.andThen


buildPath : String -> List ( String, String ) -> String
buildPath base queryParams =
    case queryParams of
        [] ->
            base

        _ ->
            String.concat
                [ base
                , "?"
                , queryParams
                    |> List.map (\( k, v ) -> k ++ "=" ++ Http.uriEncode v)
                    |> String.join "&"
                ]
