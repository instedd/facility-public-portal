module AppFacilityDetails exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Models exposing (Settings, MapViewport, Facility)
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Shared exposing (MapView)
import Api
import Date exposing (Date)
import Utils exposing (mapTCmd)
import Time
import String
import Task
import Map
import UserLocation


type Model
    = Loading MapViewport Int (Maybe Date) UserLocation.Model
    | Loaded MapViewport Facility (Maybe Date) UserLocation.Model Bool Bool


type PrivateMsg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date
    | UserLocationMsg UserLocation.Msg
    | ToggleMobileFocus
    | ToggleFacilityReport


type Msg
    = Close
    | FacilityClicked Int
    | Private PrivateMsg


init : MapViewport -> UserLocation.Model -> Int -> ( Model, Cmd Msg )
init mapViewport userLocation facilityId =
    Loading mapViewport facilityId Nothing userLocation
        ! [ Api.fetchFacility (Private << ApiFetch) facilityId
          , currentDate
          , Map.fitContentUsingPadding True
          ]


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Private msg ->
            case msg of
                CurrentDate date ->
                    ( setDate date model, Cmd.none )

                ApiFetch (Api.FetchFacilitySuccess facility) ->
                    (Loaded (mapViewport model) facility (date model) (userLocation model) False False)
                        ! ((if (Models.contains (mapViewport model) facility.position) then
                                []
                            else
                                [ Map.fitContent ]
                           )
                            ++ [ Map.setHighlightedFacilityMarker facility ]
                          )

                UserLocationMsg msg ->
                    mapTCmd (\l -> setUserLocation l model) (Private << UserLocationMsg) <|
                        UserLocation.update s msg (userLocation model)

                ToggleMobileFocus ->
                    case model of
                        Loading _ _ _ _ ->
                            ( model, Cmd.none )

                        Loaded a b c d e f ->
                            ( Loaded a b c d (not e) f, Cmd.none )

                ToggleFacilityReport ->
                    ( (setReportWindow (not <| isReportWindowOpen model) model), Cmd.none )

                _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

        _ ->
            -- public events
            ( model, Cmd.none )


view : Model -> MapView Msg
view model =
    let
        onlyMobile =
            ( "hide-on-large-only", True )

        hideOnMobileMapFocused =
            ( "hide-on-med-and-down", mobileFocusMap model )

        hideOnMobileDetailsFocused =
            ( "hide-on-med-and-down", not (mobileFocusMap model) )
    in
        { headerAttributes = [ classList [ hideOnMobileDetailsFocused ] ]
        , content =
            [ case model of
                Loading _ _ _ _ ->
                    div
                        [ class "preloader-wrapper small active" ]
                        [ div [ class "spinner-layer spinner-blue-only" ]
                            [ div [ class "circle-clipper left" ]
                                [ div [ class "circle" ] [] ]
                            , div [ class "gap-patch" ]
                                [ div [ class "circle" ] [] ]
                            , div [ class "circle-clipper right" ]
                                [ div [ class "circle" ] [] ]
                            ]
                        ]

                Loaded _ facility date _ _ _ ->
                    facilityDetail [ hideOnMobileMapFocused ] date facility
            ]
        , toolbar =
            [ userLocationView model ]
        , bottom =
            [ div
                [ classList [ hideOnMobileDetailsFocused ] ]
                [ mobileFocusToggleView ]
            ]
        , modal = openReportWindow model
        }


mobileFocusToggleView =
    a
        [ href "#"
        , Shared.onClick (Private ToggleMobileFocus)
        ]
        [ text "Show details" ]


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.viewMapControl (userLocation model))


