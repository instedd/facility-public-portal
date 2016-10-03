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
            [ a []
                [ img [ id "logo", src "/logo.svg" ] [] ]
            , a [ class "right" ]
                [ icon "menu" ]
            ]
        ]


searchBar : String -> List (Html a) -> a -> (String -> a) -> Html a
searchBar userInput trailing submitMsg inputMsg =
    div [ class "search-box" ]
        ([ div [ class "search" ]
            [ Html.form [ Events.onSubmit submitMsg ]
                [ input
                    [ type' "text"
                    , placeholder "Search health facilities"
                    , value userInput
                    , Events.onInput inputMsg
                    ]
                    []
                , icon "search"
                ]
            ]
         ]
            `List.append` trailing
        )


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
