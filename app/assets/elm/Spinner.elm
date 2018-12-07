module Spinner exposing (Color(..), spinner)

import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class)


type Color
    = Blue
    | Red
    | Yellow
    | Green
    | White


spinner : List (Attribute msg) -> Color -> Html msg
spinner attrs color =
    div (class "preloader-wrapper small active" :: attrs)
        [ div [ class ("spinner-layer " ++ colorClass color) ]
            [ div [ class "circle-clipper left" ]
                [ div [ class "circle" ] [] ]
            , div [ class "gap-patch" ]
                [ div [ class "circle" ] [] ]
            , div [ class "circle-clipper right" ]
                [ div [ class "circle" ] [] ]
            ]
        ]


colorClass : Color -> String
colorClass color =
    case color of
        Blue ->
            "spinner-blue-only"

        Red ->
            "spinner-red-only"

        Yellow ->
            "spinner-yellow-only"

        Green ->
            "spinner-green-only"

        White ->
            "spinner-white-only"