openReportWindow : Model -> List (Html Msg)
openReportWindow model =
    if isReportWindowOpen model then
        [ div [ class "modal-content" ]
            [ div [ class "header" ]
                [ text "Report an issue"
                , a [ class "right", Events.onClick (Private ToggleFacilityReport) ] [ Shared.icon "close" ]
                ]
            , div [ class "body" ]
                [ Html.form [ action "#", method "GET" ]
                    [ p []
                        [ input [ type' "checkbox", id "wrong_location" ] []
                        , label [ for "wrong_location" ] [ text "Wrong location" ]
                        ]
                    , p []
                        [ input [ type' "checkbox", id "closed" ] []
                        , label [ for "closed" ] [ text "Facility closed" ]
                        ]
                    , p []
                        [ input [ type' "checkbox", id "contact_info_missing" ] []
                        , label [ for "contact_info_missing" ] [ text "Incomplete contact info" ]
                        ]
                    , p []
                        [ input [ type' "checkbox", id "inaccurate_services" ] []
                        , label [ for "inaccurate_services" ] [ text "Inaccurate service list" ]
                        ]
                    , p []
                        [ input [ type' "checkbox", id "other" ] []
                        , label [ for "other" ] [ text "Other" ]
                        ]
                    ]
                ]
            ]
        , div [ class "modal-footer" ]
            [ a [ class "btn-flat" ] [ text "Send report" ] ]
        ]
    else
        []


subscriptions : Model -> Sub Msg
subscriptions model =
    Map.facilityMarkerClicked FacilityClicked


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ _ _ ->
            mapViewport

        Loaded mapViewport _ _ _ _ _ ->
            mapViewport


date : Model -> Maybe Date
date model =
    case model of
        Loading _ _ date _ ->
            date

        Loaded _ _ date _ _ _ ->
            date


setDate : Date -> Model -> Model
setDate date model =
    case model of
        Loading a b _ d ->
            Loading a b (Just date) d

        Loaded a b _ d e f ->
            Loaded a b (Just date) d e f


setReportWindow : Bool -> Model -> Model
setReportWindow bool model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d e _ ->
            Loaded a b c d e bool


isReportWindowOpen : Model -> Bool
isReportWindowOpen model =
    case model of
        Loading a b c d ->
            False

        Loaded a b c d e bool ->
            bool


userLocation : Model -> UserLocation.Model
userLocation model =
    case model of
        Loading _ _ _ userLocation ->
            userLocation

        Loaded _ _ _ userLocation _ _ ->
            userLocation


setUserLocation : UserLocation.Model -> Model -> Model
setUserLocation userLocation model =
    case model of
        Loading a b c _ ->
            Loading a b c userLocation

        Loaded a b c _ e f ->
            Loaded a b c userLocation e f


mobileFocusMap : Model -> Bool
mobileFocusMap model =
    case model of
        Loading _ _ _ _ ->
            True

        Loaded _ _ _ _ b _ ->
            b


currentDate : Cmd Msg
currentDate =
    let
        notFailing x =
            notFailing x
    in
        Task.perform notFailing (Utils.dateFromEpochMillis >> CurrentDate >> Private) Time.now


facilityDetail : List ( String, Bool ) -> Maybe Date -> Facility -> Html Msg
facilityDetail cssClasses now facility =
    let
        lastUpdatedSub =
            case facility.lastUpdated of
                Nothing ->
                    ""

                Just date ->
                    now
                        |> Maybe.map (\date -> String.concat [ "Last updated ", Utils.timeAgo date date, " ago" ])
                        |> Maybe.withDefault ""

        entry icon value =
            value |> Maybe.withDefault "Unavailable" |> (,) icon

        contactInfo =
            [ entry "local_post_office" facility.contactEmail
            , entry "local_phone" facility.contactPhone
              -- , entry "public" facility.url
              -- , entry "directions" facility.address
            ]
    in
        div [ classList <| ( "facilityDetail", True ) :: cssClasses ]
            [ div [ class "title" ]
                [ span [ class "name" ]
                    [ text facility.name
                    , span [ class "sub" ] [ text lastUpdatedSub ]
                    ]
                , i
                    [ class "material-icons right", Events.onClick Close ]
                    [ text "clear" ]
                ]
            , div [ class "content" ]
                [ div [ class "detailSection pic" ] [ img [ src "/facility.png" ] [] ]
                , div [ class "detailSection actions" ] [ facilityActions ]
                , div [ class "detailSection contact" ] [ facilityContactDetails contactInfo ]
                , div [ class "detailSection services" ]
                    [ span [] [ text "Services" ]
                    , if List.isEmpty facility.services then
                        div [ class "noData" ] [ text "There is currently no information about services provided by this facility." ]
                      else
                        ul [] (List.map (\s -> li [] [ text s ]) facility.services)
                    ]
                ]
            ]


facilityContactDetails : List ( String, String ) -> Html Msg
facilityContactDetails attributes =
    let
        item ( iconName, information ) =
            li [] [ Shared.icon iconName, span [] [ text information ] ]
    in
        ul [] <|
            (List.map item attributes
                ++ [ li [ class "hide-on-large-only" ]
                        [ Shared.icon "location_on"
                        , a
                            [ href "#"
                            , Shared.onClick (Private ToggleMobileFocus)
                            ]
                            [ text "View on map" ]
                        ]
                   ]
            )


facilityActions : Html Msg
facilityActions =
    a
        [ Events.onClick (Private ToggleFacilityReport) ]
        [ Shared.icon "report"
        , text "Report an issue"
        ]
