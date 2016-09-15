module Main exposing (..)

import Geolocation
import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events
import Http
import Js exposing (..)
import Json.Decode as Decode exposing ((:=))
import Process
import String
import Task
import Time

type alias Flags = { fakeUserPosition : Bool
                   , initialPosition : LatLng
                   }

main : Program Flags
main =
  App.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL
type alias LatLng = (Float, Float)

type Suggestion = Facility String String (List String)
                | Service String Int

type alias Model = { query : String
                   , suggestions : List Suggestion
                   , userLocation : Maybe LatLng
                   }


init : Flags -> (Model, Cmd Msg)
init flags = let model = { query = ""
                         , suggestions = []
                         , userLocation = Nothing
                         }
                 cmd =  if flags.fakeUserPosition
                        then fakeGeolocateUser flags.initialPosition
                        else geolocateUser
             in (model, cmd)

fakeGeolocateUser : LatLng -> Cmd Msg
fakeGeolocateUser pos = Process.sleep (1.5 * Time.second)
                      |> Task.map (always pos)
                      |> Task.perform LocationFailed LocationDetected

geolocateUser : Cmd Msg
geolocateUser = Geolocation.now
              |> Task.map (\location -> (location.latitude, location.longitude))
              |> Task.perform LocationFailed LocationDetected

-- UPDATE

type Msg = Input String
         | SuggestionsSuccess String (List Suggestion)
         | SuggestionsFailed Http.Error
         | LocationDetected LatLng
         | LocationFailed Geolocation.Error

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
                          { model | userLocation = Just pos } ! [Js.displayUserLocation pos]

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

decodeSuggestions : Decode.Decoder (List Suggestion)
decodeSuggestions = Decode.object2 (++)
                                   ("facilities" := Decode.list decodeFacility)
                                   ("services"   := Decode.list decodeService)

decodeService : Decode.Decoder Suggestion
decodeService = Decode.object2 Service
                               ("name"     := Decode.string)
                               ("count"    := Decode.int)

decodeFacility : Decode.Decoder Suggestion
decodeFacility = Decode.object3 Facility
                                ("name"     := Decode.string)
                                ("kind"     := Decode.string)
                                ("services" := Decode.list Decode.string)

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
