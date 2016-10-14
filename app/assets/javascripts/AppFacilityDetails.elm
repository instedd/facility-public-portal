module AppFacilityDetails exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Models exposing (Settings, MapViewport, Facility)
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Shared
import Api
import Date exposing (Date)
import Utils exposing (mapTCmd)
import Time
import String
import Task
import Map
import UserLocation
import Http
import Json.Decode as Decode
import Json.Encode exposing (..)


type Model
    = Loading MapViewport Int (Maybe Date) UserLocation.Model
    | Loaded MapViewport Facility (Maybe Date) UserLocation.Model (Maybe FacilityReport)


type PrivateMsg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date
    | UserLocationMsg UserLocation.Msg
    | ToggleFacilityReport
    | ToggleCheckbox String
    | ReportFinalized


type Msg
    = Close
    | FacilityClicked Int
    | Private PrivateMsg
    | FacilityReportMsg FacilityReportResult

type alias FacilityReport =
    { wrong_location : Bool
    , closed : Bool
    , contact_info_missing : Bool
    , inaccurate_services : Bool
    , other : Bool
    }


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
                    (Loaded (mapViewport model) facility (date model) (userLocation model) Nothing)
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

                ToggleFacilityReport ->
                    if (isReportWindowOpen model) then
                        ( closeReportWindow model, Cmd.none )
                    else
                        ( openReportWindow model, Cmd.none )

                ReportFinalized ->
                    ( closeReportWindow model, sendReport model )

                ToggleCheckbox name ->
                    ( toggleCheckbox name model, Cmd.none )

                _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

        _ ->
            -- public events
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        ([ Shared.controlStack
            [ div [ class "hide-on-med-and-down" ] [ Shared.header ]
            , case model of
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

                Loaded _ facility date _ _ ->
                    facilityDetail date facility
            ]
        , userLocationView model
        ] ++ (reportWindow model))


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.viewMapControl (userLocation model))


reportWindow : Model -> List(Html Msg)
reportWindow model =
    if isReportWindowOpen model then
        [ div [ id "modal", class "modal open" ]
            [ div [ class "modal-content"]
                [ div [ class "header" ]
                    [ text "Report an issue"
                    , a [ class "right", Events.onClick (Private ToggleFacilityReport) ] [ Shared.icon "close" ] ]
                , div [ class "body" ]
                    [ Html.form [ action "#", method "GET" ]
                        [ Shared.checkbox "wrong_location" "Wrong location" (facilityReport model).wrong_location (Private (ToggleCheckbox "wrong_location"))
                        , Shared.checkbox "closed" "Facility closed" (facilityReport model).closed (Private (ToggleCheckbox "closed"))
                        , Shared.checkbox "contact_info_missing" "Incomplete contact information" (facilityReport model).contact_info_missing (Private (ToggleCheckbox "contact_info_missing"))
                        , Shared.checkbox "inaccurate_services" "Inaccurate service list" (facilityReport model).inaccurate_services (Private (ToggleCheckbox "inaccurate_services"))
                        , Shared.checkbox "other" "Other" (facilityReport model).other (Private (ToggleCheckbox "other"))
                        ]
                    ]
                ]
            , div [ class "modal-footer" ]
                [ a [ class "btn-flat", Events.onClick (Private ReportFinalized) ] [ text "Send report" ] ]
            ]
        ]
        else
            [ div [class "problem"] [] ]


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
        Loading a b _ d->
            Loading a b (Just date) d

        Loaded a b _ d e ->
            Loaded a b (Just date) d e


toggleCheckbox : String -> Model -> Model
toggleCheckbox name model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d Nothing ->
            Loaded a b c d Nothing

        Loaded a b c d (Just e) ->
            case name of
                "wrong_location" ->
                    Loaded a b c d (Just { e | wrong_location = not e.wrong_location})
                "closed" ->
                    Loaded a b c d (Just { e | closed = not e.closed})
                "contact_info_missing" ->
                    Loaded a b c d (Just { e | contact_info_missing = not e.contact_info_missing})
                "inaccurate_services" ->
                    Loaded a b c d (Just { e | inaccurate_services = not e.inaccurate_services})
                "other" ->
                    Loaded a b c d (Just { e | other = not e.other})
                _ ->
                    Debug.crash "Not implemented"


facilityReport : Model -> FacilityReport
facilityReport model =
    case model of
        Loading _ _ _ _ ->
            Debug.crash "Facility report getter should not be called without one"

        Loaded _ _ _ _ Nothing ->
            Debug.crash "Facility report getter should not be called without one"

        Loaded _ _ _ _ (Just b) ->
            b


openReportWindow : Model -> Model
openReportWindow model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d _ ->
            Loaded a b c d (Just { wrong_location = False
                , closed = False
                , contact_info_missing = False
                , inaccurate_services = False
                , other = False
                })


closeReportWindow : Model -> Model
closeReportWindow model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d _ ->
            Loaded a b c d Nothing


isReportWindowOpen : Model -> Bool
isReportWindowOpen model =
    case model of
        Loading a b c d ->
            False

        Loaded a b c d Nothing ->
            False

        Loaded a b c d (Just _) ->
            True

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


type FacilityReportResult
    = ReportSuccess
    | ReportFailed


encodeReport : FacilityReport -> Json.Encode.Value
encodeReport report =
    Json.Encode.object [
        ( "wrong_location", bool report.wrong_location )
        , ( "closed", bool report.closed )
        , ( "contact_info_missing", bool report.contact_info_missing )
        , ( "inaccurate_services", bool report.inaccurate_services )
        , ( "other", bool report.other )
    ]


sendReport : Model -> Cmd Msg
sendReport model =
    let
        url =
            case model of
                Loading _ id _ _ ->
                    "/facilities/" ++ (toString id) ++ "/report"

                Loaded _ facility _ _ _ ->
                    "/facilities/" ++ (toString facility.id) ++ "/report"
    in
        Task.perform (always (FacilityReportMsg ReportFailed)) (always (FacilityReportMsg ReportSuccess)) (Http.post (Decode.succeed ()) url (Http.string (Json.Encode.encode 0 (encodeReport (facilityReport model)))))


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
        div []
            [ div [ class "facilityDetail" ]
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

facilityActions : Html Msg
facilityActions =
    a
        [ Events.onClick (Private ToggleFacilityReport) ]
        [ Shared.icon "report"
        , text "Report an issue"
        ]
