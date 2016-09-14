module Main exposing (..)

import Geolocation
import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events
import Http
import Js exposing (..)
import Json.Decode exposing ((:=))
import String
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
type alias Model = { query : String
                   , suggestions : List Suggestion
                   , userLocation : Maybe (Float,Float)
                   }

initialModel : Model
initialModel = { query = ""
               , suggestions = []
               , userLocation = Nothing
               }

init : (Model, Cmd Msg)
init = (initialModel, Task.perform LocationFailed LocationDetected Geolocation.now)

-- UPDATE

type Msg = Input String
         | SuggestionsSuccess String (List Suggestion)
         | SuggestionsFailed Http.Error
         | LocationDetected Geolocation.Location
         | LocationFailed Geolocation.Error

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
                       Input query ->
                           let model' = {model | query = query}
                           in (model', getSuggestions model')

                       SuggestionsSuccess query suggestions -> if (query == model.query)
                                                               then
                                                                   { model | suggestions = suggestions } ! [Cmd.none]
                                                               else
                                                                   -- Ignore out of order results
                                                                   model ! [Cmd.none]

                       LocationDetected location ->
                          let pos = (location.latitude, location.longitude)
                          in { model | userLocation = Just pos } ! [Js.displayUserLocation pos]

                       _ ->
                           (model, Cmd.none)

getSuggestions : Model -> Cmd Msg
getSuggestions model = let url = String.concat [ "/api/suggest?"
                                               , "q=", model.query
                                               , model.userLocation
                                                   |> Maybe.map (\ (lat,lng) -> "&lat=" ++ (toString lat) ++ "&lng=" ++ (toString lng))
                                                   |> Maybe.withDefault ""
                                               ]
                       in Task.perform SuggestionsFailed (SuggestionsSuccess model.query) (Http.get decodeSuggestions url)

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
mapControlView model = div [ class "map-control z-depth-1" ]
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
