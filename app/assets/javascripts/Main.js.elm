port module Main exposing (..)

import Http
import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode exposing ((:=))
import Task

main : Program Never
main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Suggestion = { kind : String, name : String }
type alias Model = { query : String, suggestions : List Suggestion }

initialModel : Model
initialModel = { query = "", suggestions = [] }

init : (Model, Cmd Msg)
init = (initialModel, Cmd.none)

-- UPDATE

type Msg = Input String

         | SuggestionsSuccess String (List Suggestion)
         | SuggestionsFailed Http.Error

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
                       Input query -> ({model | query = query}, getSuggestions query)

                       SuggestionsSuccess query suggestions -> if (query == model.query)
                                                               then
                                                                   ({model | suggestions = suggestions}, Cmd.none)
                                                               else
                                                                   -- Ignore out of order results
                                                                   (model, Cmd.none)
                       _ -> (model, Cmd.none)

getSuggestions : String -> Cmd Msg
getSuggestions query = let url = "/api/suggest?q=" ++ query
                       in Task.perform SuggestionsFailed (SuggestionsSuccess query) (Http.get decodeSuggestions url)

decodeSuggestions : Json.Decode.Decoder (List Suggestion)
decodeSuggestions = Json.Decode.list <| Json.Decode.object2 buildSuggestion
                                                            ("kind" := Json.Decode.string)
                                                            ("name" := Json.Decode.string)

buildSuggestion : String -> String -> Suggestion
buildSuggestion kind name = { kind = kind, name = name}

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

-- VIEW

view : Model -> Html Msg
view model = div [] [ mapControlView model ]

mapControlView : Model -> Html Msg
mapControlView model = div [ class "map-control" ]
                           [ div [ class "row header" ]
                                 [ span [] [ text "Ethiopia" ]
                                 , h1 [] [ text "Ministry of Health" ]
                                 ]
                           , div [ class "row" ]
                                 ([ input  [ value model.query
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
suggestionView s = div [ class "row suggestion" ] [ text s.name ]
