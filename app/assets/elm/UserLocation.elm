module UserLocation exposing
    ( Model
    , Msg
    , init
    , toMaybe
    , update
    , view
    )

import Geolocation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Map
import Models exposing (LatLng, Settings)
import Process
import Shared exposing (icon, onClick)
import Spinner exposing (spinner)
import Task
import Time


type Model
    = NoLocation
    | Detecting
    | Detected LatLng


type Msg
    = Geolocate
    | LocationDetected LatLng
    | LocationFailed Geolocation.Error
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
            Detected pos
                ! [ Map.addUserMarker pos ]

        LocationFailed e ->
            -- TODO
            NoLocation ! []

        GotoLocation ->
            model ! [ Map.fitContent ]


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


view : Model -> Html Msg
view model =
    div [ class "location" ]
        [ case model of
            Detecting ->
                spinner [ id "location-spinner" ]

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
