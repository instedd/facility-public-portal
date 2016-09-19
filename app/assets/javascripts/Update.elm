module Update exposing (update, urlUpdate)

import Commands
import Messages exposing (..)
import Models exposing (..)
import Routing exposing (..)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = case msg of
                       Input query ->
                           let model' = { model | query = query }
                           in (model', Commands.getSuggestions model')

                       Search ->
                           (model, Routing.navigate <| Routing.SearchRoute { q = Just model.query })

                       SearchSuccess facilities ->
                          ({model | results = Just facilities}, Cmd.none)

                       SearchFailed e ->
                           -- TODO
                           (model, Cmd.none)

                       SuggestionsSuccess query suggestions ->
                           if (query == model.query)
                           then
                              { model | suggestions = suggestions } ! [Cmd.none]
                           else
                               model ! [Cmd.none] -- Ignore out of order results

                       SuggestionsFailed e ->
                           -- TODO
                           (model, Cmd.none)

                       LocationDetected pos ->
                          { model | userLocation = Just pos } ! [Commands.displayUserLocation pos]

                       LocationFailed e ->
                           -- TODO
                           (model, Cmd.none)

                       Navigate route ->
                           (model, Routing.navigate route)

urlUpdate : Result String Route -> Model -> (Model, Cmd Msg)
urlUpdate result model = let
                             route  = Routing.routeFromResult result
                         in case route of
                             SearchRoute params ->
                                 (model, Commands.search params)

                             _ ->
                                 (model, Cmd.none)
