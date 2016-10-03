port module Map exposing (Host, Msg(..), mapViewportChanged, subscriptions, subscriptions2, initializeMap, addUserMarker, clearFacilityMarkers, addFacilityMarker, fitContent, facilityMarkerClicked)

import Json.Encode exposing (..)
import Models exposing (..)


type alias Host msg =
    { mapViewportChanged : MapViewport -> msg
    , facilityMarkerClicked : Int -> msg
    }


type Msg
    = MapViewportChanged MapViewport
    | FacilityMarkerClicked Int


subscriptions2 : Sub Msg
subscriptions2 =
    Sub.batch
        [ mapViewportChanged MapViewportChanged
        , facilityMarkerClicked FacilityMarkerClicked
        ]


subscriptions : Host msg -> Sub msg
subscriptions h =
    Sub.batch
        [ mapViewportChanged h.mapViewportChanged
        , facilityMarkerClicked h.facilityMarkerClicked
        ]


type alias Command =
    ( String, Json.Encode.Value )


port jsCommand : Command -> Cmd msg


port facilityMarkerClicked : (Int -> msg) -> Sub msg


port mapViewportChanged : (MapViewport -> msg) -> Sub msg


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
