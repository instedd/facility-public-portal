module Messages exposing (..)

import Geolocation
import Http
import Models exposing (..)
import Routing exposing (Route)

type Msg = Input String
         | SuggestionsSuccess String (List Suggestion)
         | SuggestionsFailed Http.Error
         | LocationDetected LatLng
         | LocationFailed Geolocation.Error
         | Navigate Route
