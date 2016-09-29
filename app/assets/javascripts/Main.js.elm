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
    | FacilityDetailsModel AppFacilityDetails.Model


type MainMsg
    = MapViewportChangedVR MapViewport
    | Navigate Route
    | HomeMsg AppHome.Msg
    | FacilityDetailsMsg AppFacilityDetails.Msg


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
    case model of
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
            AppHome.subscriptions hostAppHome model

        FacilityDetailsModel model ->
            AppFacilityDetails.subscriptions hostAppFacilityDetails model


mainUpdate : MainMsg -> MainModel -> ( MainModel, Cmd MainMsg )
mainUpdate msg mainModel =
    case Debug.log "mainUpdate" msg of
        Navigate route ->
            ( mainModel, Routing.navigate route )

        _ ->
            case mainModel of
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
                    case msg of
                        HomeMsg msg ->
                            AppHome.update hostAppHome msg model

                        _ ->
                            Debug.crash "unexpected message"

                FacilityDetailsModel model ->
                    case msg of
                        FacilityDetailsMsg msg ->
                            AppFacilityDetails.update hostAppFacilityDetails msg model

                        _ ->
                            Debug.crash "unexpected message"

                _ ->
                    ( mainModel, Cmd.none )


mainUrlUpdate : Result String Route -> MainModel -> ( MainModel, Cmd MainMsg )
mainUrlUpdate result mainModel =
    case mainModel of
        InitializingVR _ _ ->
            Debug.crash "urlUpdates should be handled after map is initialized"

        _ ->
            let
                viewport =
                    (mapViewport mainModel)
            in
                case Routing.routeFromResult result of
                    RootRoute ->
                        AppHome.init hostAppHome viewport

                    FacilityRoute facilityId ->
                        AppFacilityDetails.init hostAppFacilityDetails viewport facilityId

                    _ ->
                        Debug.crash "route not handled"


mapViewport : MainModel -> MapViewport
mapViewport mainModel =
    case mainModel of
        InitializedVR mapViewport ->
            mapViewport

        HomeModel model ->
            AppHome.mapViewport model

        FacilityDetailsModel model ->
            AppFacilityDetails.mapViewport model

        _ ->
            Debug.crash "not implemented"


mainView : MainModel -> Html MainMsg
mainView mainModel =
    case mainModel of
        HomeModel model ->
            AppHome.view hostAppHome model

        FacilityDetailsModel model ->
            AppFacilityDetails.view hostAppFacilityDetails model

        _ ->
            Shared.mapWithControl Nothing


hostAppHome : AppHome.Host MainModel MainMsg
hostAppHome =
    { model = HomeModel, msg = HomeMsg, facilityClicked = Navigate << FacilityRoute }


hostAppFacilityDetails : AppFacilityDetails.Host MainModel MainMsg
hostAppFacilityDetails =
    { model = FacilityDetailsModel, msg = FacilityDetailsMsg }



--andCmd : ( MainModel, Cmd MainMsg ) -> Cmd MainMsg -> ( MainModel, Cmd MainMsg )
--andCmd ( m, cmd1 ) cmd2 =
--    ( m, Cmd.batch [ cmd2, cmd1 ] )
