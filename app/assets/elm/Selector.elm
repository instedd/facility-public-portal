module Selector exposing
    ( Model
    , Msg
    , close
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Menu
import String
import Task


type alias Model a =
    { inputId : String
    , options : List (Option a)
    , autoState : Menu.State
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
    , autoState = Menu.empty
    , howManyToShow = 8
    , query = ""
    , selection = selectedId |> Maybe.andThen (findById options)
    , showMenu = False
    }


type Msg
    = SetQuery String
    | SetAutoState Menu.Msg
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
    -- Sub.map SetAutoState Menu.subscription
    Sub.none


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of
        SetQuery newQuery ->
            let
                showMenu =
                    not << List.isEmpty <| matches newQuery model.options
            in
            ( { model | query = newQuery, showMenu = showMenu, selection = Nothing }, Cmd.none )

        SetAutoState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Menu.update updateConfig autoMsg model.howManyToShow model.autoState (currentMatches model)

                newModel =
                    { model | autoState = newState }
            in
            case maybeMsg of
                Nothing ->
                    ( newModel, Cmd.none )

                Just updateMsg ->
                    update updateMsg newModel

        OverlayClicked ->
            ( escape model, Cmd.none )

        HandleEscape ->
            ( escape model, Cmd.none )

        Wrap toTop ->
            case model.selection of
                Just _ ->
                    update Reset model

                Nothing ->
                    if toTop then
                        ( { model
                            | autoState = Menu.resetToLastItem updateConfig (currentMatches model) model.howManyToShow model.autoState
                            , selection = List.head <| List.reverse <| List.take model.howManyToShow <| currentMatches model
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | autoState = Menu.resetToFirstItem updateConfig (currentMatches model) model.howManyToShow model.autoState
                            , selection = List.head <| List.take model.howManyToShow <| currentMatches model
                          }
                        , Cmd.none
                        )

        Reset ->
            ( { model | autoState = Menu.reset updateConfig model.autoState, selection = Nothing }, Cmd.none )

        SelectKeyboard id ->
            let
                newModel =
                    setQuery model id
                        |> close
            in
            ( newModel, Cmd.none )

        SelectMouse id ->
            let
                newModel =
                    setQuery model id
                        |> close
            in
            ( newModel, Task.attempt (\_ -> NoOp) (Browser.Dom.focus model.inputId) )

        Preview id ->
            ( { model | selection = findById model.options id }, Cmd.none )

        OnFocus ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


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
        | autoState = Menu.empty
        , showMenu = False
    }


view : String -> OptionView a -> Model a -> Html Msg
view cssClass optionView model =
    let
        options =
            { preventDefault = True, stopPropagation = False, message = NoOp }

        dec =
            keyCode
                |> Json.andThen
                    (\code ->
                        if code == 38 || code == 40 then
                            Json.succeed options

                        else if code == 27 then
                            Json.succeed { options | message = HandleEscape }

                        else
                            Json.fail "not handling that key"
                    )

        menu =
            if model.showMenu then
                [ viewMenu cssClass optionView model ]

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
                    , Html.Events.custom "keydown" dec
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
        , style "backgroundColor" "rgba(0,0,0,0)"
        , style "position" "fixed"
        , style "width" "100%"
        , style "height" "100%"
        , style "top" "0"
        , style "left" "0"
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
    String.toInt


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


viewMenu : String -> OptionView a -> Model a -> Html Msg
viewMenu cssClass optionView model =
    let
        modelMatches =
            currentMatches model
    in
    div [ class ("autocomplete-menu " ++ cssClass ++ " child-count-" ++ (String.fromInt <| List.length modelMatches)) ]
        [ Html.map SetAutoState (Menu.view (viewConfig optionView) model.howManyToShow model.autoState modelMatches) ]


updateConfig : Menu.UpdateConfig Msg (Option a)
updateConfig =
    Menu.updateConfig
        { toId =
            .id >> String.fromInt
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    maybeId
                        |> Maybe.andThen parseId
                        |> Maybe.map Preview

                else if code == 13 then
                    maybeId
                        |> Maybe.andThen parseId
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


viewConfig : OptionView a -> Menu.ViewConfig (Option a)
viewConfig optionView =
    let
        customizedLi keySelected mouseSelected option =
            { attributes =
                [ classList [ ( "autocomplete-item", True ), ( "key-selected", keySelected || mouseSelected ) ]
                , id (String.fromInt option.id)
                ]
            , children = optionView option.item
            }
    in
    Menu.viewConfig
        { toId = .id >> String.fromInt
        , ul = [ class "autocomplete-list" ]
        , li = customizedLi
        }
