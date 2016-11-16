module AppFacilityDetails exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Models exposing (Settings, MapViewport, Facility)
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Shared exposing (MapView, classNames)
import Api
import Date exposing (Date)
import Utils exposing (perform)
import Time
import String
import Task
import Map
import UserLocation
import Http
import Json.Decode as Decode
import Json.Encode exposing (..)
import I18n exposing (..)
import Return exposing (..)


type Model
    = Loading MapViewport Int (Maybe Date) UserLocation.Model
    | Loaded MapViewport Facility (Maybe Date) UserLocation.Model Bool (Maybe FacilityReport)


type PrivateMsg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date
    | UserLocationMsg UserLocation.Msg
    | ToggleMobileFocus
    | ToggleFacilityReport
    | ToggleCheckbox String
    | ReportMessageInput String
    | ReportFinalized
    | MapMsg Map.Msg


type Msg
    = Close
    | FacilityClicked Int
    | Private PrivateMsg
    | FacilityReportMsg FacilityReportResult
    | UnhandledError String


type alias FacilityReport =
    { wrong_location : Bool
    , closed : Bool
    , contact_info_missing : Bool
    , inaccurate_services : Bool
    , other : Bool
    , message : Maybe String
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
                    (Loaded (mapViewport model) facility (date model) (userLocation model) False Nothing)
                        ! [ let
                                fitContent =
                                    not (Models.contains (mapViewport model) facility.position)
                            in
                                Map.setHighlightedFacilityMarker facility fitContent
                          ]

                ApiFetch (Api.FetchFacilityFailed e) ->
                    Return.singleton model
                        |> perform (UnhandledError (toString e))

                UserLocationMsg msg ->
                    UserLocation.update s msg (userLocation model)
                        |> mapBoth (Private << UserLocationMsg) (setUserLocation model)

                ToggleMobileFocus ->
                    case model of
                        Loading _ _ _ _ ->
                            ( model, Cmd.none )

                        Loaded a b c d e f ->
                            ( Loaded a b c d (not e) f, Cmd.none )

                ToggleFacilityReport ->
                    if (isReportWindowOpen model) then
                        ( closeReportWindow model, Cmd.none )
                    else
                        ( openReportWindow model, Cmd.none )

                ReportFinalized ->
                    case model of
                        Loading _ _ _ _ ->
                            Utils.unreachable ()

                        Loaded _ _ _ _ _ Nothing ->
                            Utils.unreachable ()

                        Loaded _ facility _ _ _ (Just report) ->
                            if reportIsCompleted report then
                                ( closeReportWindow model, sendReport facility report )
                            else
                                ( model, Cmd.none )

                ToggleCheckbox name ->
                    case model of
                        Loading _ _ _ _ ->
                            Utils.unreachable ()

                        Loaded _ _ _ _ _ Nothing ->
                            Utils.unreachable ()

                        Loaded mapViewport facility date userLocation b (Just report) ->
                            let
                                updatedReport =
                                    toggleCheckbox name report

                                updatedModel =
                                    Loaded mapViewport facility date userLocation b (Just updatedReport)
                            in
                                ( updatedModel, Cmd.none )

                ReportMessageInput text ->
                    case model of
                        Loading _ _ _ _ ->
                            Utils.unreachable ()

                        Loaded _ _ _ _ _ Nothing ->
                            Utils.unreachable ()

                        Loaded mapViewport facility date userLocation b (Just report) ->
                            let
                                updatedReport =
                                    { report | message = text |> String.trim |> Utils.discardEmpty }

                                updatedModel =
                                    Loaded mapViewport facility date userLocation b (Just updatedReport)
                            in
                                ( updatedModel, Cmd.none )

                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( setMapViewport mapViewport model, Cmd.none )

                MapMsg _ ->
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
        { headerClass = classNames [ hideOnMobileDetailsFocused ]
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
        , modal = reportWindow model
        }


mobileFocusToggleView =
    a
        [ href "#"
        , Shared.onClick (Private ToggleMobileFocus)
        ]
        [ text "Show details" ]


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.view (userLocation model))


