module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Messages exposing (..)
import Models exposing (..)
import String

view : Model -> Html Msg
view model = div [] [ mapControlView model ]

mapControlView : Model -> Html Msg
mapControlView model = div [ class "map-control z-depth-1" ]
                           [ div [ class "row header" ]
                                 [ span [] [ text "Ethiopia" ]
                                 , h1 [] [ text "Ministry of Health" ]
                                 ]
                           , div [ class "row" ]
                                 ([ input  [ value model.query
                                           , autofocus True
                                           , placeholder "Search health facilities"
                                           , Html.Events.onInput Input ]
                                          []
                                  ] ++ suggestionsView model)
                           ]

suggestionsView : Model -> List (Html Msg)
suggestionsView model = if model.query == ""
                        then []
                        else if List.isEmpty model.suggestions
                             then [div [class "row"] [text "Nothing found..."]]
                             else List.map suggestionView model.suggestions

suggestionView : Suggestion -> Html Msg
suggestionView s = case s of
                       Facility name kind services ->
                           div [ class "row suggestion facility" ]
                               [ text name ]
                       Service name count ->
                           div [ class "row suggestion service" ]
                               [ text <| String.concat [ name, " (", toString count, " facilities)" ]]
