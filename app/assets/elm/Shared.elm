module Shared exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import I18n exposing (..)
import Json.Decode
import Models
import String


type alias LHtml a =
    List (Html a)


classNames : List ( String, Bool ) -> List String
classNames list =
    list
        |> List.filter snd
        |> List.map fst


lmap : (a -> b) -> LHtml a -> LHtml b
lmap =
    List.map << Html.map


icon : String -> Html a
icon name =
    i [ class "material-icons" ] [ text name ]


onClick : msg -> Attribute msg
onClick message =
    Events.custom "click"
        {
            message = (Json.Decode.succeed message)
            , preventDefault = True
            , stopPropagation = True
        }


modalWindow : LHtml a -> LHtml a -> LHtml a -> LHtml a
modalWindow header body footer =
    [ div [ class "modal-content" ]
        [ div [ class "header" ] header
        , div [ class "body" ] body
        ]
    , div [ class "modal-footer" ] footer
    ]


targetSelectedIndex : Json.Decode.Decoder Int
targetSelectedIndex =
    Json.Decode.at [ "target", "selectedIndex" ] Json.Decode.int


onSelect : (Int -> msg) -> Html.Attribute msg
onSelect msg =
    Events.on "change" (Json.Decode.map msg targetSelectedIndex)
