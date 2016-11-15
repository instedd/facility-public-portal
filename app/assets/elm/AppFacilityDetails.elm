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
    | ReportFinalized


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
    , other :
        Bool
        --, comments : Maybe String
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
                    if reportIsCompleted model then
                        ( closeReportWindow model, sendReport model )
                    else
                        ( model, Cmd.none )

                ToggleCheckbox name ->
                    ( toggleCheckbox name model, Cmd.none )

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
    let
        notEmpty =
            if reportIsCompleted model then
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
                    [ Shared.checkbox "wrong_location" "Wrong location" (facilityReport model).wrong_location (Private (ToggleCheckbox "wrong_location"))
                    , Shared.checkbox "closed" "Facility closed" (facilityReport model).closed (Private (ToggleCheckbox "closed"))
                    , Shared.checkbox "contact_info_missing" "Incorrect contact information" (facilityReport model).contact_info_missing (Private (ToggleCheckbox "contact_info_missing"))
                    , Shared.checkbox "inaccurate_services" "Inaccurate service list" (facilityReport model).inaccurate_services (Private (ToggleCheckbox "inaccurate_services"))
                    , Shared.checkbox "other" "Other" (facilityReport model).other (Private (ToggleCheckbox "other"))
                    ]
                ]
                [ div [ class ("warning" ++ notEmpty) ] [ text "Please select at least 1 issue to report" ]
                , a [ href "#", class "btn-flat", Shared.onClick (Private ReportFinalized) ] [ text "Send report" ]
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


toggleCheckbox : String -> Model -> Model
toggleCheckbox name model =
    case model of
        Loading a b c d ->
            Loading a b c d

        Loaded a b c d e Nothing ->
            Loaded a b c d e Nothing

        Loaded a b c d e (Just f) ->
            case name of
                "wrong_location" ->
                    Loaded a b c d e (Just { f | wrong_location = not f.wrong_location })

                "closed" ->
                    Loaded a b c d e (Just { f | closed = not f.closed })

                "contact_info_missing" ->
                    Loaded a b c d e (Just { f | contact_info_missing = not f.contact_info_missing })

                "inaccurate_services" ->
                    Loaded a b c d e (Just { f | inaccurate_services = not f.inaccurate_services })

                "other" ->
                    Loaded a b c d e (Just { f | other = not f.other })

                _ ->
                    Debug.crash "Not implemented"


facilityReport : Model -> FacilityReport
facilityReport model =
    case model of
        Loading _ _ _ _ ->
            Debug.crash "Facility report getter should not be called without one"

        Loaded _ _ _ _ _ Nothing ->
            Debug.crash "Facility report getter should not be called without one"

        Loaded _ _ _ _ _ (Just b) ->
            b


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


reportIsCompleted : Model -> Bool
reportIsCompleted model =
    case model of
        Loading a b c d ->
            False

        Loaded a b c d e Nothing ->
            False

        Loaded a b c d e (Just { wrong_location, closed, contact_info_missing, inaccurate_services, other }) ->
            List.any identity [ wrong_location, closed, contact_info_missing, inaccurate_services, other ]


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
        ]


sendReport : Model -> Cmd Msg
sendReport model =
    let
        url =
            case model of
                Loading _ id _ _ ->
                    "/facilities/" ++ (toString id) ++ "/report"

                Loaded _ facility _ _ _ _ ->
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
