module AppSearch exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api
import Map
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Models exposing (Settings, MapViewport, SearchSpec, SearchResult, Facility, LatLng, shouldLoadMore)
import Shared exposing (icon)
import Utils exposing (mapFst, mapTCmd)
import UserLocation


type alias Model =
    { input : String, query : SearchSpec, mapViewport : MapViewport, userLocation : UserLocation.Model, results : Maybe SearchResult }


type PrivateMsg
    = ApiSearch Api.SearchMsg
      -- ApiSearchMore will keep markers of map. Used for load more and for map panning
    | ApiSearchMore Api.SearchMsg
    | Input String
    | UserLocationMsg UserLocation.Msg
    | MapMsg Map.Msg


type Msg
    = FacilityClicked Int
    | Search SearchSpec
    | Private PrivateMsg


init : Settings -> SearchSpec -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init s query mapViewport userLocation =
    ( { input = queryText query, query = query, mapViewport = mapViewport, userLocation = userLocation, results = Nothing }
    , Api.search (Private << ApiSearch) { query | latLng = Just mapViewport.center }
    )


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Private msg ->
            case msg of
                MapMsg (Map.MapViewportChanged mapViewport) ->
                    let
                        query =
                            model.query

                        loadMore =
                            Api.search (Private << ApiSearchMore) { query | latLng = Just mapViewport.center }
                    in
                        ( { model | mapViewport = mapViewport }, loadMore )

                MapMsg _ ->
                    ( model, Cmd.none )

                ApiSearch (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            List.map Map.addFacilityMarker results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << ApiSearchMore) results
                            else
                                Cmd.none
                    in
                        { model | results = Just results }
                            ! (loadMore :: Map.fitContent :: addFacilities ++ [ Map.clearFacilityMarkers ])

                ApiSearch _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

                ApiSearchMore (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            List.map Map.addFacilityMarker results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << ApiSearchMore) results
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
                    mapTCmd (\m -> { model | userLocation = m }) (Private << UserLocationMsg) <|
                        UserLocation.update s msg model.userLocation

        _ ->
            -- public events
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Shared.headerWithContent [ searchView model ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map (Private << MapMsg) Map.subscriptions
        , Map.facilityMarkerClicked FacilityClicked
        ]


mapViewport : Model -> MapViewport
mapViewport model =
    model.mapViewport


userLocation : Model -> UserLocation.Model
userLocation model =
    model.userLocation


searchView : Model -> Html Msg
searchView model =
    div []
        ((queryBar model)
            ++ [ searchResults model ]
        )


queryBar : Model -> List (Html Msg)
queryBar model =
    -- TODO define how searches with services or locations should appear
    let
        query =
            model.query

        newQuery =
            { query | q = Just model.input }
    in
        [ Shared.searchBar model.input
            [ Html.App.map (Private << UserLocationMsg) (UserLocation.view model.userLocation) ]
            (Search newQuery)
            (Private << Input)
        ]


queryText : SearchSpec -> String
queryText searchSpec =
    Maybe.withDefault "" searchSpec.q


searchResults : Model -> Html Msg
searchResults model =
    let
        entries =
            case model.results of
                Nothing ->
                    -- TODO make a difference between searching and no results
                    []

                Just results ->
                    List.map facilityRow results.items
    in
        div [ class "collection results" ] entries


facilityRow : Facility -> Html Msg
facilityRow f =
    a
        [ class "collection-item result avatar"
        , Events.onClick <| FacilityClicked f.id
        ]
        [ icon "local_hospital"
        , span [ class "title" ] [ text f.name ]
        , p [ class "sub" ] [ text f.kind ]
        ]