reportWindow : Model -> List (Html Msg)
reportWindow model =
    case model of
        Loading _ _ _ _ ->
            []

        Loaded _ _ _ _ _ Nothing ->
            []

        Loaded _ _ _ _ _ (Just report) ->
            let
                notEmpty =
                    if reportIsCompleted report then
                        " hide"
                    else
                        ""
            in
                if isReportWindowOpen model then
                    Shared.modalWindow
                        [ text <| t ReportAnIssue
                        , a [ href "#", class "right", Shared.onClick (Private ToggleFacilityReport) ] [ Shared.icon "close" ]
                        ]
                        [ Html.form [ action "#", method "GET" ]
                            [ checkbox "wrong_location" "Wrong location" report.wrong_location (Private (ToggleCheckbox "wrong_location"))
                            , checkbox "closed" "Facility closed" report.closed (Private (ToggleCheckbox "closed"))
                            , checkbox "contact_info_missing" "Incorrect contact information" report.contact_info_missing (Private (ToggleCheckbox "contact_info_missing"))
                            , checkbox "inaccurate_services" "Inaccurate service list" report.inaccurate_services (Private (ToggleCheckbox "inaccurate_services"))
                            , checkbox "other" "Other" report.other (Private (ToggleCheckbox "other"))
                            , div
                                [ class "input-field col s12", style [ ( "margin-top", "40px" ) ] ]
                                [ Html.textarea
                                    [ class "materialize-textarea"
                                    , placeholder "Detailed description (optional)"
                                    , style [ ( "height", "6rem" ) ]
                                    , Events.onInput (Private << ReportMessageInput)
                                    ]
                                    []
                                ]
                            ]
                        ]
                        [ div [ class ("warning" ++ notEmpty) ] [ text "Please select at least 1 issue to report" ]
                        , a [ href "#", class "btn-flat", Shared.onClick (Private ReportFinalized) ] [ text "Send report" ]
                        ]
                else
                    []


