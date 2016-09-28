module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Json.Decode
import Messages exposing (..)
import Models exposing (..)
import Routing
import Search
import String


view : AppModel -> Html Msg
view model =
    div [ id "container" ]
        [ mapCanvas
        , mapControl model
        ]


mapCanvas : Html Msg
mapCanvas =
    div [ id "map" ] []


mapControl : AppModel -> Html Msg
mapControl model =
    div [ id "map-control", class "z-depth-1" ]
        ([ header ]
            ++ (case model of
                    Initializing _ _ ->
                        []

                    Initialized model ->
                        [ content model ]
               )
        )


header : Html Msg
header =
    nav [ id "TopNav", class "z-depth-0" ]
        [ div [ class "nav-wrapper" ]
            [ a []
                [ img [ id "logo", src "/assets/logo.svg" ] [] ]
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
            [ case model.userLocation of
                Detecting ->
                    div [ id "location-spinner", class "preloader-wrapper small active" ]
                        [ div [ class "spinner-layer spinner-blue-only" ]
                            [ div [ class "circle-clipper left" ]
                                [ div [ class "circle" ] [] ]
                            , div [ class "gap-patch" ] []
                            , div [ class "circle-clipper-right" ]
                                [ div [ class "circle" ] [] ]
                            ]
                        ]

                _ ->
                    a [ href "#", onClick GeolocateUser ]
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
                |> Maybe.map (searchResults model)
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
                , onClick NavigateBack
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
                    List.map (suggestion model) s
    in
        div [ class "collection results" ] entries


suggestion : Model -> Suggestion -> Html Msg
suggestion model s =
    case s of
        F { id, name, kind, services, adm } ->
            a
                [ class "collection-item avatar suggestion facility"
                , onClick <| navFacility id
                ]
                [ icon "local_hospital"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text (adm |> List.drop 1 |> List.reverse |> String.join ", ") ]
                ]

        S { id, name, facilityCount } ->
            a
                [ class "collection-item avatar suggestion service"
                , onClick <| navSearch (Search.byService (userLocation model) id)
                ]
                [ icon "label"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text <| toString facilityCount ++ " facilities" ]
                ]

        L { id, name, parentName } ->
            a
                [ class "collection-item avatar suggestion location"
                , onClick <| navSearch (Search.byLocation (userLocation model) id)
                ]
                [ icon "location_on"
                , span [ class "title" ] [ text name ]
                , p [ class "sub" ]
                    [ text parentName ]
                ]


searchResults : Model -> List Facility -> Html Msg
searchResults model results =
    let
        entries =
            if model.hideResults then
                []
            else
                List.map facility results
    in
        div [ class "collection results" ] entries


facility : Facility -> Html Msg
facility f =
    a
        [ class "collection-item result avatar"
        , onClick <| navFacility f.id
        ]
        [ icon "local_hospital"
        , span [ class "title" ] [ text f.name ]
        , p [ class "sub" ] [ text f.kind ]
        ]


inspector : Model -> Html Msg
inspector model =
    div
        [ id "inspector"
        , class "z-depth-1"
        ]
        [ pre [] [ text (toString model) ] ]



-- HELPERS


onClick : msg -> Attribute msg
onClick message =
    Events.onWithOptions "click"
        { preventDefault = True
        , stopPropagation = True
        }
        (Json.Decode.succeed message)


navFacility : Int -> Msg
navFacility id =
    Navigate (FacilityRoute id)


navSearch : SearchSpec -> Msg
navSearch spec =
    Navigate (SearchRoute spec)


icon : String -> Html Msg
icon name =
    i [ class "material-icons" ] [ text name ]
