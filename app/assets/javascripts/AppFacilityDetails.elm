module AppFacilityDetails exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

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


type Model
    = Loading MapViewport Int (Maybe Date)
    | Loaded MapViewport Facility (Maybe Date)


type Msg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    , navigateBack : msg
    }


init : Host model msg -> MapViewport -> Int -> ( model, Cmd msg )
init h mapViewport facilityId =
    lift h <|
        Loading mapViewport facilityId Nothing
            ! [ Api.fetchFacility (h.msg << ApiFetch) facilityId, currentDate h ]


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    lift h <|
        case msg of
            CurrentDate date ->
                ( setDate date model, Cmd.none )

            ApiFetch (Api.FetchFacilitySuccess facility) ->
                ( Loaded (mapViewport model) facility (date model), Cmd.none )

            _ ->
                -- TODO handle error
                ( model, Cmd.none )


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            case model of
                Loading _ _ _ ->
                    Html.h3 [] [ text "Loading... " ]

                Loaded _ facility date ->
                    facilityDetail h date facility


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    Sub.none


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ _ ->
            mapViewport

        Loaded mapViewport _ _ ->
            mapViewport


date : Model -> Maybe Date
date model =
    case model of
        Loading _ _ date ->
            date

        Loaded _ _ date ->
            date


setDate : Date -> Model -> Model
setDate date model =
    case model of
        Loading a b _ ->
            Loading a b (Just date)

        Loaded a b _ ->
            Loaded a b (Just date)


lift : Host model msg -> ( Model, Cmd msg ) -> ( model, Cmd msg )
lift h ( m, c ) =
    ( h.model m, c )


currentDate : Host model msg -> Cmd msg
currentDate h =
    let
        notFailing x =
            notFailing x
    in
        Task.perform notFailing (Utils.dateFromEpochMillis >> CurrentDate >> h.msg) Time.now


facilityDetail : Host model msg -> Maybe Date -> Facility -> Html msg
facilityDetail h now facility =
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
                    [ class "material-icons right", Events.onClick h.navigateBack ]
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
