module Api exposing (SuggestionsMsg(..), getSuggestions, FetchFacilityMsg(..), fetchFacility, SearchMsg(..), search, searchMore, emptySearch)

import Decoders exposing (..)
import Http
import Maybe exposing (andThen)
import Models exposing (..)
import Task
import Utils exposing (..)


type SuggestionsMsg
    = SuggestionsSuccess String (List Suggestion)
    | SuggestionsFailed Http.Error


getSuggestions : (SuggestionsMsg -> msg) -> Maybe LatLng -> String -> Cmd msg
getSuggestions wmsg latLng query =
    let
        url =
            suggestionsPath "/api/suggest" latLng query
    in
        Task.perform (wmsg << SuggestionsFailed) (wmsg << SuggestionsSuccess query) (Http.get Decoders.suggestions url)


type FetchFacilityMsg
    = FetchFacilitySuccess Facility
    | FetchFacilityFailed Http.Error


fetchFacility : (FetchFacilityMsg -> msg) -> Int -> Cmd msg
fetchFacility wmsg id =
    let
        url =
            "/api/facilities/" ++ (toString id)
    in
        Task.perform (wmsg << FetchFacilityFailed) (wmsg << FetchFacilitySuccess) (Http.get Decoders.facility url)


type SearchMsg
    = SearchSuccess SearchResult
    | SearchFailed Http.Error


search : (SearchMsg -> msg) -> SearchSpec -> Cmd msg
search wmsg params =
    let
        url =
            path "/api/search" params
    in
        Task.perform (wmsg << SearchFailed) (wmsg << SearchSuccess) (Http.get Decoders.search url)


searchMore : (SearchMsg -> msg) -> SearchResult -> Cmd msg
searchMore wmsg result =
    case result.nextUrl of
        Nothing ->
            Cmd.none

        Just nextUrl ->
            Task.perform (wmsg << SearchFailed) (wmsg << SearchSuccess) (Http.get Decoders.search nextUrl)


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


emptySearch : SearchSpec
emptySearch =
    { q = Nothing, s = Nothing, l = Nothing, latLng = Nothing }


byQuery : Maybe LatLng -> Maybe String -> SearchSpec
byQuery latLng q =
    { emptySearch | latLng = latLng, q = (q `andThen` discardEmpty) }


suggestionsPath : String -> Maybe LatLng -> String -> String
suggestionsPath base latLng query =
    path base <| byQuery latLng (Just query)


discardEmpty : String -> Maybe String
discardEmpty q =
    if q == "" then
        Nothing
    else
        Just q
