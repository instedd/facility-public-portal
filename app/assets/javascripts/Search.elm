module Search
    exposing
        ( isEmpty
        , empty
        , byQuery
        , byService
        , byLocation
        , path
        , suggestionsPath
        , specFromParams
        , SearchSpec
        )

import Dict exposing (Dict)
import Maybe exposing (andThen)
import Models exposing (..)
import String
import Utils exposing (..)


type alias SearchSpec =
    { q : Maybe String
    , s : Maybe Int
    , l : Maybe Int
    , latLng : Maybe LatLng
    }



-- Building seach specs


isEmpty : SearchSpec -> Bool
isEmpty spec =
    spec.q == Nothing && spec.s == Nothing && spec.latLng == Nothing


empty : SearchSpec
empty =
    { q = Nothing, s = Nothing, l = Nothing, latLng = Nothing }


byQuery : Maybe LatLng -> Maybe String -> SearchSpec
byQuery latLng q =
    { empty | latLng = latLng, q = (q `andThen` discardEmpty) }


byService : Maybe LatLng -> Int -> SearchSpec
byService latLng s =
    { empty | latLng = latLng, s = Just s }


byLocation : Maybe LatLng -> Int -> SearchSpec
byLocation latLng l =
    { empty | latLng = latLng, l = Just l }



-- Url handling


path : String -> SearchSpec -> String
path base params =
    let
        queryParams =
            List.concat
                [ params.q
                    |> Maybe.map (\q -> [ ( "q", q ) ])
                    |> Maybe.withDefault []
                , params.s
                    |> Maybe.map (\s -> [ ( "s", toString s ) ])
                    |> Maybe.withDefault []
                , params.l
                    |> Maybe.map (\l -> [ ( "l", toString l ) ])
                    |> Maybe.withDefault []
                , params.latLng
                    |> Maybe.map (\( lat, lng ) -> [ ( "lat", toString lat ), ( "lng", toString lng ) ])
                    |> Maybe.withDefault []
                ]
    in
        buildPath base queryParams


suggestionsPath : String -> Maybe LatLng -> String -> String
suggestionsPath base latLng query =
    path base <| byQuery latLng (Just query)


specFromParams : Dict String String -> SearchSpec
specFromParams params =
    { q =
        Dict.get "q" params
            &> discardEmpty
    , s =
        Dict.get "s" params
            &> (String.toInt >> Result.toMaybe)
    , l =
        Dict.get "l" params
            &> (String.toInt >> Result.toMaybe)
    , latLng = paramsLatLng params
    }



-- Private


paramsLatLng : Dict String String -> Maybe Models.LatLng
paramsLatLng params =
    let
        mlat =
            floatParam "lat" params

        mlng =
            floatParam "lng" params
    in
        mlat `andThen` \lat -> Maybe.map ((,) lat) mlng


floatParam : String -> Dict String String -> Maybe Float
floatParam key params =
    case Dict.get key params of
        Nothing ->
            Nothing

        Just v ->
            Result.toMaybe (String.toFloat v)


discardEmpty : String -> Maybe String
discardEmpty q =
    if q == "" then
        Nothing
    else
        Just q
