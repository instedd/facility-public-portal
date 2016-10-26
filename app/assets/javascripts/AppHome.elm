module AppHome exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api exposing (emptySearch)
import Html exposing (..)
import Html.App
import Map
import Models exposing (Settings, MapViewport, LatLng, SearchResult, FacilityType, shouldLoadMore)
import Shared exposing (MapView)
import Utils exposing (mapFst, mapTCmd)
import UserLocation
import Suggest
import Debounce


type alias Model =
    { suggest : Suggest.Model, mapViewport : MapViewport, userLocation : UserLocation.Model, d : Debounce.State, facilityTypes : List FacilityType }


type PrivateMsg
    = SuggestMsg Suggest.Msg
    | MapMsg Map.Msg
    | ApiSearch Bool Api.SearchMsg
    | UserLocationMsg UserLocation.Msg
    | Deb (Debounce.Msg Msg)
    | PerformSearch


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search String
    | Private PrivateMsg
    | UnhandledError


init : Settings -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init settings mapViewport userLocation =
    { suggest = Suggest.empty, mapViewport = mapViewport, userLocation = userLocation, d = Debounce.init, facilityTypes = settings.facilityTypes }
        ! [ searchAllFacilitiesStartingFrom mapViewport.center
          , Map.removeHighlightedFacilityMarker
          , Map.fitContentUsingPadding False
          ]


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Private msg ->
            case msg of
                SuggestMsg msg ->
                    case msg of
                        Suggest.FacilityClicked facilityId ->
                            ( model, Utils.performMessage (FacilityClicked facilityId) )

                        Suggest.ServiceClicked serviceId ->
                            ( model, Utils.performMessage (ServiceClicked serviceId) )

                        Suggest.LocationClicked locationId ->
                            ( model, Utils.performMessage (LocationClicked locationId) )

                        Suggest.Search q ->
                            ( model, Utils.performMessage (Search q) )

                        _ ->
                            wrapSuggest model <| Suggest.update { mapViewport = model.mapViewport } msg model.suggest

                ApiSearch initial (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            if initial then
                                Map.resetFacilityMarkers results.items
                            else
                                Map.addFacilityMarkers results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << (ApiSearch False)) results
                            else
                                Cmd.none
                    in
                        model ! [ loadMore, addFacilities ]

                ApiSearch _ (Api.SearchFailed _) ->
                    ( model, Utils.performMessage UnhandledError )

                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( { model | mapViewport = mapViewport }, debCmd (Private PerformSearch) )

                MapMsg _ ->
                    ( model, Cmd.none )

                UserLocationMsg msg ->
                    mapTCmd (\m -> { model | userLocation = m }) (Private << UserLocationMsg) <|
                        UserLocation.update s msg model.userLocation

                PerformSearch ->
                    ( model, searchAllFacilitiesStartingFrom model.mapViewport.center )

                Deb a ->
                    Debounce.update cfg a model

        _ ->
            -- public events
            ( model, Cmd.none )


cfg : Debounce.Config Model Msg
cfg =
    Debounce.config .d (\model s -> { model | d = s }) (Private << Deb) 750


debCmd =
    Debounce.debounceCmd cfg


wrapSuggest : Model -> ( Suggest.Model, Cmd Suggest.Msg ) -> ( Model, Cmd Msg )
wrapSuggest model =
    mapTCmd (\s -> { model | suggest = s }) (Private << SuggestMsg)


view : Model -> MapView Msg
view model =
    { headerClass = ""
    , content = suggestionInput model :: (suggestionItems model)
    , toolbar = [ userLocationView model ]
    , bottom = []
    , modal = List.map (Html.App.map (Private << SuggestMsg)) (Suggest.advancedSearchWindow model.suggest model.facilityTypes)
    }


suggestionInput model =
    Html.App.map (Private << SuggestMsg) (Suggest.viewInput model.suggest)


suggestionItems model =
    (List.map (Html.App.map (Private << SuggestMsg)) (Suggest.viewSuggestions model.suggest))


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.view model.userLocation)


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


searchAllFacilitiesStartingFrom : Models.LatLng -> Cmd Msg
searchAllFacilitiesStartingFrom latLng =
    Api.search (Private << (ApiSearch True)) { emptySearch | latLng = Just latLng }
