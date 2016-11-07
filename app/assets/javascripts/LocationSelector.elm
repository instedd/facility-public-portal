module LocationSelector
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        , subscriptions
        , close
        )

import Autocomplete
import Dom
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Models exposing (Location)
import String
import Task
import Utils exposing ((&>))


type alias Model =
    { locations : List Location
    , autoState : Autocomplete.State
    , howManyToShow : Int
    , query : String
    , selectedLocation : Maybe Location
    , showMenu : Bool
    }


init : List Location -> Maybe Int -> Model
init locations selectedId =
    { locations = List.sortBy .name locations
    , autoState = Autocomplete.empty
    , howManyToShow = 8
    , query = ""
    , selectedLocation = selectedId &> findById locations
    , showMenu = False
    }


type Msg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | Wrap Bool
    | Reset
    | OverlayClicked
    | HandleEscape
    | SelectLocationKeyboard Int
    | SelectLocationMouse Int
    | PreviewLocation Int
    | OnFocus
    | NoOp


subscriptions : Sub Msg
subscriptions =
    -- TODO: keyboard control is not supported yet :(
    -- Sub.map SetAutoState Autocomplete.subscription
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- case msg of
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

        OverlayClicked ->
            escape model ! []

        HandleEscape ->
            escape model ! []

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
                        |> close
            in
                newModel ! []

        SelectLocationMouse id ->
            let
                newModel =
                    setQuery model id
                        |> close
            in
                ( newModel, Task.perform (\err -> NoOp) (\_ -> NoOp) (Dom.focus "location-input") )

        PreviewLocation id ->
            { model | selectedLocation = Just <| findByIdWithDefault model.locations id } ! []

        OnFocus ->
            model ! []

        NoOp ->
            model ! []


resetInput model =
    { model | query = "" }
        |> removeSelection
        |> close


removeSelection model =
    { model | selectedLocation = Nothing }


findById locations id =
    List.filter (\location -> location.id == id) locations
        |> List.head


findByIdWithDefault locations id =
    findById locations id
        |> -- TODO: crash on default? We should probably use findById always
           Maybe.withDefault ({ id = 0, name = "", parentName = Nothing })


setQuery model id =
    { model
        | query = .name <| findByIdWithDefault model.locations id
        , selectedLocation = Just <| findByIdWithDefault model.locations id
    }


close model =
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
            [ overlay model
            , div
                [ class "autocomplete-wrapper" ]
                (List.append
                    [ input
                        [ onInput SetQuery
                        , onFocus OnFocus
                        , onWithOptions "keydown" options dec
                        , value query
                        , id "location-input"
                        , class "autocomplete-input"
                        , autocomplete False
                        , spellcheck False
                        , attribute "role" "combobox"
                        ]
                        []
                    ]
                    menu
                )
            ]


overlay : Model -> Html Msg
overlay model =
    div
        [ class "autocomplete-overlay"
        , onClick OverlayClicked
        , hidden (not model.showMenu)
        , style
            [ ( "backgroundColor", "rgba(0,0,0,0)" )
            , ( "position", "fixed" )
            , ( "width", "100%" )
            , ( "height", "100%" )
            , ( "top", "0" )
            , ( "left", "0" )
            ]
        ]
        []


acceptableLocations : String -> List Location -> List Location
acceptableLocations query locations =
    let
        lowerQuery =
            String.toLower query
    in
        List.filter (String.contains lowerQuery << String.toLower << .name) locations


parseId : String -> Maybe Int
parseId =
    String.toInt >> Result.toMaybe


escape model =
    let
        validOptions =
            not <| List.isEmpty (acceptableLocations model.query model.locations)

        clearModel =
            if validOptions then
                model
                    |> removeSelection
                    |> close
            else
                { model | query = "" }
                    |> removeSelection
                    |> close
    in
        case model.selectedLocation of
            Just location ->
                if model.query == location.name then
                    resetInput model
                else
                    clearModel

            Nothing ->
                clearModel


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
            , children =
                [ Html.text location.name
                , Html.span [ class "autocomplete-item-context" ] [ Html.text (Maybe.withDefault "" location.parentName) ]
                ]
            }
    in
        Autocomplete.viewConfig
            { toId = .id >> toString
            , ul = [ class "autocomplete-list" ]
            , li = customizedLi
            }
