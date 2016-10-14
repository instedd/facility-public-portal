module Shared exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Json.Decode
import Models
import String


type alias LHtml a =
    List (Html a)


type alias MapView a =
    { headerAttributes : List (Attribute a)
    , content : LHtml a
    , toolbar : LHtml a
    , bottom : LHtml a
    , modal : LHtml a
    }


mapCanvas : Html a
mapCanvas =
    div [ id "map" ] []


layout : Html a -> Html a
layout content =
    div [ id "container" ] [ mapCanvas, content ]


controlStack : List (Html a) -> Html a
controlStack content =
    div [ id "map-control", class "z-depth-1" ] content


header : Html a
header =
    nav [ id "TopNav", class "z-depth-0" ]
        [ div [ class "nav-wrapper" ]
            [ a [ href "/" ]
                [ img [ id "logo", src "/logo.svg" ] [] ]
              --, a [ class "right" ] [ icon "menu" ]
            ]
        ]


searchBar : String -> a -> (String -> a) -> Html a -> Html a
searchBar userInput submitMsg inputMsg trailing =
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
                , trailing
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


checkbox : String -> String -> Bool -> a -> Html a
checkbox htmlId label v msg =
    p []
        [ input [ type' "checkbox", id htmlId, checked v, onClick msg ] []
        , Html.label [ for htmlId ] [ text label ]
        ]
