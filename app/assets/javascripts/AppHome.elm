module AppHome exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api exposing (emptySearch)
import Html exposing (..)
import Html.App
import Map
import Models exposing (Settings, MapViewport, LatLng, SearchResult, shouldLoadMore)
import Shared
import Utils exposing (mapFst, mapTCmd)
import UserLocation
import Suggest


type alias Model =
    { suggest : Suggest.Model, mapViewport : MapViewport, userLocation : UserLocation.Model }


type PrivateMsg
    = SuggestMsg Suggest.Msg
    | MapMsg Map.Msg
    | ApiSearch Bool Api.SearchMsg
    | UserLocationMsg UserLocation.Msg


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search String
    | Private PrivateMsg


init : Settings -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init _ mapViewport userLocation =
    { suggest = Suggest.empty, mapViewport = mapViewport, userLocation = userLocation }
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

                ApiSearch _ _ ->
                    -- TODO handle error
                    ( model, Cmd.none )

                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( { model | mapViewport = mapViewport }, searchAllFacilitiesStartingFrom mapViewport.center )

                MapMsg _ ->
                    ( model, Cmd.none )

                UserLocationMsg msg ->
                    mapTCmd (\m -> { model | userLocation = m }) (Private << UserLocationMsg) <|
                        UserLocation.update s msg model.userLocation

        _ ->
            -- public events
            ( model, Cmd.none )


wrapSuggest : Model -> ( Suggest.Model, Cmd Suggest.Msg ) -> ( Model, Cmd Msg )
wrapSuggest model =
    mapTCmd (\s -> { model | suggest = s }) (Private << SuggestMsg)


view : Model -> Html Msg
view model =
    div []
        [ Shared.headerWithContent
            (suggestionInput model :: (suggestionItems model))
        , userLocationView model
        ]


suggestionInput model =
    Html.App.map (Private << SuggestMsg) (Suggest.viewInput model.suggest)


suggestionItems model =
    (List.map (Html.App.map (Private << SuggestMsg)) (Suggest.viewSuggestions model.suggest))


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.viewMapControl model.userLocation)


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
