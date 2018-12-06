module Main exposing (CommonPageState, FacilityDetailsContext(..), Flags, MainModel(..), MainMsg(..), Notice, PagedModel(..), displayErrorDetail, getSettings, getUserLocation, init, loadingView, localeControlView, main, mainUpdate, mainUrlUpdate, mainView, mapView, mapViewport, navigateBack, navigateFacility, navigateHome, navigateSearch, navigateSearchCategory, navigateSearchLocation, notice, noticePopup, prependToolbar, scaleControlView, subscriptions, unknownRouteErrorNotice, withErrorNotice, withNotice, withoutNotice)

import AppFacilityDetails
import AppHome
import AppSearch
import Browser exposing (application)
import Browser.Navigation
import Html exposing (Html, a, div, p, span, text)
import Html.Attributes exposing (attribute, class, classList, href, id, style)
import Layout
import Map
import Menu
import Models exposing (..)
import Return exposing (..)
import Routing
import SelectList exposing (..)
import Shared
import UserLocation
import Utils


type alias Flags =
    { fakeUserPosition : Bool
    , initialPosition : LatLng
    , contactEmail : String
    , locale : String
    , locales : List ( String, String )
    , facilityTypes : List FacilityType
    , ownerships : List Ownership
    , categoryGroups : List CategoryGroup
    , facilityPhotos : Bool
    }


displayErrorDetail : Bool
displayErrorDetail =
    False


main : Program Flags MainModel MainMsg
main =
    Browser.application
        { init = init
        , view = mainView
        , update = mainUpdate
        , subscriptions = subscriptions
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }


type MainModel
    = -- pending map to be initialized from flag
      Initializing (Result String Route) LatLng Settings
      -- map initialized pending to determine which view/route to load
    | Initialized MapViewport Settings (Maybe Notice)
    | Page CommonPageState PagedModel


type alias CommonPageState =
    { settings : Settings
    , menu : Menu.Model
    , route : Route
    , expanded : Bool
    , notice : Maybe Notice
    }


type PagedModel
    = HomeModel AppHome.Model
    | FacilityDetailsModel AppFacilityDetails.Model FacilityDetailsContext
    | SearchModel AppSearch.Model


type MainMsg
    = MapViewportChanged MapViewport
    | Navigate Route
    | HomeMsg AppHome.Msg
    | FacilityDetailsMsg AppFacilityDetails.Msg
    | SearchMsg AppSearch.Msg
    | ToggleMenu
    | ToggleExpand
    | DismissNotice
    | ClickedLink Browser.UrlRequest
    | ChangedUrl Url


type FacilityDetailsContext
    = FromUnknown Bool
    | FromSearch AppSearch.Model Bool


type alias Notice =
    { message : String, refresh : Bool }


init : Flags -> Result String Route -> ( MainModel, Cmd MainMsg )
init flags route =
    let
        settings =
            { fakeLocation =
                if flags.fakeUserPosition then
                    Just flags.initialPosition

                else
                    Nothing
            , contactEmail = flags.contactEmail
            , locale = flags.locale
            , locales = flags.locales
            , facilityTypes = flags.facilityTypes
            , ownerships = flags.ownerships
            , categoryGroups = flags.categoryGroups
            , facilityPhotos = flags.facilityPhotos
            }

        model =
            Initializing route flags.initialPosition settings

        cmds =
            [ Map.initializeMap flags.initialPosition ]
    in
    model ! cmds


