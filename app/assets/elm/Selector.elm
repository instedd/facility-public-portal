module Selector
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
import String
import Task
import Utils exposing ((&>))


type alias Model a =
    { inputId : String
    , options : List (Option a)
    , autoState : Autocomplete.State
    , howManyToShow : Int
    , query : String
    , selection : Maybe (Option a)
    , showMenu : Bool
    }


type alias Option a =
    { id : Int, label : String, item : a }


type alias OptionView a =
    a -> List (Html Never)


init : String -> List a -> (a -> Int) -> (a -> String) -> Maybe Int -> Model a
init id items fId fLabel selectedId =
    let
        options =
            items
                |> List.map (\a -> { id = fId a, label = fLabel a, item = a })
                |> List.sortBy .label
    in
        { inputId = id
        , options = options
        , autoState = Autocomplete.empty
        , howManyToShow = 8
        , query = ""
        , selection = selectedId &> findById options
        , showMenu = False
        }


type Msg
    = SetQuery String
    | SetAutoState Autocomplete.Msg
    | Wrap Bool
    | Reset
    | OverlayClicked
    | HandleEscape
    | SelectKeyboard Int
    | SelectMouse Int
    | Preview Int
    | OnFocus
    | NoOp


subscriptions : Sub Msg
subscriptions =
    -- TODO: keyboard control is not supported yet :(
    -- Sub.map SetAutoState Autocomplete.subscription
    Sub.none


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of
        SetQuery newQuery ->
            let
                showMenu =
                    not << List.isEmpty <| (matches newQuery model.options)
            in
                { model | query = newQuery, showMenu = showMenu, selection = Nothing } ! []

        SetAutoState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Autocomplete.update updateConfig autoMsg model.howManyToShow model.autoState (currentMatches model)

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
            case model.selection of
                Just _ ->
                    update Reset model

                Nothing ->
                    if toTop then
                        { model
                            | autoState = Autocomplete.resetToLastItem updateConfig (currentMatches model) model.howManyToShow model.autoState
                            , selection = List.head <| List.reverse <| List.take model.howManyToShow <| (currentMatches model)
                        }
                            ! []
                    else
                        { model
                            | autoState = Autocomplete.resetToFirstItem updateConfig (currentMatches model) model.howManyToShow model.autoState
                            , selection = List.head <| List.take model.howManyToShow <| (currentMatches model)
                        }
                            ! []

        Reset ->
            { model | autoState = Autocomplete.reset updateConfig model.autoState, selection = Nothing } ! []

        SelectKeyboard id ->
            let
                newModel =
                    setQuery model id
                        |> close
            in
                newModel ! []

        SelectMouse id ->
            let
                newModel =
                    setQuery model id
                        |> close
            in
                ( newModel, Task.perform (\err -> NoOp) (\_ -> NoOp) (Dom.focus model.inputId) )

        Preview id ->
            { model | selection = findById model.options id } ! []

        OnFocus ->
            model ! []

        NoOp ->
            model ! []


resetInput model =
    { model | query = "" }
        |> removeSelection
        |> close


removeSelection model =
    { model | selection = Nothing }


findById options id =
    List.filter (\option -> option.id == id) options
        |> List.head


setQuery model id =
    { model
        | query = findById model.options id |> Maybe.map .label |> Maybe.withDefault ""
        , selection = findById model.options id
    }


close model =
    { model
        | autoState = Autocomplete.empty
        , showMenu = False
    }


view : OptionView a -> Model a -> Html Msg
view optionView model =
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
                [ viewMenu optionView model ]
            else
                []

        query =
            case model.selection of
                Just option ->
                    option.label

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
                        , id model.inputId
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


overlay : Model a -> Html Msg
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


currentMatches : Model a -> List (Option a)
currentMatches model =
    matches model.query model.options


matches : String -> List (Option a) -> List (Option a)
matches query options =
    let
        lowerQuery =
            String.toLower query
    in
        List.filter (String.contains lowerQuery << String.toLower << .label) options


parseId : String -> Maybe Int
parseId =
    String.toInt >> Result.toMaybe


escape model =
    let
        validOptions =
            not <| List.isEmpty (currentMatches model)

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
        case model.selection of
            Just option ->
                if model.query == option.label then
                    resetInput model
                else
                    clearModel

            Nothing ->
                clearModel


viewMenu : OptionView a -> Model a -> Html Msg
viewMenu optionView model =
    div [ class "autocomplete-menu" ]
        [ Html.map SetAutoState (Autocomplete.view (viewConfig optionView) model.howManyToShow model.autoState (currentMatches model)) ]


updateConfig : Autocomplete.UpdateConfig Msg (Option a)
updateConfig =
    Autocomplete.updateConfig
        { toId =
            .id >> toString
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    maybeId
                        &> parseId
                        |> Maybe.map Preview
                else if code == 13 then
                    maybeId
                        &> parseId
                        |> Maybe.map SelectKeyboard
                else
                    Just <| Reset
        , onTooLow =
            Just <| Wrap False
        , onTooHigh =
            Just <| Wrap True
        , onMouseEnter =
            parseId >> Maybe.map Preview
        , onMouseLeave =
            \_ -> Nothing
        , onMouseClick =
            parseId >> Maybe.map SelectMouse
        , separateSelections = False
        }


viewConfig : OptionView a -> Autocomplete.ViewConfig (Option a)
viewConfig optionView =
    let
        customizedLi keySelected mouseSelected option =
            { attributes =
                [ classList [ ( "autocomplete-item", True ), ( "key-selected", keySelected || mouseSelected ) ]
                , id (toString option.id)
                ]
            , children = optionView option.item
            }
    in
        Autocomplete.viewConfig
            { toId = .id >> toString
            , ul = [ class "autocomplete-list" ]
            , li = customizedLi
            }
