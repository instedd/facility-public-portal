module Utils exposing
    ( buildPath
    , dateFromEpochMillis
    , dateFromEpochSeconds
    , discardEmpty
    , equalMaybe
    , isJust
    , isNothing
    , last
    , parseParam
    , parseQuery
    , perform
    , performMessage
    , setQuery
    , timeAgo
    )

import Dict exposing (Dict)
import Html exposing (Html)
import Http
import Return
import String
import Task
import Time
import Url exposing (percentDecode, percentEncode)


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
                    |> List.map (\( k, v ) -> k ++ "=" ++ percentEncode v)
                    |> String.join "&"
                ]


parseQuery : String -> Dict String String
parseQuery query =
    query
        -- "?a=foo&b=bar&baz"
        |> String.dropLeft 1
        -- "a=foo&b=bar&baz"
        |> String.split "&"
        -- ["a=foo","b=bar","baz"]
        |> List.map parseParam
        -- [[("a", "foo")], [("b", "bar")], []]
        |> List.concat
        -- [("a", "foo"), ("b", "bar")]
        |> Dict.fromList


parseParam : String -> List ( String, String )
parseParam s =
    case String.split "=" s of
        k :: v :: [] ->
            [ ( k, percentDecode v |> Maybe.withDefault v ) ]

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
            "?" ++ Maybe.withDefault "" (List.head (Maybe.withDefault [] (List.tail parts)))

        queryDict =
            parseQuery query

        newQueryList =
            Dict.toList <| Dict.union (Dict.singleton name value) queryDict
    in
    buildPath path newQueryList


dateFromEpochSeconds : Float -> Time.Posix
dateFromEpochSeconds i =
    Time.millisToPosix (round i * 1000)


dateFromEpochMillis : Float -> Time.Posix
dateFromEpochMillis i =
    Time.millisToPosix (round i)


timeAgo : Time.Posix -> Time.Posix -> String
timeAgo d1 d2 =
    let
        diffSeconds =
            (Time.posixToMillis d1 // 1000) - (Time.posixToMillis d2 // 1000)

        secondsInHour =
            60 * 60

        secondsInDay =
            24 * secondsInHour

        secondsInMonth =
            30 * secondsInDay

        secondsInYear =
            12 * secondsInMonth

        ( yearsPassed, rem1 ) =
            ( diffSeconds // secondsInYear, remainderBy secondsInYear diffSeconds )

        ( monthsPassed, rem2 ) =
            ( rem1 // secondsInMonth, remainderBy secondsInMonth rem1 )

        ( daysPassed, rem3 ) =
            ( rem2 // secondsInDay, remainderBy secondsInDay rem2 )

        hoursPassed =
            rem3 // secondsInHour
    in
    if yearsPassed > 0 then
        String.fromInt yearsPassed ++ " years"

    else if monthsPassed > 0 then
        String.fromInt monthsPassed ++ " months"

    else if daysPassed > 0 then
        String.fromInt daysPassed ++ " days"

    else
        String.fromInt hoursPassed ++ " hours"


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


performMessage : msg -> Cmd msg
performMessage msg =
    Task.perform identity (Task.succeed msg)


perform : msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
perform msg =
    Return.command (performMessage msg)
