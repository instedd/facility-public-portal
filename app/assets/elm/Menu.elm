module Menu exposing
    ( Item(..)
    , Model(..)
    , Settings
    , anchor
    , dimWhenOpen
    , fixed
    , parseItem
    , sideBar
    , toggle
    , togglingContent
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import I18n exposing (..)
import Layout
import SelectList exposing (iff, include)
import Shared exposing (icon, onClick)


type Model
    = Open
    | Closed


type Item
    = Map
    | ApiDoc
    | LandingPage
    | Editor
    | Dataset
    | Logout


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
            classList [ ( "active", active == item ) ]

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
                    menuItem Editor "/content" "mode_edit" I18n.Editor
                , iff settings.showEdition <|
                    menuItem Dataset "/datasets" "storage" I18n.Dataset
                , iff settings.showEdition <|
                    menuItem Logout "/users/sign_out" "logout" I18n.Logout
                , include <| menuItem LandingPage "/" "info" I18n.LandingPage
                , include <| menuItem ApiDoc "/docs" "code" I18n.ApiDocs
                , include <| hr [] []
                , include <|
                    li []
                        [ a [ href <| "/api/dump" ]
                            [ icon "file_download"
                            , text <| t I18n.FullDownload
                            ]
                        ]
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


togglingContent : Settings -> Item -> Model -> List (Html a) -> List (Html a)
togglingContent settings active model content =
    case model of
        Closed ->
            content

        Open ->
            [ div []
                [ div [ class "hide-on-med-and-down" ] [ menuContent settings active ]
                , div [ class "hide-on-large-only" ] content
                ]
            ]


dimWhenOpen : List (Html a) -> Model -> List (Html a)
dimWhenOpen content model =
    case model of
        Closed ->
            content

        Open ->
            div [ class "overlay" ] []
                :: content


sideBar : Settings -> Item -> Model -> msg -> Html msg
sideBar settings active model toggleMsg =
    div [ id "mobile-menu", class "hide-on-large-only" ]
        [ div
            [ classList [ ( "side-nav", True ), ( "active", model == Open ) ] ]
            [ menuContent settings active ]
        , div
            [ classList [ ( "overlay", True ), ( "hide", model == Closed ) ], onClick toggleMsg ]
            []
        ]


fixed : Settings -> Item -> Html msg
fixed settings active =
    div [ class "side-nav fixed" ]
        [ Layout.header [] []
        , menuContent settings active
        ]


parseItem : String -> Item
parseItem s =
    case s of
        "landing" ->
            LandingPage

        "editor" ->
            Editor

        "docs" ->
            ApiDoc

        "datasets" ->
            Dataset

        "map" ->
            Map

        _ ->
            LandingPage
