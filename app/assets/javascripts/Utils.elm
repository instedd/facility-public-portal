module Utils exposing (..)

import Http
import String
import Date exposing (Date)
import Time
import Task


(&>) : Maybe a -> (a -> Maybe b) -> Maybe b
(&>) =
    Maybe.andThen


mapFst : (a -> b) -> ( a, c ) -> ( b, c )
mapFst f ( a, c ) =
    ( f a, c )


mapSnd : (b -> c) -> ( a, b ) -> ( a, c )
mapSnd f ( a, b ) =
    ( a, f b )


mapTCmd : (a -> c) -> (b -> d) -> ( a, Cmd b ) -> ( c, Cmd d )
mapTCmd f g ( a, b ) =
    ( f a, Cmd.map g b )


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


last : List a -> Maybe a
last l =
    List.head <| List.reverse l


singleton : a -> List a
singleton x =
    [ x ]


selectList : List ( a, Bool ) -> List a
selectList =
    List.foldr
        (\( x, include ) rec ->
            if include then
                x :: rec
            else
                rec
        )
        []


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
