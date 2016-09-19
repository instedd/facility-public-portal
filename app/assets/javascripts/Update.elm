module Update exposing (update, urlUpdate)

import Commands exposing (..)
import Http
import Json.Decode exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Routing exposing (..)
import String
import Task

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
                       Input query ->
                           let model' = { model | query = query }
                           in ({ model | query = query }, getSuggestions model')

                       SuggestionsSuccess query suggestions ->
                           if (query == model.query)
                           then
                              { model | suggestions = suggestions } ! [Cmd.none]
                           else
                               model ! [Cmd.none] -- Ignore out of order results

                       LocationDetected pos ->
                          { model | userLocation = Just pos } ! [Commands.displayUserLocation pos]

                       Navigate route ->
                           (model, Routing.navigate route)

                       _ ->
                           (model, Cmd.none)

urlUpdate : Result String Route -> Model -> (Model, Cmd Msg)
urlUpdate result model = ({ model | route = Routing.routeFromResult result }, Cmd.none)

getSuggestions : Model -> Cmd Msg
getSuggestions model = let url = String.concat [ "/api/suggest?"
                                               , "q=", model.query
                                               , model.userLocation
                                                   |> Maybe.map (\ (lat,lng) -> "&lat=" ++ (toString lat) ++ "&lng=" ++ (toString lng))
                                                   |> Maybe.withDefault ""
                                               ]
                       in Task.perform SuggestionsFailed (SuggestionsSuccess model.query) (Http.get suggestionsDecoder url)

suggestionsDecoder : Decoder (List Suggestion)
suggestionsDecoder = object2 (++)
                             ("facilities" := list (object4 Facility ("id"       := int)
                                                                     ("name"     := string)
                                                                     ("kind"     := string)
                                                                     ("services" := list string)))
                             ("services"   := list (object2 Service ("name"  := string)
                                                                    ("count" := int)))
