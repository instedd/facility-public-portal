module CommandsDeprecated exposing (..)

import Decoders exposing (..)
import Geolocation
import Http
import Json.Encode exposing (..)
import Messages exposing (..)
import Models exposing (..)
import Process
import Search
import Task
import Time
import Utils exposing (..)


search : SearchSpec -> Cmd Msg
search params =
    let
        url =
            Search.path "/api/search" params
    in
        Task.perform SearchFailed SearchSuccess (Http.get Decoders.search url)


appendSearch : SearchSpec -> Cmd Msg
appendSearch params =
    let
        url =
            Search.path "/api/search" params
    in
        Task.perform SearchFailed SearchLoadMoreSuccess (Http.get Decoders.search url)


searchMore : SearchResult -> Cmd Msg
searchMore result =
    case result.nextUrl of
        Nothing ->
            Cmd.none

        Just nextUrl ->
            Task.perform SearchFailed SearchLoadMoreSuccess (Http.get Decoders.search nextUrl)


fetchFacility : Int -> Cmd Msg
fetchFacility id =
    let
        url =
            "/api/facilities/" ++ (toString id)
    in
        Task.perform FacilityFethFailed FacilityFecthSuccess (Http.get Decoders.facility url)


currentDate : Cmd Msg
currentDate =
    let
        notFailing x =
            notFailing x
    in
        Task.perform notFailing (dateFromEpochMillis >> CurrentDate) Time.now


fakeGeolocateUser : LatLng -> Cmd Msg
fakeGeolocateUser pos =
    Process.sleep (1.5 * Time.second)
        |> Task.map (always pos)
        |> Task.perform LocationFailed LocationDetected


geolocateUser : Cmd Msg
geolocateUser =
    Geolocation.now
        |> Task.map (\location -> ( location.latitude, location.longitude ))
        |> Task.perform LocationFailed LocationDetected