subscriptions : MainModel -> Sub MainMsg
subscriptions model =
    case model of
        Initializing _ _ _ ->
            Map.mapViewportChanged MapViewportChanged

        Initialized _ _ _ ->
            Sub.none

        Page _ pagedModel ->
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

        ToggleMenu ->
            case mainModel of
                Page common pagedModel ->
                    ( Page { common | menu = Menu.toggle common.menu } pagedModel, Cmd.none )

                _ ->
                    ( mainModel, Cmd.none )

        ToggleExpand ->
            case mainModel of
                Page common pagedModel ->
                    ( mainModel, Routing.toggleExpandedParam common.route )

                _ ->
                    singleton mainModel

        DismissNotice ->
            ( withoutNotice mainModel, Cmd.none )

        _ ->
            case mainModel of
                Initializing route _ settings ->
                    case msg of
                        MapViewportChanged mapViewport ->
                            Initialized mapViewport settings Nothing
                                ! [ Routing.navigate (Routing.routeFromResult route) ]

                        _ ->
                            -- Ignore other actions until map is initialized
                            ( mainModel, Cmd.none )

                Page common pagedModel ->
                    case ( pagedModel, msg ) of
                        ( HomeModel homeModel, HomeMsg (AppHome.UnhandledError msg) ) ->
                            ( withErrorNotice msg mainModel, Cmd.none )

                        ( HomeModel homeModel, HomeMsg msg ) ->
                            (case msg of
                                AppHome.UnhandledError msg ->
                                    ( homeModel, Cmd.none )

                                AppHome.FacilityClicked facilityId ->
                                    ( homeModel, navigateFacility facilityId )

                                AppHome.CategoryClicked categoryId ->
                                    ( homeModel, navigateSearchCategory categoryId )

                                AppHome.LocationClicked locationId ->
                                    ( homeModel, navigateSearchLocation locationId )

                                AppHome.Search search ->
                                    ( homeModel, navigateSearch common.expanded search )

                                AppHome.Private _ ->
                                    mapCmd HomeMsg <| AppHome.update common.settings msg homeModel
                            )
                                |> map HomeModel
                                |> map (Page common)

                        ( FacilityDetailsModel facilityModel context, FacilityDetailsMsg msg ) ->
                            case msg of
                                AppFacilityDetails.UnhandledError msg ->
                                    ( withErrorNotice msg mainModel, Cmd.none )

                                AppFacilityDetails.Close ->
                                    ( mainModel
                                    , case context of
                                        FromSearch searchModel expanded ->
                                            navigateSearch expanded searchModel.query

                                        FromUnknown expanded ->
                                            navigateHome expanded
                                    )

                                AppFacilityDetails.FacilityClicked facilityId ->
                                    ( Page common (FacilityDetailsModel facilityModel context), navigateFacility facilityId )

                                _ ->
                                    AppFacilityDetails.update common.settings msg facilityModel
                                        |> mapCmd FacilityDetailsMsg
                                        |> map (\m -> FacilityDetailsModel m context)
                                        |> map (Page common)

                        ( SearchModel _, SearchMsg (AppSearch.UnhandledError msg) ) ->
                            ( withErrorNotice msg mainModel, Cmd.none )

                        ( SearchModel searchModel, SearchMsg msg ) ->
                            (case msg of
                                AppSearch.Search s ->
                                    ( searchModel, navigateSearch common.expanded s )

                                AppSearch.FacilityClicked facilityId ->
                                    ( searchModel, navigateFacility facilityId )

                                AppSearch.CategoryClicked categoryId ->
                                    ( searchModel, navigateSearchCategory categoryId )

                                AppSearch.LocationClicked locationId ->
                                    ( searchModel, navigateSearchLocation locationId )

                                AppSearch.ClearSearch ->
                                    ( searchModel, navigateHome False )

                                _ ->
                                    mapCmd SearchMsg <| AppSearch.update common.settings msg searchModel
                            )
                                |> map SearchModel
                                |> map (Page common)

                        _ ->
                            -- Ignore out of order messages generated by pages other than the current one.
                            ( mainModel, Cmd.none )

                _ ->
                    ( mainModel, Cmd.none )


mainUrlUpdate : Result String Route -> MainModel -> ( MainModel, Cmd MainMsg )
mainUrlUpdate result mainModel =
    case mainModel of
        Initializing _ _ _ ->
            Debug.crash "urlUpdates should be handled after map is initialized"

        _ ->
            let
                viewport =
                    mapViewport mainModel

                userLocation =
                    getUserLocation mainModel

                route =
                    Routing.routeFromResult result

                common =
                    { settings = getSettings mainModel
                    , menu = Menu.Closed
                    , route = route
                    , expanded = False
                    , notice = notice mainModel
                    }
            in
            case route of
                RootRoute { expanded } ->
                    AppHome.init common.settings viewport userLocation
                        |> mapBoth HomeMsg HomeModel
                        |> map (Page { common | expanded = expanded })

                FacilityRoute facilityId ->
                    let
                        context =
                            case mainModel of
                                Page { expanded } (SearchModel searchModel) ->
                                    FromSearch searchModel expanded

                                Page _ (FacilityDetailsModel _ previousContext) ->
                                    previousContext

                                Page { expanded } _ ->
                                    FromUnknown expanded

                                _ ->
                                    FromUnknown False
                    in
                    AppFacilityDetails.init viewport userLocation facilityId
                        |> mapBoth FacilityDetailsMsg (flip FacilityDetailsModel context)
                        |> map (Page common)

                SearchRoute { spec, expanded } ->
                    (case mainModel of
                        Page _ (FacilityDetailsModel _ (FromSearch searchModel _)) ->
                            if searchModel.query == spec then
                                ( searchModel, AppSearch.restoreCmd )

                            else
                                AppSearch.init common.settings spec viewport userLocation

                        _ ->
                            AppSearch.init common.settings spec viewport userLocation
                    )
                        |> mapBoth SearchMsg SearchModel
                        |> map (Page { common | expanded = expanded })

                NotFoundRoute ->
                    ( withNotice unknownRouteErrorNotice mainModel, navigateHome False )


mapViewport : MainModel -> MapViewport
mapViewport mainModel =
    case mainModel of
        Initializing _ _ _ ->
            Debug.crash "mapViewport should not be called before map is initialized"

        Initialized mapViewport _ _ ->
            mapViewport

        Page _ pagedModel ->
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
        Initializing _ _ settings ->
            settings

        Initialized mapViewport settings _ ->
            settings

        Page common _ ->
            common.settings


