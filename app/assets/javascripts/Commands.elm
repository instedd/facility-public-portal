port module Commands exposing (..)

import Decoders exposing (..)
import Geolocation
import Http
import Json.Encode exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Process
import Search
import Task
import Time


port jsCommand : Command -> Cmd msg


port facilityMarkerClicked : (Int -> msg) -> Sub msg


port mapViewportChanged : (MapViewport -> msg) -> Sub msg


type alias Command =
    ( String, Json.Encode.Value )


initializeMap : ( Float, Float ) -> Cmd msg
initializeMap pos =
    jsCommand ( "initializeMap", encodeLatLng pos )


addUserMarker : ( Float, Float ) -> Cmd msg
addUserMarker pos =
    jsCommand ( "addUserMarker", encodeLatLng pos )


fitContent : Cmd msg
fitContent =
    jsCommand ( "fitContent", null )


clearFacilityMarkers : Cmd msg
clearFacilityMarkers =
    jsCommand ( "clearFacilityMarkers", null )


addFacilityMarker : Facility -> Cmd msg
addFacilityMarker facility =
    jsCommand ( "addFacilityMarker", encodeFacility facility )


encodeLatLng : ( Float, Float ) -> Json.Encode.Value
encodeLatLng ( lat, lng ) =
    object
        [ ( "lat", float lat )
        , ( "lng", float lng )
        ]


encodeFacility : Facility -> Json.Encode.Value
encodeFacility facility =
    object
        [ ( "id", int facility.id )
        , ( "position", encodeLatLng facility.position )
        ]


fakeGeolocateUser : LatLng -> Cmd Msg
fakeGeolocateUser pos =
    Process.sleep (1.5 * Time.second)
        |> Task.map (always pos)
        |> Task.perform LocationFailed LocationDetected


geolocateUser : Cmd Msg
geolocateUser =
    Geolocation.now
        |> Task.map (\location -> ( location.latitude, location.longitude ))
        |> Task.perform LocationFailed LocationDetected


getSuggestions : Maybe LatLng -> String -> Cmd Msg
getSuggestions latLng query =
    let
        url =
            Search.suggestionsPath "/api/suggest" latLng query
    in
        Task.perform SuggestionsFailed (SuggestionsSuccess query) (Http.get Decoders.suggestions url)


search : SearchSpec -> Cmd Msg
search params =
    let
        url =
            Search.path "/api/search" params
    in
        Task.perform SearchFailed SearchSuccess (Http.get Decoders.search url)


searchMore : SearchResult -> Cmd Msg
searchMore result =
    case result.nextUrl of
        Nothing ->
            Cmd.none

        Just nextUrl ->
            Task.perform SearchFailed SearchLoadMoreSuccess (Http.get Decoders.search nextUrl)


fetchFacility : Int -> Cmd Msg
fetchFacility id =
    let
        url =
            "/api/facilities/" ++ (toString id)
    in
        Task.perform FacilityFethFailed FacilityFecthSuccess (Http.get Decoders.facility url)
