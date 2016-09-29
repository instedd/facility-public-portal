module AppSearch exposing (Host, Model, Msg, init, view, update, subscriptions, mapViewport)

import Api
import Context
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Models exposing (MapViewport, SearchSpec, SearchResult, Facility)
import Shared exposing (icon)
import Utils exposing (mapFst)
import Commands


type alias Model =
    { input : String, query : SearchSpec, mapViewport : MapViewport, results : Maybe SearchResult }


type Msg
    = ContextMsg Context.Msg
    | ApiSearch Api.SearchMsg
    | Input String


type alias Host model msg =
    { model : Model -> model
    , msg : Msg -> msg
    , search : SearchSpec -> msg
    , facilityClicked : Int -> msg
    }


init : Host model msg -> SearchSpec -> MapViewport -> ( model, Cmd msg )
init h query mapViewport =
    mapFst h.model <|
        ( { input = queryText query, query = query, mapViewport = mapViewport, results = Nothing }
        , Api.search (h.msg << ApiSearch) query
        )


update : Host model msg -> Msg -> Model -> ( model, Cmd msg )
update h msg model =
    mapFst h.model <|
        case msg of
            ContextMsg msg ->
                -- TODO update search when viewport changes
                Context.update (hostContext h) msg model

            ApiSearch (Api.SearchSuccess results) ->
                let
                    addFacilities =
                        List.map Commands.addFacilityMarker results.items

                    commands =
                        (Commands.fitContent :: addFacilities) ++ [ Commands.clearFacilityMarkers ]
                in
                    -- TODO keep loading more results until map bounds exceeded
                    { model | results = Just results } ! commands

            Input query ->
                ( { model | input = query }, Cmd.none )

            _ ->
                -- TODO handle error
                ( model, Cmd.none )


view : Host model msg -> Model -> Html msg
view h model =
    Shared.mapWithControl <|
        Just <|
            searchView h model


subscriptions : Host model msg -> Model -> Sub msg
subscriptions h model =
    (Context.subscriptions <| hostContext h)


hostContext : Host model msg -> Context.Host Model msg
hostContext h =
    { setMapViewport = \mapViewport model -> { model | mapViewport = mapViewport }
    , facilityMarkerClicked = h.facilityClicked
    , msg = h.msg << ContextMsg
    }


mapViewport : Model -> MapViewport
mapViewport model =
    model.mapViewport


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
        [ Shared.searchBar model.input (h.search newQuery) (h.msg << Input) ]


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
