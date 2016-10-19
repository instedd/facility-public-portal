module Main exposing (..)

import Map
import Models exposing (..)
import Navigation
import Routing
import Shared
import AppHome
import AppSearch
import AppFacilityDetails
import UserLocation
import Html exposing (Html, div)
import Html.Attributes exposing (id, class)
import Html.App
import Utils exposing (mapFst, mapSnd, mapTCmd)
import Menu


type alias Flags =
    { fakeUserPosition : Bool
    , initialPosition : LatLng
    , contactEmail : String
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
      InitializingVR (Result String Route) LatLng Settings
      -- map initialized pending to determine which view/route to load
    | InitializedVR MapViewport Settings
    | Page PagedModel CommonPageState


type alias CommonPageState =
    { settings : Settings, menu : Menu.Model }


type PagedModel
    = HomeModel AppHome.Model
    | FacilityDetailsModel AppFacilityDetails.Model FacilityDetailsContext
    | SearchModel AppSearch.Model


type MainMsg
    = MapViewportChangedVR MapViewport
    | Navigate Route
    | NavigateBack
    | HomeMsg AppHome.Msg
    | FacilityDetailsMsg AppFacilityDetails.Msg
    | SearchMsg AppSearch.Msg
    | ToggleMenu


type FacilityDetailsContext
    = FromUnkown
    | FromSearch AppSearch.Model


init : Flags -> Result String Route -> ( MainModel, Cmd MainMsg )
init flags route =
    let
        settings =
            { fakeLocation =
                (if flags.fakeUserPosition then
                    Just flags.initialPosition
                 else
                    Nothing
                )
            , contactEmail = flags.contactEmail
            }

        model =
            InitializingVR route flags.initialPosition settings

        cmds =
            [ Map.initializeMap flags.initialPosition ]
    in
        model ! cmds


subscriptions : MainModel -> Sub MainMsg
subscriptions model =
    case model of
        InitializingVR _ _ _ ->
            Map.mapViewportChanged MapViewportChangedVR

        InitializedVR _ _ ->
            Sub.none

        Page pagedModel _ ->
            case pagedModel of
                HomeModel model ->
                    Sub.map HomeMsg <| AppHome.subscriptions model

                FacilityDetailsModel model _ ->
                    Sub.map FacilityDetailsMsg <| AppFacilityDetails.subscriptions model

                SearchModel model ->
                    Sub.map SearchMsg <| AppSearch.subscriptions model


mainUpdate : MainMsg -> MainModel -> ( MainModel, Cmd MainMsg )
mainUpdate msg mainModel =
    case msg of
        Navigate route ->
            ( mainModel, Routing.navigate route )

        NavigateBack ->
            -- remove
            ( mainModel, Navigation.back 1 )

        ToggleMenu ->
            case mainModel of
                Page pagedModel common ->
                    ( Page pagedModel { common | menu = Menu.toggle common.menu }, Cmd.none )

                _ ->
                    ( mainModel, Cmd.none )

        _ ->
            case mainModel of
                InitializingVR route _ settings ->
                    case msg of
                        MapViewportChangedVR mapViewport ->
                            (InitializedVR mapViewport settings)
                                ! [ Routing.navigate (Routing.routeFromResult route) ]

                        _ ->
                            Debug.crash "map is not initialized yet"

                Page pagedModel common ->
                    case pagedModel of
                        HomeModel homeModel ->
                            case msg of
                                HomeMsg msg ->
                                    updatePagedModel HomeModel common <|
                                        case msg of
                                            AppHome.FacilityClicked facilityId ->
                                                ( homeModel, navigateFacility facilityId )

                                            AppHome.ServiceClicked serviceId ->
                                                ( homeModel, navigateSearchService serviceId )

                                            AppHome.LocationClicked locationId ->
                                                ( homeModel, navigateSearchLocation locationId )

                                            AppHome.Search q ->
                                                ( homeModel, navigateSearchQuery q )

                                            AppHome.Private _ ->
                                                mapCmd HomeMsg <| AppHome.update common.settings msg homeModel

                                _ ->
                                    Debug.crash "unexpected message"

                        FacilityDetailsModel facilityModel context ->
                            case msg of
                                FacilityDetailsMsg msg ->
                                    case msg of
                                        AppFacilityDetails.Close ->
                                            ( mainModel
                                            , case context of
                                                FromSearch searchModel ->
                                                    navigateSearch searchModel.query

                                                _ ->
                                                    navigateHome
                                            )

                                        AppFacilityDetails.FacilityClicked facilityId ->
                                            ( Page (FacilityDetailsModel facilityModel context) common, navigateFacility facilityId )

                                        _ ->
                                            mapTCmd
                                                (\m -> Page (FacilityDetailsModel m context) common)
                                                FacilityDetailsMsg
                                                (AppFacilityDetails.update common.settings msg facilityModel)

                                _ ->
                                    Debug.crash "unexpected message"

                        SearchModel searchModel ->
                            case msg of
                                SearchMsg msg ->
                                    updatePagedModel SearchModel common <|
                                        case msg of
                                            AppSearch.Search s ->
                                                ( searchModel, navigateSearch s )

                                            AppSearch.FacilityClicked facilityId ->
                                                ( searchModel, navigateFacility facilityId )

                                            AppSearch.ServiceClicked serviceId ->
                                                ( searchModel, navigateSearchService serviceId )

                                            AppSearch.LocationClicked locationId ->
                                                ( searchModel, navigateSearchLocation locationId )

                                            AppSearch.ClearSearch ->
                                                ( searchModel, navigateHome )

                                            _ ->
                                                mapCmd SearchMsg <| AppSearch.update common.settings msg searchModel

                                _ ->
                                    Debug.crash "unexpected message"

                _ ->
                    ( mainModel, Cmd.none )


mainUrlUpdate : Result String Route -> MainModel -> ( MainModel, Cmd MainMsg )
mainUrlUpdate result mainModel =
    case mainModel of
        InitializingVR _ _ _ ->
            Debug.crash "urlUpdates should be handled after map is initialized"

        _ ->
            let
                viewport =
                    (mapViewport mainModel)

                userLocation =
                    (getUserLocation mainModel)

                common =
                    { settings = getSettings mainModel, menu = Menu.Closed }
            in
                case Routing.routeFromResult result of
                    RootRoute ->
                        updatePagedModel HomeModel common <|
                            mapCmd HomeMsg <|
                                AppHome.init common.settings viewport userLocation

                    FacilityRoute facilityId ->
                        let
                            context =
                                case mainModel of
                                    Page (SearchModel searchModel) _ ->
                                        FromSearch searchModel

                                    Page (FacilityDetailsModel _ previousContext) _ ->
                                        previousContext

                                    _ ->
                                        FromUnkown
                        in
                            updatePagedModel (\m -> FacilityDetailsModel m context) common <|
                                mapCmd FacilityDetailsMsg <|
                                    AppFacilityDetails.init viewport userLocation facilityId

                    SearchRoute searchSpec ->
                        updatePagedModel SearchModel common <|
                            mapCmd SearchMsg <|
                                case mainModel of
                                    Page (FacilityDetailsModel _ (FromSearch searchModel)) _ ->
                                        if searchModel.query == searchSpec then
                                            ( searchModel, AppSearch.restoreCmd )
                                        else
                                            AppSearch.init common.settings searchSpec viewport userLocation

                                    _ ->
                                        AppSearch.init common.settings searchSpec viewport userLocation

                    _ ->
                        Debug.crash "route not handled"


updatePagedModel : (a -> PagedModel) -> CommonPageState -> ( a, Cmd MainMsg ) -> ( MainModel, Cmd MainMsg )
updatePagedModel wmodel common t =
    mapFst (\m -> Page (wmodel m) common) t


mapCmd : (a -> MainMsg) -> ( m, Cmd a ) -> ( m, Cmd MainMsg )
mapCmd =
    mapTCmd identity


mapViewport : MainModel -> MapViewport
mapViewport mainModel =
    case mainModel of
        InitializingVR _ _ _ ->
            Debug.crash "mapViewport should not be called before map is initialized"

        InitializedVR mapViewport _ ->
            mapViewport

        Page pagedModel _ ->
            case pagedModel of
                HomeModel model ->
                    AppHome.mapViewport model

                FacilityDetailsModel model _ ->
                    AppFacilityDetails.mapViewport model

                SearchModel model ->
                    AppSearch.mapViewport model


getSettings : MainModel -> Settings
getSettings mainModel =
    case mainModel of
        InitializingVR _ _ settings ->
            settings

        InitializedVR mapViewport settings ->
            settings

        Page _ common ->
            common.settings


getUserLocation : MainModel -> UserLocation.Model
getUserLocation mainModel =
    case mainModel of
        Page pagedModel _ ->
            case pagedModel of
                HomeModel model ->
                    AppHome.userLocation model

                FacilityDetailsModel model _ ->
                    AppFacilityDetails.userLocation model

                SearchModel model ->
                    AppSearch.userLocation model

        _ ->
            UserLocation.init


mainView : MainModel -> Html MainMsg
mainView mainModel =
    case mainModel of
        Page pagedModel common ->
            case pagedModel of
                HomeModel pagedModel ->
                    mapView HomeMsg common.settings common.menu <| AppHome.view pagedModel

                FacilityDetailsModel pagedModel _ ->
                    mapView FacilityDetailsMsg common.settings common.menu <| AppFacilityDetails.view pagedModel

                SearchModel pagedModel ->
                    mapView SearchMsg common.settings common.menu <| AppSearch.view pagedModel

        InitializingVR _ _ settings ->
            mapView identity settings Menu.Closed { headerClass = "", content = [], toolbar = [], bottom = [], modal = [] }

        InitializedVR _ settings ->
            mapView identity settings Menu.Closed { headerClass = "", content = [], toolbar = [], bottom = [], modal = [] }


mapView : (a -> MainMsg) -> Settings -> Menu.Model -> Shared.MapView a -> Html MainMsg
mapView wmsg settings menuModel viewContent =
    Shared.layout <|
        div
            []
            ([ Shared.controlStack
                ((div [ class viewContent.headerClass ] [ Shared.header [ Menu.anchor ToggleMenu ] ])
                    :: (Menu.orContent settings Menu.Map menuModel (Shared.lmap wmsg viewContent.content))
                )
             ]
                ++ (if List.isEmpty viewContent.bottom then
                        []
                    else
                        [ div [ id "bottom-action", class "z-depth-1" ] (Shared.lmap wmsg viewContent.bottom) ]
                   )
                ++ [ div [ class "map-toolbar" ] (Shared.lmap wmsg viewContent.toolbar) ]
                ++ (if List.isEmpty viewContent.modal then
                        []
                    else
                        [ div [ id "modal", class "modal open" ] (Shared.lmap wmsg viewContent.modal) ]
                   )
            )


navigateHome : Cmd MainMsg
navigateHome =
    Utils.performMessage (Navigate RootRoute)


navigateFacility : Int -> Cmd MainMsg
navigateFacility =
    Utils.performMessage << Navigate << FacilityRoute


navigateSearchService : Int -> Cmd MainMsg
navigateSearchService =
    Utils.performMessage << Navigate << (\id -> SearchRoute { q = Nothing, l = Nothing, latLng = Nothing, s = Just id })


navigateSearchLocation : Int -> Cmd MainMsg
navigateSearchLocation =
    Utils.performMessage << Navigate << (\id -> SearchRoute { q = Nothing, l = Just id, latLng = Nothing, s = Nothing })


navigateSearchQuery : String -> Cmd MainMsg
navigateSearchQuery =
    Utils.performMessage << Navigate << (\q -> SearchRoute { q = Just q, l = Nothing, latLng = Nothing, s = Nothing })


navigateSearch : SearchSpec -> Cmd MainMsg
navigateSearch =
    Utils.performMessage << Navigate << SearchRoute


navigateBack =
    Navigation.back 1
