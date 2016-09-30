module AppSearch exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport, userLocation)

import Api
import Map
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Models exposing (MapViewport, SearchSpec, SearchResult, Facility, LatLng, shouldLoadMore)
import Shared exposing (icon)
import Utils exposing (mapFst)
import Commands
import UserLocation


type alias Model =
    { input : String, query : SearchSpec, mapViewport : MapViewport, userLocation : UserLocation.Model, results : Maybe SearchResult }


type Msg
    = ApiSearch Api.SearchMsg
      -- ApiSearchMore will keep markers of map. Used for load more and for map panning
    | ApiSearchMore Api.SearchMsg
    | Input String
    | MapViewportChanged MapViewport
    | UserLocationMsg UserLocation.Msg


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    , search : SearchSpec -> msg
    , facilityClicked : Int -> msg
    , fakeLocation : Maybe LatLng
    }


init : Host model msg -> SearchSpec -> MapViewport -> UserLocation.Model -> ( model, Cmd msg )
init h query mapViewport userLocation =
    mapFst h.model <|
        ( { input = queryText query, query = query, mapViewport = mapViewport, userLocation = userLocation, results = Nothing }
        , Api.search (h.msg << ApiSearch) { query | latLng = Just mapViewport.center }
        )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    mapFst h.model <|
        case msg of
            MapViewportChanged mapViewport ->
                let
                    query =
                        model.query

                    loadMore =
                        Api.search (h.msg << ApiSearchMore) { query | latLng = Just mapViewport.center }
                in
                    ( { model | mapViewport = mapViewport }, loadMore )

            ApiSearch (Api.SearchSuccess results) ->
                let
                    addFacilities =
                        List.map Commands.addFacilityMarker results.items

                    loadMore =
                        if shouldLoadMore results model.mapViewport then
                            Api.searchMore (h.msg << ApiSearchMore) results
                        else
                            Cmd.none
                in
                    { model | results = Just results }
                        ! (loadMore :: Commands.fitContent :: addFacilities ++ [ Commands.clearFacilityMarkers ])

            ApiSearch _ ->
                -- TODO handle error
                ( model, Cmd.none )

            ApiSearchMore (Api.SearchSuccess results) ->
                let
                    addFacilities =
                        List.map Commands.addFacilityMarker results.items

                    loadMore =
                        if shouldLoadMore results model.mapViewport then
                            Api.searchMore (h.msg << ApiSearchMore) results
                        else
                            Cmd.none
                in
                    -- TODO append/merge or replace results items to current results. The order might not be trivial
                    model ! (loadMore :: addFacilities)

            ApiSearchMore _ ->
                -- TODO handle error
                ( model, Cmd.none )

            Input query ->
                ( { model | input = query }, Cmd.none )

            UserLocationMsg msg ->
                UserLocation.update (hostUserLocation h) msg model


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            searchView h model


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    (Map.subscriptions <| hostMap h)


hostMap : Host model msg -> Map.Host msg
hostMap h =
    { mapViewportChanged = h.msg << MapViewportChanged
    , facilityMarkerClicked = h.facilityClicked
    }


mapViewport : Model -> MapViewport
mapViewport model =
    model.mapViewport


userLocation : Model -> UserLocation.Model
userLocation model =
    model.userLocation


searchView : Host model msg -> Model -> Html msg
searchView h model =
    div []
        ((queryBar h model)
            ++ [ searchResults h model ]
        )


queryBar : Host model msg -> Model -> List (Html msg)
queryBar h model =
    -- TODO define how searches with services or locations should appear
    let
        query =
            model.query

        newQuery =
            { query | q = Just model.input }
    in
        [ Shared.searchBar model.input
            [ UserLocation.view (hostUserLocation h) model.userLocation ]
            (h.search newQuery)
            (h.msg << Input)
        ]


queryText : SearchSpec -> String
queryText searchSpec =
    Maybe.withDefault "" searchSpec.q


searchResults : Host model msg -> Model -> Html msg
searchResults h model =
    let
        entries =
            case model.results of
                Nothing ->
                    -- TODO make a difference between searching and no results
                    []

                Just results ->
                    List.map (facilityRow h) results.items
    in
        div [ class "collection results" ] entries


facilityRow : Host model msg -> Facility -> Html msg
facilityRow h f =
    a
        [ class "collection-item result avatar"
        , Events.onClick <| h.facilityClicked f.id
        ]
        [ icon "local_hospital"
        , span [ class "title" ] [ text f.name ]
        , p [ class "sub" ] [ text f.kind ]
        ]


hostUserLocation : Host model msg -> UserLocation.Host Model msg
hostUserLocation h =
    { setModel = \model userLocation -> { model | userLocation = userLocation }
    , msg = h.msg << UserLocationMsg
    , fakeLocation = h.fakeLocation
    }
