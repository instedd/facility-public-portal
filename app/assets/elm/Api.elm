module Api exposing
    ( CategoriesMsg(..)
    , FetchFacilityMsg(..)
    , LocationsMsg(..)
    , SearchMsg(..)
    , SuggestionsMsg(..)
    , fetchFacility
    , getCategories
    , getLocations
    , getSuggestions
    , search
    , searchMore
    )

import Decoders exposing (..)
import Http
import Json.Decode exposing (Decoder)
import Maybe exposing (andThen)
import Models exposing (..)
import Task
import Utils


type SuggestionsMsg
    = SuggestionsSuccess String (List Suggestion)
    | SuggestionsFailed Http.Error


resultHandler : (a -> msg) -> (Http.Error -> msg) -> Result Http.Error a -> msg
resultHandler successHandler errorHandler result =
    case result of
        Ok data ->
            successHandler data

        Err error ->
            errorHandler error


getJson : String -> Decoder a -> (a -> msg) -> (Http.Error -> msg) -> Cmd msg
getJson url decoder successHandler errorHandler =
    let
        handler =
            resultHandler successHandler errorHandler
    in
    Http.get
        { url = url
        , expect = Http.expectJson handler decoder
        }


getSuggestions : (SuggestionsMsg -> msg) -> Maybe LatLng -> String -> Cmd msg
getSuggestions wmsg latLng query =
    getJson
        (suggestionsPath "/api/suggest" latLng query)
        Decoders.suggestions
        (wmsg << SuggestionsSuccess query)
        (wmsg << SuggestionsFailed)


type FetchFacilityMsg
    = FetchFacilitySuccess Facility
    | FetchFacilityFailed Http.Error


fetchFacility : (FetchFacilityMsg -> msg) -> Int -> Cmd msg
fetchFacility wmsg id =
    getJson
        ("/api/facilities/" ++ String.fromInt id)
        Decoders.facility
        (wmsg << FetchFacilitySuccess)
        (wmsg << FetchFacilityFailed)


type LocationsMsg
    = LocationsSuccess (List Location)
    | LocationsFailed Http.Error


getLocations : (Http.Error -> msg) -> (List Location -> msg) -> Cmd msg
getLocations error ok =
    getJson "/api/locations" Decoders.locations ok error


type CategoriesMsg
    = CategoriesSuccess (List Category)
    | CategoriesFailed Http.Error


getCategories : (Http.Error -> msg) -> (List Category -> msg) -> Cmd msg
getCategories error ok =
    getJson "/api/categories" Decoders.categories ok error


type SearchMsg
    = SearchSuccess SearchResult
    | SearchFailed Http.Error


search : (SearchMsg -> msg) -> SearchSpec -> Cmd msg
search wmsg params =
    getJson
        (Utils.buildPath "/api/search" (searchParams params))
        Decoders.search
        (wmsg << SearchSuccess)
        (wmsg << SearchFailed)


searchMore : (SearchMsg -> msg) -> SearchResult -> Cmd msg
searchMore wmsg result =
    case result.nextUrl of
        Nothing ->
            Cmd.none

        Just nextUrl ->
            getJson nextUrl Decoders.search (wmsg << SearchSuccess) (wmsg << SearchFailed)


byQuery : Maybe LatLng -> Maybe String -> SearchSpec
byQuery latLng q =
    { emptySearch | latLng = latLng, q = Maybe.andThen discardEmpty q }


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
