module Menu
    exposing
        ( Model(..)
        , Item(..)
        , Settings
        , toggle
        , anchor
        , fixedMenu
        , toggleMenu
        , sideMenu
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Shared exposing (icon, onClick)
import I18n exposing (..)
import SelectList exposing (include, iff)


type Model
    = Open
    | Closed


type Item
    = Map
    | ApiDoc
    | LandingPage
    | Editor


type alias Settings =
    { contactEmail : String
    , showEdition : Bool
    }


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

        menuItem item link iconName label =
            li []
                [ a [ href link, isActive item ]
                    [ icon iconName
                    , text <| t label
                    ]
                ]
    in
        div [ class "menu" ]
            [ ul []
                (SelectList.select
                    [ include <| menuItem Map "/map" "map" I18n.Map
                    , iff settings.showEdition <|
                        menuItem Editor "/edit" "mode_edit" I18n.Editor
                    , include <| menuItem LandingPage "/" "info" I18n.LandingPage
                    , include <| menuItem ApiDoc "/docs" "code" I18n.ApiDocs
                    , include <| hr [] []
                    , include <|
                        li []
                            [ a [ href <| "mailto:" ++ settings.contactEmail ]
                                [ icon "email"
                                , text <| t I18n.Contact
                                ]
                            ]
                    ]
                )
            ]


toggleMenu : Settings -> Item -> Model -> List (Html a) -> List (Html a)
toggleMenu settings active model content =
    case model of
        Closed ->
            content

        Open ->
            [ div []
                [ div [ class "hide-on-med-and-down" ] [ menuContent settings active ]
                , div [ class "hide-on-large-only" ] content
                ]
            ]


sideMenu : Settings -> Item -> Model -> msg -> Html msg
sideMenu settings active model toggleMsg =
    div [ id "mobile-menu", class "hide-on-large-only" ]
        [ div
            [ classList [ ( "side-nav", True ), ( "active", model == Open ) ] ]
            [ menuContent settings active ]
        , div
            [ classList [ ( "overlay", True ), ( "hide", model == Closed ) ], onClick toggleMsg ]
            []
        ]


fixedMenu : Settings -> Item -> Html msg
fixedMenu settings active =
    div [ class "side-nav fixed" ]
        [ Shared.header []
        , menuContent settings active
        ]
