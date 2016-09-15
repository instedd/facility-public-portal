module Update exposing (update)

import Commands exposing (..)
import Http
import Json.Decode exposing (..)
import Messages exposing (..)
import Models exposing (..)
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

decodeSuggestions : Decoder (List Suggestion)
decodeSuggestions = object2 (++)
                            ("facilities" := list decodeFacility)
                            ("services"   := list decodeService)

decodeService : Decoder Suggestion
decodeService = object2 Service
                        ("name"  := string)
                        ("count" := int)

decodeFacility : Decoder Suggestion
decodeFacility = object3 Facility
                         ("name"     := string)
                         ("kind"     := string)
                         ("services" := list string)
