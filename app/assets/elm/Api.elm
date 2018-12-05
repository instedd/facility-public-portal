module Api
    exposing
        ( SuggestionsMsg(..)
        , getSuggestions
        , FetchFacilityMsg(..)
        , fetchFacility
        , CategoriesMsg(..)
        , getCategories
        , LocationsMsg(..)
        , getLocations
        , SearchMsg(..)
        , search
        , searchMore
        )

import Decoders exposing (..)
import Http
import Maybe exposing (andThen)
import Models exposing (..)
import Task
import Utils


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
            "/api/facilities/" ++ (String.fromInt id)
    in
        Task.perform (wmsg << FetchFacilityFailed) (wmsg << FetchFacilitySuccess) (Http.get Decoders.facility url)


type LocationsMsg
    = LocationsSuccess (List Location)
    | LocationsFailed Http.Error


getLocations : (Http.Error -> msg) -> (List Location -> msg) -> Cmd msg
getLocations error ok =
    Task.perform error ok (Http.get Decoders.locations "/api/locations")


type CategoriesMsg
    = CategoriesSuccess (List Category)
    | CategoriesFailed Http.Error


getCategories : (Http.Error -> msg) -> (List Category -> msg) -> Cmd msg
getCategories error ok =
    Task.perform error ok (Http.get Decoders.categories "/api/categories")


type SearchMsg
    = SearchSuccess SearchResult
    | SearchFailed Http.Error


search : (SearchMsg -> msg) -> SearchSpec -> Cmd msg
search wmsg params =
    let
        url =
            Utils.buildPath "/api/search" (searchParams params)
    in
        Task.perform (wmsg << SearchFailed) (wmsg << SearchSuccess) (Http.get Decoders.search url)


searchMore : (SearchMsg -> msg) -> SearchResult -> Cmd msg
searchMore wmsg result =
    case result.nextUrl of
        Nothing ->
            Cmd.none

        Just nextUrl ->
            Task.perform (wmsg << SearchFailed) (wmsg << SearchSuccess) (Http.get Decoders.search nextUrl)


byQuery : Maybe LatLng -> Maybe String -> SearchSpec
byQuery latLng q =
    { emptySearch | latLng = latLng, q = (Maybe.andThen discardEmpty q) }


suggestionsPath : String -> Maybe LatLng -> String -> String
suggestionsPath base latLng query =
    byQuery latLng (Just query)
        |> searchParams
        |> Utils.buildPath base


discardEmpty : String -> Maybe String
discardEmpty q =
    if q == "" then
        Nothing
    else
        Just q
