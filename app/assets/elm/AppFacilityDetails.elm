module AppFacilityDetails exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api
import Date exposing (Date)
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Http
import I18n exposing (..)
import Json.Decode as Decode
import Json.Encode exposing (..)
import Layout exposing (MapView)
import Map
import Models exposing (Settings, MapViewport, Facility)
import Return exposing (..)
import Shared exposing (classNames)
import String
import Task
import Time
import UserLocation
import Utils exposing (perform)


type Model
    = Loading MapViewport Int (Maybe Date) UserLocation.Model
    | Loaded MapViewport Facility (Maybe Date) UserLocation.Model Bool (Maybe FacilityReport)


type Msg
    = Close
    | FacilityClicked Int
    | Private PrivateMsg
    | UnhandledError String


type PrivateMsg
    = ApiFetch Api.FetchFacilityMsg
    | CurrentDate Date
    | UserLocationMsg UserLocation.Msg
    | ToggleMobileFocus
    | ToggleFacilityReport
    | Report ReportMsg
    | MapMsg Map.Msg


type ReportMsg
    = Toggle FacilityIssue
    | MessageInput String
    | Send
    | ReportResult FacilityReportResult


type FacilityIssue
    = WrongLocation
    | Closed
    | ContactMissing
    | InnacurateServices
    | Other


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

                Report (ReportResult result) ->
                    -- TODO
                    ( model, Cmd.none )

                Report msg ->
                    case model of
                        Loading _ _ _ _ ->
                            Utils.unreachable ()

                        Loaded _ _ _ _ _ Nothing ->
                            Utils.unreachable ()

                        Loaded mapViewport facility date userLocation b (Just report) ->
                            case msg of
                                Send ->
                                    if reportIsCompleted report then
                                        Return.singleton (closeReportWindow model)
                                            |> Return.command (sendReport facility report)
                                    else
                                        Return.singleton model

                                Toggle issue ->
                                    let
                                        updatedReport =
                                            toggleCheckbox issue report
                                    in
                                        Return.singleton
                                            (Loaded mapViewport facility date userLocation b (Just updatedReport))

                                MessageInput text ->
                                    let
                                        updatedReport =
                                            { report | message = text |> String.trim |> Utils.discardEmpty }
                                    in
                                        Return.singleton
                                            (Loaded mapViewport facility date userLocation b (Just updatedReport))

                                ReportResult result ->
                                    Utils.unreachable ()

                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( setMapViewport mapViewport model, Cmd.none )

                MapMsg _ ->
                    ( model, Cmd.none )

        _ ->
            -- public events
            ( model, Cmd.none )


view : Settings -> Model -> MapView Msg
view settings model =
    let
        onlyMobile =
            ( "hide-on-large-only", True )

        hideOnMobileMapFocused =
            ( "hide-on-med-and-down", mobileFocusMap model )

        hideOnMobileDetailsFocused =
            ( "hide-on-med-and-down", not (mobileFocusMap model) )
    in
        { headerClasses = classNames [ hideOnMobileDetailsFocused ]
        , content =
            [ case model of
                Loading _ _ _ _ ->
                    spinner

                Loaded _ facility date userLocation _ _ ->
                    facilityDetail settings [ hideOnMobileMapFocused ] date userLocation facility
            ]
        , expandedContent = Nothing
        , toolbar =
            [ userLocationView model ]
        , bottom =
            [ div
                [ classList [ hideOnMobileDetailsFocused ] ]
                [ mobileFocusToggleView ]
            ]
        , modal =
            case model of
                Loading _ _ _ _ ->
                    []

                Loaded _ _ _ _ _ Nothing ->
                    []

                Loaded _ _ _ _ _ (Just report) ->
                    reportWindow report
        }


spinner =
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


mobileFocusToggleView =
    a [ href "#", Shared.onClick (Private ToggleMobileFocus) ]
        [ text "Show details" ]


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.view (userLocation model))


reportWindow : FacilityReport -> List (Html Msg)
reportWindow report =
    let
        completed =
            reportIsCompleted report
    in
        Shared.modalWindow
            [ text <| t ReportAnIssue
            , a [ href "#", class "right", Shared.onClick (Private ToggleFacilityReport) ] [ Shared.icon "close" ]
            ]
            [ Html.form [ action "#", method "GET" ]
                [ issueToggle WrongLocation report.wrong_location
                , issueToggle Closed report.closed
                , issueToggle ContactMissing report.contact_info_missing
                , issueToggle InnacurateServices report.inaccurate_services
                , issueToggle Other report.other
                , div
                    [ class "input-field col s12", style [ ( "margin-top", "40px" ) ] ]
                    [ Html.textarea
                        [ class "materialize-textarea"
                        , placeholder <| t DetailedDescription
                        , style [ ( "height", "6rem" ) ]
                        , Events.onInput (Private << Report << MessageInput)
                        ]
                        []
                    ]
                ]
            ]
            [ div
                [ classList [ ( "warning", True ), ( "hide", completed ) ] ]
                [ text <| t SelectIssueToReport ]
            , a
                [ href "#"
                , classList [ ( "btn-flat", True ), ( "disabled", not completed ) ]
                , Shared.onClick (Private (Report Send))
                ]
                [ text <| t SendReport ]
            ]


