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
    | Loaded MapViewport Facility (Maybe Date) UserLocation.Model Bool


type PrivateMsg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date
    | UserLocationMsg UserLocation.Msg
    | ToggleMobileFocus


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
                    (Loaded (mapViewport model) facility (date model) (userLocation model) False)
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

                        Loaded a b c d e ->
                            ( Loaded a b c d (not e), Cmd.none )

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
        { headerAttributes = classList [ hideOnMobileDetailsFocused ]
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

                Loaded _ facility date _ mobileFocusMap ->
                    facilityDetail [ hideOnMobileMapFocused ] date facility
            ]
        , toolbar =
            [ userLocationView model ]
        , bottom =
            [ div
                [ classList [ hideOnMobileDetailsFocused ] ]
                [ mobileFocusToggleView ]
            ]
        }


mobileFocusToggleView =
    a
        [ href "#"
        , Shared.onClick (Private ToggleMobileFocus)
        ]
        [ text "Show details" ]


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.viewMapControl (userLocation model))


subscriptions : Model -> Sub Msg
subscriptions model =
    Map.facilityMarkerClicked FacilityClicked


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ _ _ ->
            mapViewport

        Loaded mapViewport _ _ _ _ ->
            mapViewport


date : Model -> Maybe Date
date model =
    case model of
        Loading _ _ date _ ->
            date

        Loaded _ _ date _ _ ->
            date


setDate : Date -> Model -> Model
setDate date model =
    case model of
        Loading a b _ d ->
            Loading a b (Just date) d

        Loaded a b _ d e ->
            Loaded a b (Just date) d e


userLocation : Model -> UserLocation.Model
userLocation model =
    case model of
        Loading _ _ _ userLocation ->
            userLocation

        Loaded _ _ _ userLocation _ ->
            userLocation


setUserLocation : UserLocation.Model -> Model -> Model
setUserLocation userLocation model =
    case model of
        Loading a b c _ ->
            Loading a b c userLocation

        Loaded a b c _ e ->
            Loaded a b c userLocation e


mobileFocusMap : Model -> Bool
mobileFocusMap model =
    case model of
        Loading _ _ _ _ ->
            True

        Loaded _ _ _ _ b ->
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
