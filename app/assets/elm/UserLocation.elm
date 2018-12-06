module UserLocation exposing
    ( Model
    , Msg
    , init
    , toMaybe
    , update
    , view
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Map
import Models exposing (LatLng, Settings)
import PortFunnel.Geolocation
import Process
import Shared exposing (icon, onClick)
import Task
import Time


type Model
    = NoLocation
    | Detecting
    | Detected LatLng


type Msg
    = Geolocate
    | LocationDetected LatLng
    | LocationFailed PortFunnel.Geolocation.Error
    | GotoLocation


init : Model
init =
    NoLocation


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Geolocate ->
            let
                cmd =
                    s.fakeLocation
                        |> Maybe.map fakeGeolocateUser
                        |> Maybe.withDefault geolocateUser
            in
            ( Detecting, cmd )

        LocationDetected pos ->
            -- TODO remove old user marker in case he/she moved (?)
            ( Detected pos, Map.addUserMarker pos )

        LocationFailed e ->
            -- TODO
            ( NoLocation, Cmd.none )

        GotoLocation ->
            ( model, Map.fitContent )


fakeGeolocateUser : LatLng -> Cmd Msg
fakeGeolocateUser pos =
    Process.sleep 1500
        |> Task.map (always pos)
        |> Task.perform LocationDetected


geolocateUser : Cmd Msg
geolocateUser =
    let
        handler =
            \result ->
                case result of
                    Ok latlng ->
                        LocationDetected latlng

                    Err err ->
                        LocationFailed err
    in
    PortFunnel.Geolocation.now
        |> Task.map (\location -> ( location.latitude, location.longitude ))
        |> Task.perform handler


view : Model -> Html Msg
view model =
    div [ class "location" ]
        [ case model of
            Detecting ->
                div [ id "location-spinner", class "preloader-wrapper small active" ]
                    [ div [ class "spinner-layer spinner-blue-only" ]
                        [ div [ class "circle-clipper left" ]
                            [ div [ class "circle" ] [] ]
                        , div [ class "gap-patch" ] []
                        , div [ class "circle-clipper-right" ]
                            [ div [ class "circle" ] [] ]
                        ]
                    ]

            NoLocation ->
                a [ href "#", onClick Geolocate ]
                    [ icon "my_location" ]

            Detected _ ->
                a [ href "#", onClick GotoLocation, class "detected" ]
                    [ icon "my_location" ]
        ]


toMaybe : Model -> Maybe LatLng
toMaybe model =
    case model of
        Detected latLng ->
            Just latLng

        _ ->
            Nothing
