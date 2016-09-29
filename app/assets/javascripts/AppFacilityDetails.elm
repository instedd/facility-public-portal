module AppFacilityDetails exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Models exposing (MapViewport, Facility)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Shared
import Api
import Date exposing (Date)


type Model
    = Loading MapViewport Int
    | Loaded MapViewport Facility


type Msg
    = ApiFetch Api.FetchFacilityMsg


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    , navigateBack : msg
    }


init : Host model msg -> MapViewport -> Int -> ( model, Cmd msg )
init h mapViewport facilityId =
    lift h <|
        ( Loading mapViewport facilityId
        , Api.fetchFacility (h.msg << ApiFetch) facilityId
        )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    lift h <|
        case msg of
            ApiFetch (Api.FetchFacilitySuccess facility) ->
                ( Loaded (mapViewport model) facility, Cmd.none )

            _ ->
                -- TODO handle error
                ( model, Cmd.none )


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            case model of
                Loading _ _ ->
                    Html.h3 [] [ text "Loading... " ]

                Loaded _ facility ->
                    facilityDetail h Nothing facility


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    Sub.none


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ ->
            mapViewport

        Loaded mapViewport _ ->
            mapViewport


lift : Host model msg -> ( Model, Cmd msg ) -> ( model, Cmd msg )
lift h ( m, c ) =
    ( h.model m, c )


facilityDetail : Host model msg -> Maybe Date -> Facility -> Html msg
facilityDetail h now facility =
    let
        lastUpdatedSub =
            "XXX ago"

        --now
        --    |> Maybe.map (\date -> String.concat [ "Last updated ", timeAgo date facility.lastUpdated, " ago" ])
        --    |> Maybe.withDefault ""
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
