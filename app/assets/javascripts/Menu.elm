module Menu exposing (Model(..), Item(..), toggle, anchor, menuContent, toggleMenu, sideMenu)

import Html exposing (..)
import Html.Attributes exposing (..)
import Shared exposing (icon, onClick)
import Models exposing (Settings)
import I18n exposing (..)


type Model
    = Open
    | Closed


type Item
    = Map
    | ApiDoc
    | LandingPage


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
                    [ a [ href "/map", isActive Map ]
                        [ icon "map"
                        , text <| t I18n.Map
                        ]
                    ]
                , li []
                    [ a [ href "/", isActive LandingPage ]
                        [ icon "info"
                        , text <| t I18n.LandingPage
                        ]
                    ]
                , li []
                    [ a [ href "/docs", isActive ApiDoc ]
                        [ icon "code"
                        , text <| t I18n.ApiDocs
                        ]
                    ]
                , li []
                    [ a [ href "/data" ]
                        [ icon "file_download"
                        , text <| t I18n.FullDownload
                        ]
                    ]
                , hr [] []
                , li []
                    [ a [ href <| "mailto:" ++ settings.contactEmail ]
                        [ icon "email"
                        , text <| t I18n.Contact
                        ]
                    ]
                ]
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
