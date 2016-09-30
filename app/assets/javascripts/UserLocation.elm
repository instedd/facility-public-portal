module UserLocation exposing (Host, Model, Msg, init, update, view)

import Models exposing (LatLng)
import Utils exposing (mapFst)
import Geolocation
import Commands
import Process
import Time
import Task
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Shared exposing (icon, onClick)


type Model
    = NoLocation
    | Detecting
    | Detected LatLng


type Msg
    = Geolocate
    | LocationDetected LatLng
    | LocationFailed Geolocation.Error


type alias Host model msg =
    { setModel : model -> Model -> model
    , msg : Msg -> msg
    , fakeLocation : Maybe LatLng
    }


init : Host model msg -> Model
init h =
    NoLocation


update : Host model msg -> Msg -> model -> ( model, Cmd msg )
update h msg model =
    mapFst (h.setModel model) <|
        case msg of
            Geolocate ->
                let
                    cmd =
                        h.fakeLocation
                            |> Maybe.map (fakeGeolocateUser h)
                            |> Maybe.withDefault (geolocateUser h)
                in
                    ( Detecting, cmd )

            LocationDetected pos ->
                -- TODO remove old user marker in case he/she moved (?)
                Detected pos
                    ! [ Commands.fitContent, Commands.addUserMarker pos ]

            LocationFailed e ->
                -- TODO
                NoLocation ! []


fakeGeolocateUser : Host model msg -> LatLng -> Cmd msg
fakeGeolocateUser h pos =
    Process.sleep (1.5 * Time.second)
        |> Task.map (always pos)
        |> Task.perform (h.msg << LocationFailed) (h.msg << LocationDetected)


geolocateUser : Host model msg -> Cmd msg
geolocateUser h =
    Geolocation.now
        |> Task.map (\location -> ( location.latitude, location.longitude ))
        |> Task.perform (h.msg << LocationFailed) (h.msg << LocationDetected)


view : Host model msg -> Model -> Html msg
view h model =
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

            _ ->
                a [ href "#", onClick (h.msg Geolocate) ]
                    [ icon "my_location" ]
        ]
