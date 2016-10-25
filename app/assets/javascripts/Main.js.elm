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
import Html exposing (Html, div, span, p, text, a)
import Html.Attributes exposing (id, class, style, href, attribute, classList)
import Html.App
import Utils exposing (mapFst, mapSnd, mapTCmd)
import Menu
import SelectList exposing (..)


type alias Flags =
    { fakeUserPosition : Bool
    , initialPosition : LatLng
    , contactEmail : String
    , locale : String
    , locales : List ( String, String )
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
    | InitializedVR MapViewport Settings (Maybe Notice)
    | Page PagedModel CommonPageState


type alias CommonPageState =
    { settings : Settings, menu : Menu.Model, route : Route, notice : Maybe Notice }


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
    | DismissNotice


type FacilityDetailsContext
    = FromUnkown
    | FromSearch AppSearch.Model


type alias Notice =
    { message : String, refresh : Bool }


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
            , locale = flags.locale
            , locales = flags.locales
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

        InitializedVR _ _ _ ->
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

        DismissNotice ->
            ( withoutNotice mainModel, Cmd.none )

        _ ->
            case mainModel of
                InitializingVR route _ settings ->
                    case msg of
                        MapViewportChangedVR mapViewport ->
                            (InitializedVR mapViewport settings Nothing)
                                ! [ Routing.navigate (Routing.routeFromResult route) ]

                        _ ->
                            -- Ignore other actions until map is initialized
                            ( mainModel, Cmd.none )

                Page pagedModel common ->
                    case ( pagedModel, msg ) of
                        ( HomeModel homeModel, HomeMsg (AppHome.UnhandledError) ) ->
                            ( withGenericNotice mainModel, Cmd.none )

                        ( HomeModel homeModel, HomeMsg msg ) ->
                            updatePagedModel HomeModel common <|
                                case msg of
                                    AppHome.UnhandledError ->
                                        Utils.unreachable ()

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

                        ( FacilityDetailsModel facilityModel context, FacilityDetailsMsg msg ) ->
                            case msg of
                                AppFacilityDetails.UnhandledError ->
                                    ( withGenericNotice mainModel, Cmd.none )

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

                        ( SearchModel _, SearchMsg (AppSearch.UnhandledError) ) ->
                            ( withGenericNotice mainModel, Cmd.none )

                        ( SearchModel searchModel, SearchMsg msg ) ->
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
                            -- Ignore out of order messages generated by pages other than the current one.
                            ( mainModel, Cmd.none )

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

                route =
                    Routing.routeFromResult result

                common =
                    { settings = getSettings mainModel, menu = Menu.Closed, route = route, notice = notice mainModel }
            in
                case route of
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

                    NotFoundRoute ->
                        ( withNotice unknownRouteErrorNotice mainModel, navigateHome )


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

        InitializedVR mapViewport _ _ ->
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

        InitializedVR mapViewport settings _ ->
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
            let
                withLocale =
                    prependToolbar (localeControlView common.settings common.route)

                withScale =
                    prependToolbar (scaleControlView (mapViewport mainModel).scale)

                withControls =
                    withLocale << withScale
            in
                case pagedModel of
                    HomeModel pagedModel ->
                        mapView HomeMsg common.settings common.menu common.notice <| withControls <| AppHome.view pagedModel

                    FacilityDetailsModel pagedModel _ ->
                        mapView FacilityDetailsMsg common.settings common.menu common.notice <| withControls <| AppFacilityDetails.view pagedModel

                    SearchModel pagedModel ->
                        mapView SearchMsg common.settings common.menu common.notice <| withControls <| AppSearch.view pagedModel

        InitializingVR _ _ settings ->
            mapView identity settings Menu.Closed Nothing { headerClass = "", content = [], toolbar = [], bottom = [], modal = [] }

        InitializedVR _ settings notice ->
            mapView identity settings Menu.Closed notice { headerClass = "", content = [], toolbar = [], bottom = [], modal = [] }


prependToolbar : Html a -> Shared.MapView a -> Shared.MapView a
prependToolbar item view =
    { view | toolbar = item :: view.toolbar }


scaleControlView : MapScale -> Html a
scaleControlView scale =
    div [ class "scale" ]
        [ span [] [ Html.text scale.label ]
        , div [ class "line", style [ ( "width", (toString scale.width) ++ "px" ) ] ] []
        ]


localeControlView : Settings -> Route -> Html a
localeControlView settings route =
    let
        localeUrl lang =
            Utils.setQuery ( "locale", lang ) (Routing.routeToPath route)

        localeAnchor ( key, name ) =
            Html.a [ Html.Attributes.href (localeUrl key), classList [ ( "active", key == settings.locale ) ] ]
                [ Html.text name ]
    in
        div [ class "locales" ] <|
            List.map localeAnchor settings.locales


mapView : (a -> MainMsg) -> Settings -> Menu.Model -> Maybe Notice -> Shared.MapView a -> Html MainMsg
mapView wmsg settings menuModel notice viewContent =
    Shared.layout <|
        div [] <|
            select
                [ include <|
                    Shared.controlStack
                        ((div [ class viewContent.headerClass ] [ Shared.header [ Menu.anchor ToggleMenu ] ])
                            :: (Menu.orContent settings Menu.Map menuModel (Shared.lmap wmsg viewContent.content))
                        )
                , unless (List.isEmpty viewContent.bottom) <|
                    div [ id "bottom-action", class "z-depth-1" ] (Shared.lmap wmsg viewContent.bottom)
                , include <|
                    div [ id "map-toolbar", class "z-depth-1" ] (Shared.lmap wmsg viewContent.toolbar)
                , unless (List.isEmpty viewContent.modal) <|
                    div [ id "modal", class "modal open" ] (Shared.lmap wmsg viewContent.modal)
                , maybe <|
                    Maybe.map noticePopup notice
                ]


noticePopup : Notice -> Html MainMsg
noticePopup notice =
    div [ id "notice", class "card" ]
        [ div [ class "card-content" ]
            [ p [] [ text notice.message ]
            ]
        , div [ class "card-action" ]
            (select
                [ iff notice.refresh <|
                    (a [ href "#", attribute "onClick" "event.preventDefault(); window.location.reload(true)" ] [ text "Refresh" ])
                , include <|
                    (a [ href "#", Shared.onClick DismissNotice ] [ text "Dismiss" ])
                ]
            )
        ]


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


notice : MainModel -> Maybe Notice
notice mainModel =
    case mainModel of
        InitializedVR _ _ notice ->
            notice

        Page _ common ->
            common.notice

        InitializingVR _ _ _ ->
            Nothing


unknownRouteErrorNotice : Notice
unknownRouteErrorNotice =
    { message = "The requested URL does not exist.", refresh = False }


withGenericNotice : MainModel -> MainModel
withGenericNotice mainModel =
    withNotice { message = "Something went wrong. You may want to refresh the application.", refresh = True } mainModel


withNotice : Notice -> MainModel -> MainModel
withNotice notice mainModel =
    case mainModel of
        InitializedVR mapViewport settings _ ->
            InitializedVR mapViewport settings (Just notice)

        Page pagedModel common ->
            Page pagedModel { common | notice = Just notice }

        InitializingVR _ _ _ ->
            mainModel


withoutNotice : MainModel -> MainModel
withoutNotice mainModel =
    case mainModel of
        InitializedVR mapViewport settings _ ->
            InitializedVR mapViewport settings Nothing

        Page pagedModel common ->
            Page pagedModel { common | notice = Nothing }

        InitializingVR _ _ _ ->
            mainModel
