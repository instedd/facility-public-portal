module Layout
    exposing
        ( MapView
        , ExpandedView
        , overMap
        , sideControl
        , expansibleControl
        , header
        , contentWithTopBar
        , mapExpandedView
        )

import Html exposing (..)
import Html.Attributes exposing (..)
import Shared exposing (LHtml, icon, onClick, lmap)
import String


type alias MapView a =
    { headerClasses : List String
    , content : LHtml a
    , expandedContent : Maybe (ExpandedView a)
    , toolbar : LHtml a
    , bottom : LHtml a
    , modal : LHtml a
    }


type alias ExpandedView a =
    { side : LHtml a
    , main : LHtml a
    }


overMap : LHtml a -> Html a
overMap content =
    let
        mapCanvas =
            div [ id "map" ] []
    in
        div [ id "container" ] (mapCanvas :: content)


sideControl : Html a -> List (Html a) -> Html a
sideControl header content =
    mapControl { expansible = False, expanded = False }
        [ div [ class "panels z-depth-1" ]
            [ div [ class "side" ] <|
                mapControlColumn
                    header
                    content
            ]
        ]


expansibleControl : Html msg -> Bool -> msg -> List (Html msg) -> Maybe (ExpandedView msg) -> Html msg
expansibleControl header expanded toggleMsg collapsedView expandedContent =
    let
        toggleIcon =
            if expanded then
                "keyboard_arrow_left"
            else
                "keyboard_arrow_right"
    in
        case expandedContent of
            Nothing ->
                sideControl header collapsedView

            Just { side, main } ->
                mapControl { expansible = True, expanded = expanded }
                    [ div [ class "panels z-depth-1" ]
                        [ -- mobile view: rendered separately and toggled via CSS
                          div [ class "side hide-on-large-only" ] <|
                            mapControlColumn
                                header
                                collapsedView
                          -- desktop view: expansible content
                        , div [ class "side hide-on-med-and-down" ] <|
                            mapControlColumn
                                header
                                (if expanded then
                                    side
                                 else
                                    collapsedView
                                )
                        , div [ class "main hide-on-med-and-down" ] <|
                            mapControlColumn
                                (div [ class "TopNav" ] [])
                                main
                        ]
                    , mapControlToggle toggleMsg toggleIcon
                    ]


mapControl : { expansible : Bool, expanded : Bool } -> List (Html a) -> Html a
mapControl { expansible, expanded } =
    div
        [ id "map-control"
        , classList
            [ ( "expansible", expansible )
            , ( "expanded", expanded )
            ]
        ]


mapControlColumn : Html a -> List (Html a) -> List (Html a)
mapControlColumn headerRow contentRow =
    [ headerRow
    , div [ class "control-content" ] contentRow
    ]


mapControlToggle toggleMsg toggleIcon =
    div [ class "toggle hide-on-med-and-down" ]
        [ div [ class "spacing" ] []
        , div [ class "toggle-btn z-depth-1", onClick toggleMsg ]
            [ icon toggleIcon ]
        ]


header : LHtml a -> List String -> Html a
header content classes =
    let
        classAttribute =
            classList (List.map (\c -> ( c, True )) classes)

        logo =
            a [ id "logo", href "/" ] [ img [ src "/logo.png" ] [] ]
    in
        div [ classAttribute ]
            [ nav [ class "TopNav z-depth-0" ]
                [ div [ class "nav-wrapper" ] (logo :: content) ]
            ]


contentWithTopBar : Html a -> List (Html a) -> List (Html a)
contentWithTopBar topBar content =
    [ div [ class "control-content-top" ] [ topBar ]
    , div [ class "control-content-bottom" ] content
    ]


mapExpandedView : (a -> b) -> ExpandedView a -> ExpandedView b
mapExpandedView f { side, main } =
    { side = lmap f side
    , main = lmap f main
    }
