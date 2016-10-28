port module KeyboardControl exposing (subscriptions, handleKey, ControlKey)

import Array
import Models exposing (..)
import Utils exposing (..)
import NavegableList exposing (..)


type ControlKey
    = Up
    | Down
    | Enter
    | NoOp


port controlKeys : (Int -> msg) -> Sub msg


subscriptions : Sub ControlKey
subscriptions =
    controlKeys interpretKey


handleKey : msg -> (a -> msg) -> ControlKey -> NavegableList a -> ( NavegableList a, Cmd msg )
handleKey submitMsg enterMsg code list =
    case code of
        Up ->
            ( focusNext list, Cmd.none )

        Down ->
            ( focusPrevious list, Cmd.none )

        Enter ->
            case focusedElement list of
                Nothing ->
                    ( list, Utils.performMessage submitMsg )

                Just x ->
                    ( list, Utils.performMessage (enterMsg x) )

        NoOp ->
            ( list, Cmd.none )



-- PRIVATE


interpretKey : Int -> ControlKey
interpretKey code =
    if code == 38 then
        Down
    else if code == 40 then
        Up
    else if code == 13 then
        Enter
    else
        NoOp
