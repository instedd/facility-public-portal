module AppFacilityDetails exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Models exposing (MapViewport, Facility)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Shared
import Api
import Date exposing (Date)
import Utils
import Time
import String
import Task
import Map
import UserLocation


type Model
    = Loading MapViewport Int (Maybe Date) UserLocation.Model
    | Loaded MapViewport Facility (Maybe Date) UserLocation.Model


type PrivateMsg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date


type Msg
    = Close
    | Private PrivateMsg


init : MapViewport -> UserLocation.Model -> Int -> ( Model, Cmd Msg )
init mapViewport userLocation facilityId =
    Loading mapViewport facilityId Nothing userLocation
        ! [ -- TODO should make them grey instead of removing
            Map.clearFacilityMarkers
          , Api.fetchFacility (Private << ApiFetch) facilityId
          , currentDate
          ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Private msg ->
            case msg of
                CurrentDate date ->
                    ( setDate date model, Cmd.none )

                ApiFetch (Api.FetchFacilitySuccess facility) ->
                    ( Loaded (mapViewport model) facility (date model) (userLocation model), Map.addFacilityMarker facility )

                _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

        _ ->
            -- public events
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Shared.headerWithContent
        [ case model of
            Loading _ _ _ _ ->
                Html.h3 [] [ text "Loading... " ]

            Loaded _ facility date _ ->
                facilityDetail date facility
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ _ _ ->
            mapViewport

        Loaded mapViewport _ _ _ ->
            mapViewport


date : Model -> Maybe Date
date model =
    case model of
        Loading _ _ date _ ->
            date

        Loaded _ _ date _ ->
            date


setDate : Date -> Model -> Model
setDate date model =
    case model of
        Loading a b _ d ->
            Loading a b (Just date) d

        Loaded a b _ d ->
            Loaded a b (Just date) d


userLocation : Model -> UserLocation.Model
userLocation model =
    case model of
        Loading _ _ _ userLocation ->
            userLocation

        Loaded _ _ _ userLocation ->
            userLocation


currentDate : Cmd Msg
currentDate =
    let
        notFailing x =
            notFailing x
    in
        Task.perform notFailing (Utils.dateFromEpochMillis >> CurrentDate >> Private) Time.now


facilityDetail : Maybe Date -> Facility -> Html Msg
facilityDetail now facility =
    let
        lastUpdatedSub =
            now
                |> Maybe.map (\date -> String.concat [ "Last updated ", Utils.timeAgo date facility.lastUpdated, " ago" ])
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
        div [ class "facilityDetail" ]
            [ div [ class "title" ]
                [ span [ class "name" ]
                    [ text facility.name
                    , span [ class "sub" ] [ text lastUpdatedSub ]
                    ]
                , i
                    [ class "material-icons right", Events.onClick Close ]
                    [ text "clear" ]
                ]
            , div [ class "detailSection pic" ] [ img [ src "/facility.png" ] [] ]
            , div [ class "detailSection contact" ] [ facilityContactDetails contactInfo ]
            , div [ class "detailSection services" ]
                [ span [] [ text "Services" ]
                , if List.isEmpty facility.services then
                    div [ class "noData" ] [ text "There is currently no information about services provided by this facility." ]
                  else
                    ul [] (List.map (\s -> li [] [ text s ]) facility.services)
                ]
            ]


facilityContactDetails : List ( String, String ) -> Html msg
facilityContactDetails attributes =
    let
        item ( iconName, information ) =
            li [] [ Shared.icon iconName, span [] [ text information ] ]
    in
        attributes
            |> List.map item
            |> ul []
