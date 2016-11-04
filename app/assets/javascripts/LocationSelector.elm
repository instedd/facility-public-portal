module LocationSelector exposing (..)

import Autocomplete
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as Html
import String
import Json.Decode as Json
import Dom
import Task
import Models exposing (Location)
import Utils exposing ((&>))


subscriptions : Sub Msg
subscriptions =
    Sub.map SetAutoState Autocomplete.subscription


type alias Model =
    { locations : List Location
    , autoState : Autocomplete.State
    , howManyToShow : Int
    , query : String
    , selectedLocation : Maybe Location
    , showMenu : Bool
    }


init : List Location -> Model
init locations =
    { locations = locations
    , autoState = Autocomplete.empty
    , howManyToShow = 5
    , query = ""
    , selectedLocation = Nothing
    , showMenu = False
    }


type Msg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | Wrap Bool
    | Reset
    | HandleEscape
    | SelectLocationKeyboard Int
    | SelectLocationMouse Int
    | PreviewLocation Int
    | OnFocus
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetQuery newQuery ->
            let
                showMenu =
                    not << List.isEmpty <| (acceptableLocations newQuery model.locations)
            in
                { model | query = newQuery, showMenu = showMenu, selectedLocation = Nothing } ! []

        SetAutoState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Autocomplete.update updateConfig autoMsg model.howManyToShow model.autoState (acceptableLocations model.query model.locations)

                newModel =
                    { model | autoState = newState }
            in
                case maybeMsg of
                    Nothing ->
                        newModel ! []

                    Just updateMsg ->
                        update updateMsg newModel

        HandleEscape ->
            let
                validOptions =
                    not <| List.isEmpty (acceptableLocations model.query model.locations)

                handleEscape =
                    if validOptions then
                        model
                            |> removeSelection
                            |> resetMenu
                    else
                        { model | query = "" }
                            |> removeSelection
                            |> resetMenu

                escapedModel =
                    case model.selectedLocation of
                        Just location ->
                            if model.query == location.name then
                                model
                                    |> resetInput
                            else
                                handleEscape

                        Nothing ->
                            handleEscape
            in
                escapedModel ! []

        Wrap toTop ->
            case model.selectedLocation of
                Just location ->
                    update Reset model

                Nothing ->
                    if toTop then
                        { model
                            | autoState = Autocomplete.resetToLastItem updateConfig (acceptableLocations model.query model.locations) model.howManyToShow model.autoState
                            , selectedLocation = List.head <| List.reverse <| List.take model.howManyToShow <| (acceptableLocations model.query model.locations)
                        }
                            ! []
                    else
                        { model
                            | autoState = Autocomplete.resetToFirstItem updateConfig (acceptableLocations model.query model.locations) model.howManyToShow model.autoState
                            , selectedLocation = List.head <| List.take model.howManyToShow <| (acceptableLocations model.query model.locations)
                        }
                            ! []

        Reset ->
            { model | autoState = Autocomplete.reset updateConfig model.autoState, selectedLocation = Nothing } ! []

        SelectLocationKeyboard id ->
            let
                newModel =
                    setQuery model id
                        |> resetMenu
            in
                newModel ! []

        SelectLocationMouse id ->
            let
                newModel =
                    setQuery model id
                        |> resetMenu
            in
                ( newModel, Task.perform (\err -> NoOp) (\_ -> NoOp) (Dom.focus "location-input") )

        PreviewLocation id ->
            { model | selectedLocation = Just <| getLocationAtId model.locations id } ! []

        OnFocus ->
            model ! []

        NoOp ->
            model ! []


resetInput model =
    { model | query = "" }
        |> removeSelection
        |> resetMenu


removeSelection model =
    { model | selectedLocation = Nothing }


getLocationAtId locations id =
    List.filter (\location -> location.id == id) locations
        |> List.head
        |> -- TODO: crash on default?
           Maybe.withDefault ({ id = 0, name = "", parentName = Nothing })


setQuery model id =
    { model
        | query = .name <| getLocationAtId model.locations id
        , selectedLocation = Just <| getLocationAtId model.locations id
    }


resetMenu model =
    { model
        | autoState = Autocomplete.empty
        , showMenu = False
    }


view : Model -> Html Msg
view model =
    let
        options =
            { preventDefault = True, stopPropagation = False }

        dec =
            (Json.customDecoder keyCode
                (\code ->
                    if code == 38 || code == 40 then
                        Ok NoOp
                    else if code == 27 then
                        Ok HandleEscape
                    else
                        Err "not handling that key"
                )
            )

        menu =
            if model.showMenu then
                [ viewMenu model ]
            else
                []

        query =
            case model.selectedLocation of
                Just location ->
                    location.name

                Nothing ->
                    model.query
    in
        div []
            (List.append
                [ input
                    [ onInput SetQuery
                    , onFocus OnFocus
                    , onWithOptions "keydown" options dec
                    , value query
                    , id "location-input"
                    , class "autocomplete-input"
                    , autocomplete False
                    , attribute "role" "combobox"
                    ]
                    []
                ]
                menu
            )


acceptableLocations : String -> List Location -> List Location
acceptableLocations query locations =
    let
        lowerQuery =
            String.toLower query
    in
        List.filter (String.contains lowerQuery << String.toLower << .name) locations


viewMenu : Model -> Html Msg
viewMenu model =
    div [ class "autocomplete-menu" ]
        [ Html.map SetAutoState (Autocomplete.view viewConfig model.howManyToShow model.autoState (acceptableLocations model.query model.locations)) ]


updateConfig : Autocomplete.UpdateConfig Msg Location
updateConfig =
    Autocomplete.updateConfig
        { toId =
            .id >> toString
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    maybeId
                        &> parseId
                        |> Maybe.map PreviewLocation
                else if code == 13 then
                    maybeId
                        &> parseId
                        |> Maybe.map SelectLocationKeyboard
                else
                    Just <| Reset
        , onTooLow =
            Just <| Wrap False
        , onTooHigh =
            Just <| Wrap True
        , onMouseEnter =
            parseId >> Maybe.map PreviewLocation
        , onMouseLeave =
            \_ -> Nothing
        , onMouseClick =
            parseId >> Maybe.map SelectLocationMouse
        , separateSelections = False
        }


viewConfig : Autocomplete.ViewConfig Location
viewConfig =
    let
        customizedLi keySelected mouseSelected location =
            { attributes =
                [ classList [ ( "autocomplete-item", True ), ( "key-selected", keySelected || mouseSelected ) ]
                , id (toString location.id)
                ]
            , children = [ Html.text location.name ]
            }
    in
        Autocomplete.viewConfig
            { toId = .id >> toString
            , ul = [ class "autocomplete-list" ]
            , li = customizedLi
            }



-- LOCATIONS


parseId : String -> Maybe Int
parseId =
    String.toInt >> Result.toMaybe
