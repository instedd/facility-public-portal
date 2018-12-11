module Utils exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.App
import Http
import Return
import String
import Task
import Time


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


setQuery : ( String, String ) -> String -> String
setQuery ( name, value ) url =
    let
        parts =
            String.split "?" url

        path =
            Maybe.withDefault "" (List.head parts)

        query =
            "?" ++ (Maybe.withDefault "" (List.head (Maybe.withDefault [] (List.tail parts))))

        queryDict =
            parseQuery query

        newQueryList =
            Dict.toList <| Dict.union (Dict.singleton name value) queryDict
    in
        buildPath path newQueryList


dateFromEpochSeconds : Float -> Date
dateFromEpochSeconds i =
    Date.fromTime (i * 1000 * Time.millisecond)


dateFromEpochMillis : Float -> Date
dateFromEpochMillis i =
    Date.fromTime (i * Time.millisecond)


timeAgo : Date -> Date -> String
timeAgo d1 d2 =
    let
        diffSeconds =
            ceiling (Date.toTime d1 / 1000 - Date.toTime d2 / 1000)

        secondsInHour =
            60 * 60

        secondsInDay =
            24 * secondsInHour

        secondsInMonth =
            30 * secondsInDay

        secondsInYear =
            12 * secondsInMonth

        ( yearsPassed, rem1 ) =
            ( diffSeconds // secondsInYear, diffSeconds % secondsInYear )

        ( monthsPassed, rem2 ) =
            ( rem1 // secondsInMonth, rem1 % secondsInMonth )

        ( daysPassed, rem3 ) =
            ( rem2 // secondsInDay, rem2 % secondsInDay )

        hoursPassed =
            rem3 // secondsInHour
    in
        if yearsPassed > 0 then
            (toString yearsPassed) ++ " years"
        else if monthsPassed > 0 then
            (toString monthsPassed) ++ " months"
        else if daysPassed > 0 then
            (toString daysPassed) ++ " days"
        else
            (toString hoursPassed) ++ " hours"


isJust : Maybe a -> Bool
isJust m =
    case m of
        Nothing ->
            False

        Just _ ->
            True


isNothing : Maybe a -> Bool
isNothing =
    not << isJust


equalMaybe : Maybe a -> Maybe a -> Bool
equalMaybe a b =
    case ( a, b ) of
        ( Nothing, Nothing ) ->
            True

        ( Just xa, Just xb ) ->
            xa == xb

        _ ->
            False


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


discardEmpty : String -> Maybe String
discardEmpty q =
    if q == "" then
        Nothing
    else
        Just q


unreachable : a -> b
unreachable =
    (\_ -> Debug.crash "This failure cannot happen.")


performMessage : msg -> Cmd msg
performMessage msg =
    Task.perform unreachable identity (Task.succeed msg)


perform : msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
perform msg =
    Return.command (performMessage msg)

notFailing : a -> a
notFailing x = notFailing x