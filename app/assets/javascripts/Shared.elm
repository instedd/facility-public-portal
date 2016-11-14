module Shared exposing (..)

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Json.Decode
import Models
import String
import I18n exposing (..)


type alias LHtml a =
    List (Html a)


type alias MapView a =
    { headerClass : String
    , content : LHtml a
    , toolbar : LHtml a
    , bottom : LHtml a
    , modal : LHtml a
    }


classNames : List ( String, Bool ) -> String
classNames list =
    list
        |> List.filter snd
        |> List.map fst
        |> String.join " "


lmap : (a -> b) -> LHtml a -> LHtml b
lmap =
    List.map << Html.App.map


mapCanvas : Html a
mapCanvas =
    div [ id "map" ] []


layout : Html a -> Html a
layout content =
    div [ id "container" ] [ mapCanvas, content ]


controlStack : List (Html a) -> Html a
controlStack content =
    div [ id "map-control", class "z-depth-1" ] content


header : LHtml a -> Html a
header content =
    let
        logo =
            a [ id "logo", href "/" ] [ img [ src "/logo.svg" ] [] ]
    in
        nav [ id "TopNav", class "z-depth-0" ]
            [ div [ class "nav-wrapper" ] (logo :: content) ]


searchBar : String -> a -> (String -> a) -> Html a -> Html a
searchBar userInput submitMsg inputMsg trailing =
    div [ class "search-box" ]
        [ div [ class "search" ]
            [ Html.form [ action "#", method "GET", autocomplete False, Events.onSubmit submitMsg ]
                [ input
                    [ type' "search"
                    , placeholder <| t SearchHealthFacility
                    , value userInput
                    , autofocus True
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
