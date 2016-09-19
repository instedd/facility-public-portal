module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Messages exposing (..)
import Models exposing (..)
import Routing
import String

view : Model -> Html Msg
view model = div [ id "container"]
                 [ mapControl model
                 , mapCanvas
                 -- , inspector model
                 ]

mapCanvas : Html Msg
mapCanvas = div [ id "map" ] []

mapControl : Model -> Html Msg
mapControl model = div [ class "map-control z-depth-1" ]
                           [ header
                           , searchBar model
                           , listing model
                           ]
header : Html Msg
header = div [ class "row header" ]
             [ span [] [ text "Ethiopia" ]
             , h1 [] [ text "Ministry of Health" ]
             ]

searchBar : Model -> Html Msg
searchBar model = div [ class "row search" ]
                      [ Html.form [ Events.onSubmit Search ]
                                  [ input  [ value model.query
                                          , autofocus True
                                          , placeholder "Search health facilities"
                                          , Events.onInput Input
                                          ]
                                          []
                                  ]
                      ]

listing : Model -> Html Msg
listing model = case model.suggestions of
                    Nothing -> div [ class "row listing" ] (searchResults model)
                    Just s  -> div [ class "row listing" ] (suggestions model s)

suggestions : Model -> List Suggestion -> List (Html Msg)
suggestions model s = case s of
                            [] -> if model.query == ""
                                       then []
                                       else [ text "Nothing found..." ]
                            _   -> List.map suggestion s

suggestion : Suggestion -> Html Msg
suggestion s = case s of
                       F {id,name,kind,services} ->
                           div [ class "row entry suggestion facility"
                               , Events.onClick <| Navigate (Routing.FacilityRoute id) ]
                               [ text name ]
                       S {name,count} ->
                           div [ class "row entry suggestion service" ]
                               [ text <| String.concat [ name, " (", toString count, " facilities)" ]]

searchResults : Model -> List (Html Msg)
searchResults model = case model.results of
                          Nothing -> [ ]
                          Just facilities -> List.map facility facilities

facility : Facility -> Html Msg
facility f = div [ class "row entry result" ]
                 [ text f.name
                 , span [ class "kind" ] [ text f.kind]]

inspector : Model -> Html Msg
inspector model = div [ id "inspector"
                      , class "z-depth-1" ]
                      [ pre [] [text (toString model)] ]
