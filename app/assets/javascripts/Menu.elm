module Menu exposing (Model(..), toggle, anchor, menuContent, orContent)

import Html exposing (..)
import Html.Attributes exposing (..)
import Shared exposing (icon)
import Models exposing (Settings)


type Model
    = Open
    | Closed


toggle model =
    case model of
        Open ->
            Closed

        Closed ->
            Open


anchor : a -> Html a
anchor msg =
    a [ href "#", Shared.onClick msg, class "right" ] [ icon "menu" ]


menuContent : Settings -> Html a
menuContent settings =
    div [ class "menu" ]
        [ ul []
            [ li []
                [ a [ href "/", class "active" ]
                    [ icon "map"
                    , text "Map"
                    ]
                ]
            , hr [] []
            , li []
                [ a [ href <| "mailto:" ++ settings.contactEmail ]
                    [ icon "email"
                    , text "Contact"
                    ]
                ]
            ]
        ]


orContent : Settings -> Model -> List (Html a) -> List (Html a)
orContent settings model content =
    case model of
        Closed ->
            content

        Open ->
            [ menuContent settings ]
