module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Messages exposing (..)
import Models exposing (..)
import Routing
import String


view : Model -> Html Msg
view model =
    div [ id "container" ]
        [ mapControl model
        , mapCanvas
          -- , inspector model
        ]


mapCanvas : Html Msg
mapCanvas =
    div [ id "map" ] []


mapControl : Model -> Html Msg
mapControl model =
    div [ class "map-control z-depth-1" ]
        [ header
        , searchBar model
        , content model
        ]


header : Html Msg
header =
    div [ class "row header" ]
        [ span [] [ text "Ethiopia" ]
        , h1 [] [ text "Ministry of Health" ]
        ]


searchBar : Model -> Html Msg
searchBar model =
    div [ class "row search" ]
        [ Html.form [ Events.onSubmit Search ]
            [ input
                [ value model.query
                , autofocus True
                , placeholder "Search health facilities"
                , Events.onInput Input
                ]
                []
            ]
        ]


content : Model -> Html Msg
content model =
    case model.suggestions of
        Nothing ->
            case model.results of
                Nothing ->
                    case model.facility of
                        Nothing ->
                            div [] []

                        Just f ->
                            facilityDetail f

                _ ->
                    searchResults model

        Just s ->
            suggestions model s


facilityDetail : Facility -> Html Msg
facilityDetail facility =
    div [ class "row" ] [ text facility.name ]


suggestions : Model -> List Suggestion -> Html Msg
suggestions model s =
    let
        entries =
            case s of
                [] ->
                    if model.query == "" then
                        []
                    else
                        [ text "Nothing found..." ]

                _ ->
                    List.map suggestion s
    in
        div [ class "row listing" ] entries


suggestion : Suggestion -> Html Msg
suggestion s =
    case s of
        F { id, name, kind, services } ->
            div
                [ class "row entry suggestion facility"
                , Events.onClick <| Navigate (Routing.FacilityRoute id)
                ]
                [ text name ]

        S { name, count } ->
            div [ class "row entry suggestion service" ]
                [ text <| String.concat [ name, " (", toString count, " facilities)" ] ]


searchResults : Model -> Html Msg
searchResults model =
    let
        entries =
            model.results
                |> Maybe.withDefault []
                |> List.map facility
    in
        div [ class "row listing" ] entries


facility : Facility -> Html Msg
facility f =
    div
        [ class "row entry result"
        , Events.onClick <| Navigate (Routing.FacilityRoute f.id)
        ]
        [ text f.name
        , span [ class "kind" ] [ text f.kind ]
        ]


inspector : Model -> Html Msg
inspector model =
    div
        [ id "inspector"
        , class "z-depth-1"
        ]
        [ pre [] [ text (toString model) ] ]
