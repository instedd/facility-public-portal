module AppHome exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api exposing (emptySearch)
import Html exposing (..)
import Html.App
import Map
import Models exposing (Settings, MapViewport, LatLng, SearchResult, shouldLoadMore)
import Shared
import Utils exposing (mapFst, mapTCmd)
import UserLocation


type alias Model =
    { query : String, suggestions : Shared.Suggestions, mapViewport : MapViewport, userLocation : UserLocation.Model }


type PrivateMsg
    = Input String
    | Sug Api.SuggestionsMsg
    | MapMsg Map.Msg
    | ApiSearch Api.SearchMsg
    | UserLocationMsg UserLocation.Msg


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search String
    | Private PrivateMsg


init : Settings -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init _ mapViewport userLocation =
    ( { query = "", suggestions = Nothing, mapViewport = mapViewport, userLocation = userLocation }
    , searchAllFacilitiesStartingFrom mapViewport.center
    )


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Private msg ->
            case msg of
                Input query ->
                    if query == "" then
                        ( { model | query = query, suggestions = Nothing }, Cmd.none )
                    else
                        ( { model | query = query }, Api.getSuggestions (Private << Sug) (Just model.mapViewport.center) query )

                Sug msg ->
                    case msg of
                        Api.SuggestionsSuccess query suggestions ->
                            if (query == model.query) then
                                ( { model | suggestions = Just suggestions }, Cmd.none )
                            else
                                -- ignore old requests
                                ( model, Cmd.none )

                        -- Ignore out of order results
                        Api.SuggestionsFailed e ->
                            -- TODO
                            ( model, Cmd.none )

                ApiSearch (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            List.map Map.addFacilityMarker results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << ApiSearch) results
                            else
                                Cmd.none
                    in
                        model ! (loadMore :: addFacilities)

                ApiSearch _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( { model | mapViewport = mapViewport }, searchAllFacilitiesStartingFrom mapViewport.center )

                MapMsg _ ->
                    ( model, Cmd.none )

                UserLocationMsg msg ->
                    mapTCmd (\m -> { model | userLocation = m }) (Private << UserLocationMsg) <|
                        UserLocation.update2 s msg model.userLocation

        _ ->
            -- public events
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Shared.headerWithContent
        [ Shared.suggestionsView
            { facilityClicked = FacilityClicked
            , serviceClicked = ServiceClicked
            , locationClicked = LocationClicked
            , submit = Search model.query
            , input = Private << Input
            }
            [ Html.App.map (Private << UserLocationMsg) (UserLocation.view2 model.userLocation) ]
            model.query
            model.suggestions
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map (Private << MapMsg) Map.subscriptions2
        , Map.facilityMarkerClicked FacilityClicked
        ]


mapViewport : Model -> MapViewport
mapViewport model =
    model.mapViewport


userLocation : Model -> UserLocation.Model
userLocation model =
    model.userLocation


searchAllFacilitiesStartingFrom : Models.LatLng -> Cmd Msg
searchAllFacilitiesStartingFrom latLng =
    Api.search (Private << ApiSearch) { emptySearch | latLng = Just latLng }
