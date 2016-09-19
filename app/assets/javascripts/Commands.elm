port module Commands exposing (..)

import Decoders exposing (..)
import Geolocation
import Http
import Json.Encode exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Process
import Routing
import String
import Task
import Time

port jsCommand : Command -> Cmd msg

type alias Command = (String, Json.Encode.Value)

initializeMap : (Float, Float) -> Cmd msg
initializeMap pos = jsCommand ("initializeMap", encodeLatLng pos)

displayUserLocation : (Float, Float) -> Cmd msg
displayUserLocation pos = jsCommand ("displayUserLocation", encodeLatLng pos)

encodeLatLng : (Float, Float) -> Json.Encode.Value
encodeLatLng (lat, lng )= object [ ("lat", float lat)
                                 , ("lng", float lng)
                                 ]

fakeGeolocateUser : LatLng -> Cmd Msg
fakeGeolocateUser pos = Process.sleep (1.5 * Time.second)
                      |> Task.map (always pos)
                      |> Task.perform LocationFailed LocationDetected

geolocateUser : Cmd Msg
geolocateUser = Geolocation.now
              |> Task.map (\location -> (location.latitude, location.longitude))
              |> Task.perform LocationFailed LocationDetected

getSuggestions : Model -> Cmd Msg
getSuggestions model = let params = { q = Just model.query, latLng = model.userLocation }
                           url    = Routing.searchPath "/api/suggest" params
                       in Task.perform SuggestionsFailed (SuggestionsSuccess model.query) (Http.get Decoders.suggestions url)

search : SearchSpec -> Cmd Msg
search params = let url = Routing.searchPath "/api/search" params
                in Task.perform SearchFailed SearchSuccess (Http.get Decoders.search url)