getUserLocation : MainModel -> UserLocation.Model
getUserLocation mainModel =
    case mainModel of
        Page _ pagedModel ->
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
        Page common pagedModel ->
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
                    AppHome.view pagedModel
                        |> withControls
                        |> mapView HomeMsg common

                FacilityDetailsModel pagedModel _ ->
                    AppFacilityDetails.view common.settings pagedModel
                        |> withControls
                        |> mapView FacilityDetailsMsg common

                SearchModel pagedModel ->
                    AppSearch.view pagedModel
                        |> withControls
                        |> mapView SearchMsg common

        Initializing _ _ _ ->
            loadingView Nothing

        Initialized _ _ notice ->
            loadingView notice


prependToolbar : Html a -> Layout.MapView a -> Layout.MapView a
prependToolbar item view =
    { view | toolbar = item :: view.toolbar }


scaleControlView : MapScale -> Html a
scaleControlView scale =
    div [ class "scale" ]
        [ span [] [ Html.text scale.label ]
        , div [ class "line", style [ ( "width", toString scale.width ++ "px" ) ] ] []
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


loadingView : Maybe Notice -> Html MainMsg
loadingView notice =
    Layout.overMap <|
        select
            [ include <| Layout.sideControl (Layout.header [] []) []
            , maybe <| Maybe.map noticePopup notice
            ]


mapView : (a -> MainMsg) -> CommonPageState -> Layout.MapView a -> Html MainMsg
mapView wmsg { settings, menu, expanded, notice } viewContent =
    let
        menuSettings =
            { contactEmail = settings.contactEmail
            , showEdition = False
            }

        hosting =
            Shared.lmap wmsg

        togglingMenu =
            Menu.togglingContent menuSettings Menu.Map menu

        mobileMenu =
            Menu.sideBar menuSettings Menu.Map menu ToggleMenu

        header =
            Layout.header [ Menu.anchor ToggleMenu ] viewContent.headerClasses

        collapsedView =
            togglingMenu (hosting viewContent.content)

        expandedView =
            viewContent.expandedContent
                |> Maybe.map
                    (\{ side, main } ->
                        { side = togglingMenu (hosting side)
                        , main = Menu.dimWhenOpen (hosting main) menu
                        }
                    )

        mapControl =
            Layout.expansibleControl header expanded ToggleExpand collapsedView expandedView
    in
    Layout.overMap <|
        select
            [ include <|
                mapControl
            , unless (List.isEmpty viewContent.bottom) <|
                div [ id "bottom-action", class "z-depth-1" ] (hosting viewContent.bottom)
            , include <|
                div [ id "map-toolbar", class "z-depth-1" ] (hosting viewContent.toolbar)
            , unless (List.isEmpty viewContent.modal) <|
                div [ id "modal", class "modal open" ] (hosting viewContent.modal)
            , include <|
                mobileMenu
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
                    a [ href "#", attribute "onClick" "event.preventDefault(); window.location.reload(true)" ] [ text "Refresh" ]
                , include <|
                    a [ href "#", Shared.onClick DismissNotice ] [ text "Dismiss" ]
                ]
            )
        ]


navigateHome : Bool -> Cmd MainMsg
navigateHome expanded =
    Utils.performMessage (Navigate <| RootRoute { expanded = expanded })


navigateFacility : Int -> Cmd MainMsg
navigateFacility =
    Utils.performMessage << Navigate << FacilityRoute


navigateSearchCategory : Int -> Cmd MainMsg
navigateSearchCategory id =
    Utils.performMessage <|
        Navigate (SearchRoute { spec = { emptySearch | category = Just id }, expanded = False })


navigateSearchLocation : Int -> Cmd MainMsg
navigateSearchLocation id =
    Utils.performMessage <|
        Navigate (SearchRoute { spec = { emptySearch | location = Just id }, expanded = False })


navigateSearch : Bool -> SearchSpec -> Cmd MainMsg
navigateSearch expanded spec =
    Utils.performMessage <|
        Navigate (SearchRoute { expanded = expanded, spec = spec })


navigateBack : Cmd MainMsg
navigateBack =
    Navigation.back 1


notice : MainModel -> Maybe Notice
notice mainModel =
    case mainModel of
        Initialized _ _ notice ->
            notice

        Page common _ ->
            common.notice

        Initializing _ _ _ ->
            Nothing


unknownRouteErrorNotice : Notice
unknownRouteErrorNotice =
    { message = "The requested URL does not exist.", refresh = False }


withErrorNotice : String -> MainModel -> MainModel
withErrorNotice msg mainModel =
    mainModel
        |> withNotice
            (if displayErrorDetail then
                { message = msg, refresh = True }

             else
                { message = "Something went wrong. You may want to refresh the application.", refresh = True }
            )


withNotice : Notice -> MainModel -> MainModel
withNotice notice mainModel =
    case mainModel of
        Initialized mapViewport settings _ ->
            Initialized mapViewport settings (Just notice)

        Page common pagedModel ->
            Page { common | notice = Just notice } pagedModel

        Initializing _ _ _ ->
            mainModel


withoutNotice : MainModel -> MainModel
withoutNotice mainModel =
    case mainModel of
        Initialized mapViewport settings _ ->
            Initialized mapViewport settings Nothing

        Page common pagedModel ->
            Page { common | notice = Nothing } pagedModel

        Initializing _ _ _ ->
            mainModel
