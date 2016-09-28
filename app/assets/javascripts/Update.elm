module Update exposing (update, urlUpdate)

import Commands
import Messages exposing (..)
import Models exposing (..)
import Routing exposing (..)
import Search
import Navigation


update : Msg -> AppModel -> ( AppModel, Cmd Msg )
update msg appModel =
    case appModel of
        Initializing route fakeLocation ->
            case msg of
                MapViewportChanged mapViewport ->
                    let
                        model =
                            { query = ""
                            , userLocation = NoLocation
                            , fakeLocation = fakeLocation
                            , suggestions = Nothing
                            , results = Nothing
                            , facility = Nothing
                            , hideResults = False
                            , mapViewport = mapViewport
                            , now = Nothing
                            , currentSearch = Nothing
                            }
                    in
                        Initialized model
                            ! [ Routing.navigate (Routing.routeFromResult route)
                              , Commands.currentDate
                              ]

                _ ->
                    Debug.crash "map is not initialized yet"

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

        CurrentDate date ->
            ( { model | now = Just date }, Cmd.none )

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
                    if model.query == "" then
                        RootRoute
                    else
                        Just model.query
                            |> Search.byQuery (Just model.mapViewport.center)
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

                shouldLoadMore =
                    case List.head <| List.reverse facilities of
                        Nothing ->
                            False

                        Just furthest ->
                            distance furthest.position model.mapViewport.center < (maxDistance model.mapViewport)

                commands =
                    (if shouldLoadMore then
                        [ loadMoreFacilities ]
                     else
                        []
                    )
                        ++ addFacilities
            in
                model ! commands

        SearchFailed e ->
            -- TODO
            Debug.crash "Invalid SearchResult"

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

        MapViewportChanged mapViewport ->
            let
                command =
                    case model.currentSearch of
                        Nothing ->
                            Cmd.none

                        Just searchSpec ->
                            Commands.appendSearch (Search.withOrder model.mapViewport.center searchSpec)
            in
                ( { model | mapViewport = mapViewport }, command )

        Navigate route ->
            ( model, Routing.navigate route )

        NavigateBack ->
            ( model, Navigation.back 1 )


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
            RootRoute ->
                ( { model | hideResults = True, currentSearch = Just Search.empty }, Commands.search <| Search.orderedFrom model.mapViewport.center )

            SearchRoute params ->
                let
                    model =
                        { model
                            | query = Maybe.withDefault "" params.q
                            , hideResults = Search.isEmpty params
                            , currentSearch = Just params
                        }
                in
                    model ! [ Commands.search (Search.withOrder model.mapViewport.center params) ]

            FacilityRoute id ->
                let
                    model =
                        { model | suggestions = Nothing, results = Nothing, currentSearch = Nothing }
                in
                    model ! [ Commands.fetchFacility id, Commands.clearFacilityMarkers ]

            NotFoundRoute ->
                ( model, Cmd.none )


toAppModel : (Model -> ( Model, a )) -> Model -> ( AppModel, a )
toAppModel f model =
    let
        ( newModel, a ) =
            f model
    in
        ( Initialized newModel, a )


maxDistance : MapViewport -> Float
maxDistance mapViewport =
    case
        List.maximum <|
            List.map
                (distance mapViewport.center)
                [ ( mapViewport.bounds.north, mapViewport.bounds.east )
                , ( mapViewport.bounds.north, mapViewport.bounds.west )
                , ( mapViewport.bounds.south, mapViewport.bounds.east )
                , ( mapViewport.bounds.south, mapViewport.bounds.west )
                ]
    of
        Just d ->
            -- 20% more of the maximum distance
            d * 1.2

        _ ->
            Debug.crash "unreachable"


distance : LatLng -> LatLng -> Float
distance ( x1, y1 ) ( x2, y2 ) =
    sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
