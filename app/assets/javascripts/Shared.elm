module Shared exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Json.Decode
import Models
import String


mapWithControl : Maybe (Html a) -> Html a
mapWithControl content =
    layout (mapControl content)


mapCanvas : Html a
mapCanvas =
    div [ id "map" ] []


layout : Html a -> Html a
layout content =
    div [ id "container" ] [ mapCanvas, content ]


headerWithContent : List (Html a) -> Html a
headerWithContent content =
    div [ id "map-control", class "z-depth-1" ] (header :: content)


controlStack : List (Html a) -> Html a
controlStack content =
    div [ id "map-control", class "z-depth-1" ] content


mapControl : Maybe (Html a) -> Html a
mapControl content =
    headerWithContent
        (case content of
            Nothing ->
                []

            Just content ->
                [ content ]
        )


header : Html a
header =
    nav [ id "TopNav", class "z-depth-0" ]
        [ div [ class "nav-wrapper" ]
            [ a [ href "/" ]
                [ img [ id "logo", src "/logo.svg" ] [] ]
              --, a [ class "right" ] [ icon "menu" ]
            ]
        ]


searchBar : String -> a -> (String -> a) -> Html a
searchBar userInput submitMsg inputMsg =
    div [ class "search-box" ]
        [ div [ class "search" ]
            [ Html.form [ action "#", method "GET", autocomplete False, Events.onSubmit submitMsg ]
                [ input
                    [ type' "search"
                    , placeholder "Search health facilities"
                    , value userInput
                    , Events.onInput inputMsg
                    ]
                    []
                , icon "search"
                ]
            ]
        ]


icon : String -> Html a
icon name =
    i [ class "material-icons" ] [ text name ]


onClick : msg -> Attribute msg
onClick message =
    Events.onWithOptions "click"
        { preventDefault = True
        , stopPropagation = True
        }
        (Json.Decode.succeed message)