issueToggle : FacilityIssue -> Bool -> Html Msg
issueToggle issue v =
    let
        msg =
            Private (Report (Toggle issue))

        htmlId =
            "issue-toggle-" ++ toString issue

        i18nLabel =
            t <|
                case issue of
                    WrongLocation ->
                        I18n.WrongLocation

                    Closed ->
                        I18n.Closed

                    ContactMissing ->
                        I18n.ContactMissing

                    InnacurateServices ->
                        I18n.InnacurateServices

                    Other ->
                        I18n.Other
    in
        div [ class "input-field col s12" ]
            [ input [ type' "checkbox", id htmlId, checked v, Shared.onClick msg ] []
            , Html.label [ for htmlId ] [ text i18nLabel ]
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


toggleCheckbox : FacilityIssue -> FacilityReport -> FacilityReport
toggleCheckbox issue report =
    case issue of
        WrongLocation ->
            { report | wrong_location = not report.wrong_location }

        Closed ->
            { report | closed = not report.closed }

        ContactMissing ->
            { report | contact_info_missing = not report.contact_info_missing }

        InnacurateServices ->
            { report | inaccurate_services = not report.inaccurate_services }

        Other ->
            { report | other = not report.other }


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
        Loading _ _ _ _ ->
            False

        Loaded _ _ _ _ _ Nothing ->
            False

        Loaded _ _ _ _ _ (Just _) ->
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

        resultTag result =
            Private (Report (ReportResult result))

        request =
            encodeReport report
                |> Json.Encode.encode 0
                |> Http.string
                |> Http.post (Decode.succeed ()) url
    in
        Task.perform (always (resultTag ReportFailed)) (always (resultTag ReportSuccess)) request


currentDate : Cmd Msg
currentDate =
    let
        notFailing x =
            notFailing x
    in
        Task.perform notFailing (Utils.dateFromEpochMillis >> CurrentDate >> Private) Time.now


facilityDetail : Settings -> List ( String, Bool ) -> Maybe Date -> UserLocation.Model -> Facility -> Html Msg
facilityDetail settings cssClasses now userLocation facility =
    let
        lastUpdatedSub =
            case facility.lastUpdated of
                Nothing ->
                    ""

                Just date ->
                    now
                        |> Maybe.map (\date -> String.concat [ "Last updated ", Utils.timeAgo date date, " ago" ])
                        |> Maybe.withDefault ""

        informationLinks =
            [ viewOnMapEntry
            , contactEntry "local_post_office" "mailto:" facility.contactEmail
            , contactEntry "local_phone" "tel:" facility.contactPhone
              -- , contactEntry "public" ... facility.url
            , directionsEntry userLocation facility
            , infoEntry "schedule" Nothing (Maybe.withDefault "Unavailable" facility.openingHours)
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
                [ div [ class ("detailSection pic" ++ (if settings.facilityPhotos then ""  else " pic-hide")) ]
                    [ if String.isEmpty (Maybe.withDefault "" facility.photo) then
                        div [ class "no-photo" ] [ Shared.icon "photo", text "No photo" ]
                      else
                        div [ class "photo" ] [ img [ src (Maybe.withDefault "" facility.photo) ] [] ]
                    ]
                , div [ class "detailSection actions" ] [ facilityActions ]
                , div [ class "detailSection contact" ] [ ul [] informationLinks ]
                , div [ class "detailSection info" ]
                    [ ul []
                        [ li [] [ text facility.ownership ]
                        , li [] [ text (String.join ", " (List.reverse facility.adm)) ]
                        ]
                    ]
                , div [ class "detailSection categories" ]
                    (List.concat
                        (List.map
                            (\cg ->
                                [ span [] [ text <| cg.name ]
                                , if List.isEmpty cg.categories then
                                    div [ class "noData" ] [ text "There is currently no information for this facility." ]
                                  else
                                    ul [] (List.map (\s -> li [] [ text s ]) cg.categories)
                                ]
                            )
                            facility.categoriesByGroup
                        )
                    )
                , div [ class "detailSection extra" ] [ text ("REF ID: " ++ facility.sourceId) ]
                ]
            ]


directionsEntry : UserLocation.Model -> Facility -> Html a
directionsEntry userLocation facility =
    let
        encodeLatLng ( lat, lng ) =
            String.join "," [ toString lat, toString lng ]

        encodedOrigin =
            UserLocation.toMaybe userLocation
                |> Maybe.map encodeLatLng
                |> Maybe.withDefault ""

        encodedDestination =
            encodeLatLng facility.position

        link =
            String.join "/"
                [ "https://maps.google.com/maps/dir"
                , encodedOrigin
                , encodedDestination
                ]
    in
        infoEntry "location_on" (Just link) (Maybe.withDefault "Get directions" facility.address)


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
        infoEntry iconName uri (Maybe.withDefault "Unavailable" value)


infoEntry : String -> Maybe String -> String -> Html a
infoEntry iconName uri labelText =
    let
        label =
            span [] [ text <| labelText ]
    in
        case uri of
            Nothing ->
                li [] [ Shared.icon iconName, label ]

            Just uri ->
                li [] [ a [ href uri, target "_blank" ] [ Shared.icon iconName, label ] ]


viewOnMapEntry : Html Msg
viewOnMapEntry =
    li [ class "hide-on-large-only" ]
        [ a
            [ href "#"
            , Shared.onClick (Private ToggleMobileFocus)
            ]
            [ Shared.icon "location_on", span [] [ text "View on map" ] ]
        ]


facilityActions : Html Msg
facilityActions =
    a
        [ href "#", Shared.onClick (Private ToggleFacilityReport) ]
        [ Shared.icon "report"
        , text <| t ReportAnIssue
        ]
