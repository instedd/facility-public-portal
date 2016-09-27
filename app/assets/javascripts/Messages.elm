module Messages exposing (..)

import Geolocation
import Http
import Models exposing (..)
import Routing exposing (Route)


type Msg
    = Input String
    | GeolocateUser
    | Search
    | SearchSuccess SearchResult
    | SearchFailed Http.Error
    | SuggestionsSuccess String (List Suggestion)
    | SuggestionsFailed Http.Error
    | LocationDetected LatLng
    | LocationFailed Geolocation.Error
    | FacilityFecthSuccess Facility
    | FacilityFethFailed Http.Error
    | Navigate Route
    | MapViewportChanged MapViewport
