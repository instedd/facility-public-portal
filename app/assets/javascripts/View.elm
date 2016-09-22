module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Messages exposing (..)
import Models exposing (..)
import Routing
import Json.Decode


view : Model -> Html Msg
view model =
    div [ id "container" ]
        [ mapCanvas
        , mapControl model
        ]


mapCanvas : Html Msg
mapCanvas =
    div [ id "map" ] []


mapControl : Model -> Html Msg
mapControl model =
    div [ id "map-control", class "z-depth-1" ]
        [ header
        , content model
        ]


header : Html Msg
header =
    nav [ id "TopNav", class "z-depth-0" ]
        [ div [ class "nav-wrapper" ]
            [ a []
                [ img [ src "/assets/logo.png" ] [] ]
            , a [ class "right" ]
                [ icon "menu" ]
            ]
        ]


searchBar : Model -> Html Msg
searchBar model =
    div [ class "search-box" ]
        [ div [ class "search" ]
            [ Html.form [ Events.onSubmit Search ]
                [ input [ type' "text", placeholder "Search health facilities", Events.onInput Input ] []
                , icon "search"
                ]
            ]
        , div [ class "location" ]
            [ a [ href "#", onClick GeolocateUser ]
                [ icon "my_location" ]
            ]
        ]


searchView : Model -> Html Msg -> Html Msg
searchView model content =
    div []
        [ searchBar model
        , content
        ]


content : Model -> Html Msg
content model =
    let
        facilityView =
            model.facility
                |> Maybe.map facilityDetail
                |> Maybe.withDefault (div [] [])

        searchResultsView =
            model.results
                |> Maybe.map (always (searchResults model))
                |> Maybe.map (searchView model)
                |> Maybe.withDefault facilityView
    in
        model.suggestions
            |> Maybe.map (suggestions model)
            |> Maybe.map (searchView model)
            |> Maybe.withDefault searchResultsView


facilityDetail : Facility -> Html Msg
facilityDetail facility =
    div [ class "facilityDetail" ]
        [ div [ class "title" ]
            [ span [] [ text facility.name ]
            , i
                [ class "material-icons right"
                , onClick <| Navigate (Routing.SearchRoute { q = Nothing, latLng = Nothing })
                ]
                [ text "clear" ]
            ]
        , div [ class "services" ]
            [ span [] [ text "Services" ]
            , ul []
                (List.map (\s -> li [] [ text s ]) facility.services)
            ]
        ]


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
        div [ class "collection results" ] entries


suggestion : Suggestion -> Html Msg
suggestion s =
    case s of
        F { id, name, kind, services } ->
            a
                [ class "collection-item avatar suggestion facility"
                , onClick <| Navigate (Routing.FacilityRoute id)
                ]
                [ icon "location_on"
                , span [ class "title" ] [ text name ]
                ]

        S { name, count } ->
            a
                [ class "collection-item avatar suggestion service" ]
                [ icon "label"
                , span [ class "title" ] [ text name ]
                , p [ class "kind" ] [ text (toString count ++ " facilities") ]
                ]


searchResults : Model -> Html Msg
searchResults model =
    let
        entries =
            model.results
                |> Maybe.withDefault []
                |> List.map facility
    in
        div [ class "collection results" ] entries


facility : Facility -> Html Msg
facility f =
    a
        [ class "collection-item result avatar"
        , onClick <| Navigate (Routing.FacilityRoute f.id)
        ]
        [ icon "location_on"
        , span [ class "title" ] [ text f.name ]
        , p [ class "kind" ] [ text f.kind ]
        ]


inspector : Model -> Html Msg
inspector model =
    div
        [ id "inspector"
        , class "z-depth-1"
        ]
        [ pre [] [ text (toString model) ] ]


onClick : msg -> Attribute msg
onClick message =
    Events.onWithOptions "click"
        { preventDefault = True
        , stopPropagation = True
        }
        (Json.Decode.succeed message)


icon : String -> Html Msg
icon name =
    i [ class "material-icons" ] [ text name ]
