module Update exposing (update, urlUpdate)

import Commands
import Messages exposing (..)
import Models exposing (..)
import Routing exposing (..)
import Search


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update msg model =
    case model of
        Initializing route fakeLocation ->
            case Debug.log "msg Initializing" msg of
                _ ->
                    ( Initialized
                        { query = ""
                        , userLocation = NoLocation
                        , fakeLocation = fakeLocation
                        , suggestions = Nothing
                        , results = Nothing
                        , facility = Nothing
                        , hideResults = False
                        }
                    , Routing.navigate (Routing.routeFromResult route)
                    )

        Initialized model ->
            toAppModel (initializedUpdate msg) model


initializedUpdate : Msg -> Model -> ( Model, Cmd Msg )
initializedUpdate msg model =
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
                        |> SearchRoute
            in
                ( model, Routing.navigate newRoute )

        SearchSuccess result ->
            let
                facilities =
                    result.items

                addFacilities =
                    List.map Commands.addFacilityMarker facilities

                loadMoreFacilities =
                    Commands.searchMore result

                commands =
                    (loadMoreFacilities :: Commands.fitContent :: addFacilities) ++ [ Commands.clearFacilityMarkers ]
            in
                { model | results = Just facilities, suggestions = Nothing } ! commands

        SearchLoadMoreSuccess result ->
            let
                facilities =
                    result.items

                addFacilities =
                    List.map Commands.addFacilityMarker facilities

                loadMoreFacilities =
                    Commands.searchMore result

                commands =
                    loadMoreFacilities :: addFacilities
            in
                model ! commands

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

        MapViewportChanged value ->
            ( model, Cmd.none )

        Navigate route ->
            ( model, Routing.navigate route )


urlUpdate : Result String Route -> AppModel -> ( AppModel, Cmd Msg )
urlUpdate result model =
    case model of
        Initializing _ _ ->
            ( model, Cmd.none )

        Initialized model ->
            toAppModel (initializedUrlUpdate result) model


initializedUrlUpdate : Result String Route -> Model -> ( Model, Cmd Msg )
initializedUrlUpdate result model =
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


toAppModel : (Model -> ( Model, a )) -> Model -> ( AppModel, a )
toAppModel f model =
    let
        ( newModel, a ) =
            f model
    in
        ( Initialized newModel, a )
