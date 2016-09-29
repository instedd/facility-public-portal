module Main exposing (..)

import Commands exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Navigation
import Routing
import Update


--

import Shared
import AppHome
import AppSearch
import AppFacilityDetails
import Html exposing (Html)


type alias Flags =
    { fakeUserPosition : Bool
    , initialPosition : LatLng
    }


main : Program Flags
main =
    Navigation.programWithFlags Routing.parser
        { init = init
        , view = mainView
        , update = mainUpdate
        , subscriptions = subscriptions
        , urlUpdate = mainUrlUpdate
        }


type MainModel
    = -- pending map to be initialized from flag
      InitializingVR (Result String Route) LatLng
      -- map initialized pending to determine which view/route to load
    | InitializedVR MapViewport
    | HomeModel AppHome.Model


type MainMsg
    = MapViewportChangedVR MapViewport
    | HomeMsg AppHome.Msg


init : Flags -> Result String Route -> ( MainModel, Cmd MainMsg )
init flags route =
    let
        model =
            InitializingVR route flags.initialPosition

        cmds =
            [ Commands.initializeMap flags.initialPosition ]
    in
        model ! cmds


subscriptions : MainModel -> Sub MainMsg
subscriptions model =
    case Debug.log "sdf" model of
        InitializingVR _ _ ->
            mapViewportChanged MapViewportChangedVR

        InitializedVR _ ->
            Sub.none

        --Sub.batch
        --[ -- facilityMarkerClicked (\id -> Navigate (FacilityRoute id))
        -- ,
        --mapViewportChanged
        --(\viewPort -> MapViewportChangedVR viewPort)
        --]
        HomeModel model ->
            AppHome.subscriptions HomeMsg model


mainUpdate : MainMsg -> MainModel -> ( MainModel, Cmd MainMsg )
mainUpdate msg mainModel =
    case Debug.log "mainUpdate" mainModel of
        InitializingVR route _ ->
            case msg of
                MapViewportChangedVR mapViewport ->
                    (InitializedVR mapViewport)
                        ! [ Routing.navigate (Routing.routeFromResult route)
                            -- , Commands.currentDate
                          ]

                _ ->
                    Debug.crash "map is not initialized yet"

        HomeModel model ->
            case Debug.log "msg" msg of
                HomeMsg msg ->
                    AppHome.update HomeModel HomeMsg msg model

                _ ->
                    ( mainModel, Cmd.none )

        _ ->
            ( mainModel, Cmd.none )


mainUrlUpdate : Result String Route -> MainModel -> ( MainModel, Cmd MainMsg )
mainUrlUpdate result mainModel =
    case mainModel of
        InitializedVR mapViewport ->
            case Debug.log "mainUrlUpdate" (Routing.routeFromResult result) of
                RootRoute ->
                    AppHome.init HomeModel HomeMsg mapViewport

                _ ->
                    Debug.crash "TODO"

        _ ->
            Debug.crash "urlUpdates should be handled after map is initialized"


mainView : MainModel -> Html MainMsg
mainView mainModel =
    case Debug.log "mainView" mainModel of
        HomeModel model ->
            AppHome.view HomeMsg model

        _ ->
            Shared.mapWithControl Nothing
