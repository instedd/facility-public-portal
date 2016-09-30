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
import Utils exposing (..)


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


getSuggestions : Maybe LatLng -> String -> Cmd Msg
getSuggestions latLng query =
    let
        url =
            Search.suggestionsPath "/api/suggest" latLng query
    in
        Task.perform SuggestionsFailed (SuggestionsSuccess query) (Http.get Decoders.suggestions url)
