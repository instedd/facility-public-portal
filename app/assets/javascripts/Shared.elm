module Shared exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Models
import String


type alias Suggestions =
    Maybe (List Models.Suggestion)


mapWithControl : Maybe (Html a) -> Html a
mapWithControl content =
    div [ id "container" ]
        [ mapCanvas
        , mapControl content
        ]


mapCanvas : Html a
mapCanvas =
    div [ id "map" ] []


mapControl : Maybe (Html a) -> Html a
mapControl content =
    div [ id "map-control", class "z-depth-1" ]
        ([ header ]
            ++ (case content of
                    Nothing ->
                        []

                    Just content ->
                        [ content ]
               )
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


searchBar : String -> a -> (String -> a) -> Html a
searchBar userInput submitMsg inputMsg =
    div [ class "search-box" ]
        [ div [ class "search" ]
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


suggestionsView : String -> Suggestions -> a -> (String -> a) -> Html a
suggestionsView userInput items submitMsg inputMsg =
    div []
        ([ searchBar userInput submitMsg inputMsg
         ]
            ++ (case items of
                    Nothing ->
                        []

                    Just s ->
                        [ suggestionsContent s ]
               )
        )


suggestionsContent : List Models.Suggestion -> Html a
suggestionsContent s =
    let
        entries =
            case s of
                [] ->
                    [ text "Nothing found..." ]

                _ ->
                    List.map suggestion s
    in
        div [ class "collection results" ] entries


suggestion : Models.Suggestion -> Html a
suggestion s =
    case s of
        Models.F { id, name, kind, services, adm } ->
            a
                [ class "collection-item avatar suggestion facility"
                  --, onClick <| navFacility id
                ]
                [ icon "local_hospital"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text (adm |> List.drop 1 |> List.reverse |> String.join ", ") ]
                ]

        Models.S { id, name, facilityCount } ->
            a
                [ class "collection-item avatar suggestion service"
                  --, onClick <| navSearch (Search.byService (userLocation model) id)
                ]
                [ icon "label"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text <| toString facilityCount ++ " facilities" ]
                ]

        Models.L { id, name, parentName } ->
            a
                [ class "collection-item avatar suggestion location"
                  -- , onClick <| navSearch (Search.byLocation (userLocation model) id)
                ]
                [ icon "location_on"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text parentName ]
                ]


icon : String -> Html a
icon name =
    i [ class "material-icons" ] [ text name ]
