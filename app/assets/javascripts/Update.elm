module Update exposing (update, urlUpdate)

import Commands
import Messages exposing (..)
import Models exposing (..)
import Routing exposing (..)
import Search


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input query ->
            if query == "" then
                ( { model | query = query, suggestions = Nothing }, Cmd.none )
            else
                ( { model | query = query }, Commands.getSuggestions (userLocation model) query )

        GeolocateUser ->
            let
                cmd =
                    model.fakeLocation
                        |> Maybe.map Commands.fakeGeolocateUser
                        |> Maybe.withDefault Commands.geolocateUser
            in
                ( { model | userLocation = Detecting }, cmd )

        Search ->
            let
                newRoute =
                    Just model.query
                        |> Search.byQuery (userLocation model)
                        |> Routing.SearchRoute
            in
                ( model, Routing.navigate newRoute )

        SearchSuccess facilities ->
            let
                addFacilities =
                    List.map Commands.addFacilityMarker facilities

                commands =
                    (Commands.fitContent :: addFacilities) ++ [ Commands.clearFacilityMarkers ]
            in
                { model | results = Just facilities, suggestions = Nothing } ! commands

        SearchFailed e ->
            -- TODO
            ( model, Cmd.none )

        SuggestionsSuccess query suggestions ->
            if (query == model.query) then
                { model | suggestions = Just suggestions } ! [ Cmd.none ]
            else
                model ! [ Cmd.none ]

        -- Ignore out of order results
        SuggestionsFailed e ->
            -- TODO
            ( model, Cmd.none )

        LocationDetected pos ->
            { model | userLocation = Detected pos }
                ! [ Commands.fitContent, Commands.addUserMarker pos ]

        LocationFailed e ->
            -- TODO
            { model | userLocation = NoLocation } ! []

        FacilityFecthSuccess facility ->
            { model | query = facility.name, facility = Just facility }
                ! [ Commands.fitContent, Commands.addFacilityMarker facility ]

        FacilityFethFailed error ->
            -- TODO
            ( model, Cmd.none )

        Navigate route ->
            ( model, Routing.navigate route )


urlUpdate : Result String Route -> Model -> ( Model, Cmd Msg )
urlUpdate result model =
    let
        route =
            Routing.routeFromResult result
    in
        case route of
            SearchRoute params ->
                let
                    model =
                        { model
                            | query = Maybe.withDefault "" params.q
                            , hideResults = Search.isEmpty params
                        }
                in
                    model ! [ Commands.search params ]

            FacilityRoute id ->
                let
                    model =
                        { model | suggestions = Nothing, results = Nothing }
                in
                    model ! [ Commands.fetchFacility id, Commands.clearFacilityMarkers ]

            _ ->
                ( model, Cmd.none )
