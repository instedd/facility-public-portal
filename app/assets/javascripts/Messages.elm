module Messages exposing (..)

import Geolocation
import Http
import Models exposing (..)
import Date exposing (Date)


type Msg
    = Input String
    | CurrentDate Date
    | GeolocateUser
    | Search
    | SearchSuccess SearchResult
    | SearchLoadMoreSuccess SearchResult
    | SearchFailed Http.Error
    | SuggestionsSuccess String (List Suggestion)
    | SuggestionsFailed Http.Error
    | LocationDetected LatLng
    | LocationFailed Geolocation.Error
    | FacilityFecthSuccess Facility
    | FacilityFethFailed Http.Error
    | Navigate Route
    | NavigateBack
    | MapViewportChanged MapViewport
