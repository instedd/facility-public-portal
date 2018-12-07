module Spinner exposing (spinner)

import Html exposing (Attribute, Html, div)
import Html.Attributes exposing (class)


spinner : List (Attribute msg) -> Html msg
spinner attrs =
    div (class "preloader-wrapper small active" :: attrs)
        [ div [ class "spinner-layer spinner-blue-only" ]
            [ div [ class "circle-clipper left" ]
                [ div [ class "circle" ] [] ]
            , div [ class "gap-patch" ]
                [ div [ class "circle" ] [] ]
            , div [ class "circle-clipper right" ]
                [ div [ class "circle" ] [] ]
            ]
        ]
