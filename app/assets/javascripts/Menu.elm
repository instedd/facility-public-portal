module Menu exposing (Model(..), Item(..), toggle, anchor, menuContent, orContent)

import Html exposing (..)
import Html.Attributes exposing (..)
import Shared exposing (icon)
import Models exposing (Settings)


type Model
    = Open
    | Closed


type Item
    = Map
    | ApiDoc


toggle model =
    case model of
        Open ->
            Closed

        Closed ->
            Open


anchor : a -> Html a
anchor msg =
    a [ href "#", Shared.onClick msg, class "right" ] [ icon "menu" ]


menuContent : Settings -> Item -> Html a
menuContent settings active =
    let
        isActive item =
            class <| Shared.classNames [ ( "active", active == item ) ]
    in
        div [ class "menu" ]
            [ ul []
                [ li []
                    [ a [ href "/", isActive Map ]
                        [ icon "map"
                        , text "Map"
                        ]
                    ]
                , li []
                    [ a [ href "/docs", isActive ApiDoc ]
                        [ icon "code"
                        , text "API Docs"
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


orContent : Settings -> Item -> Model -> List (Html a) -> List (Html a)
orContent settings active model content =
    case model of
        Closed ->
            content

        Open ->
            [ menuContent settings active ]