checkbox : String -> String -> Bool -> Msg -> Html Msg
checkbox htmlId label v msg =
    div [ class "input-field col s12" ]
        [ input [ type' "checkbox", id htmlId, checked v, Shared.onClick msg ] []
        , Html.label [ for htmlId ] [ text label ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map (Private << MapMsg) Map.subscriptions
        , Map.facilityMarkerClicked FacilityClicked
        ]


mapViewport : Model -> MapViewport
mapViewport model =
    case model of
        Loading mapViewport _ _ _ ->
            mapViewport

        Loaded mapViewport _ _ _ _ _ ->
            mapViewport


setMapViewport : MapViewport -> Model -> Model
setMapViewport mapViewport model =
    case model of
        Loading _ b c d ->
            Loading mapViewport b c d

        Loaded _ b c d e f ->
            Loaded mapViewport b c d e f


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


toggleCheckbox : String -> FacilityReport -> FacilityReport
toggleCheckbox name report =
    case name of
        "wrong_location" ->
            { report | wrong_location = not report.wrong_location }

        "closed" ->
            { report | closed = not report.closed }

        "contact_info_missing" ->
            { report | contact_info_missing = not report.contact_info_missing }

        "inaccurate_services" ->
            { report | inaccurate_services = not report.inaccurate_services }

        "other" ->
            { report | other = not report.other }

        _ ->
            Debug.crash "Not implemented"


openReportWindow : Model -> Model
openReportWindow model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d e _ ->
            Loaded a
                b
                c
                d
                e
                (Just
                    { wrong_location = False
                    , closed = False
                    , contact_info_missing = False
                    , inaccurate_services = False
                    , other = False
                    , message = Nothing
                    }
                )


closeReportWindow : Model -> Model
closeReportWindow model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d e _ ->
            Loaded a b c d e Nothing


isReportWindowOpen : Model -> Bool
isReportWindowOpen model =
    case model of
        Loading a b c d ->
            False

        Loaded a b c d e Nothing ->
            False

        Loaded a b c d e (Just _) ->
            True


reportIsCompleted : FacilityReport -> Bool
reportIsCompleted { wrong_location, closed, contact_info_missing, inaccurate_services, other, message } =
    List.any identity
        [ wrong_location
        , closed
        , contact_info_missing
        , inaccurate_services
        , other
        ]


userLocation : Model -> UserLocation.Model
userLocation model =
    case model of
        Loading _ _ _ userLocation ->
            userLocation

        Loaded _ _ _ userLocation _ _ ->
            userLocation


setUserLocation : Model -> UserLocation.Model -> Model
setUserLocation model userLocation =
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


type FacilityReportResult
    = ReportSuccess
    | ReportFailed


encodeReport : FacilityReport -> Json.Encode.Value
encodeReport report =
    Json.Encode.object
        [ ( "wrong_location", bool report.wrong_location )
        , ( "closed", bool report.closed )
        , ( "contact_info_missing", bool report.contact_info_missing )
        , ( "inaccurate_services", bool report.inaccurate_services )
        , ( "other", bool report.other )
        , ( "message"
          , (case report.message of
                Nothing ->
                    null

                Just text ->
                    string text
            )
          )
        ]


sendReport : Facility -> FacilityReport -> Cmd Msg
sendReport facility report =
    let
        url =
            "/facilities/" ++ toString facility.id ++ "/report"

        request =
            encodeReport report
                |> Json.Encode.encode 0
                |> Http.string
                |> Http.post (Decode.succeed ()) url
    in
        Task.perform (always (FacilityReportMsg ReportFailed)) (always (FacilityReportMsg ReportSuccess)) request


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

        contactInfo =
            [ contactEntry "local_post_office" "mailto:" facility.contactEmail
            , contactEntry "local_phone" "tel:" facility.contactPhone
              -- , contactEntry "public" ... facility.url
              -- , contactEntry "directions" ... facility.address
            ]
    in
        div [ classList <| ( "facilityDetail", True ) :: cssClasses ]
            [ div [ class "title" ]
                [ span [ class "name" ]
                    [ text facility.name
                    , span [ class "sub" ] [ text facility.facilityType ]
                    ]
                , i
                    [ class "material-icons right", Events.onClick Close ]
                    [ text "clear" ]
                ]
            , div [ class "content expand" ]
                [ div [ class "detailSection pic" ] [ div [ class "no-photo" ] [ Shared.icon "photo", text "No photo" ] ]
                , div [ class "detailSection actions" ] [ facilityActions ]
                , div [ class "detailSection contact" ] [ facilityContactDetails contactInfo ]
                , div [ class "detailSection services" ]
                    [ span [] [ text <| t Services ]
                    , if List.isEmpty facility.services then
                        div [ class "noData" ] [ text "There is currently no information about services provided by this facility." ]
                      else
                        ul [] (List.map (\s -> li [] [ text s ]) facility.services)
                    ]
                ]
            ]


contactEntry : String -> String -> Maybe String -> Html a
contactEntry iconName scheme value =
    let
        uriFriendly =
            if scheme == "tel:" then
                String.filter (\c -> c /= ' ' && c /= '-')
            else
                identity

        uri =
            Maybe.map (\v -> scheme ++ (uriFriendly v)) value

        label =
            span [] [ text <| Maybe.withDefault "Unavailable" value ]
    in
        case uri of
            Nothing ->
                li [] [ Shared.icon iconName, label ]

            Just uri ->
                li [] [ a [ href uri ] [ Shared.icon iconName, label ] ]


viewOnMapEntry : Html Msg
viewOnMapEntry =
    li [ class "hide-on-large-only" ]
        [ a
            [ href "#"
            , Shared.onClick (Private ToggleMobileFocus)
            ]
            [ Shared.icon "location_on", span [] [ text "View on map" ] ]
        ]


facilityContactDetails : List (Html Msg) -> Html Msg
facilityContactDetails contactInfo =
    ul [] (viewOnMapEntry :: contactInfo)


facilityActions : Html Msg
facilityActions =
    a
        [ href "#", Shared.onClick (Private ToggleFacilityReport) ]
        [ Shared.icon "report"
        , text <| t ReportAnIssue
        ]
