module AppHome
    exposing
        ( Model
        , Msg(..)
        , PrivateMsg
        , init
        , view
        , update
        , subscriptions
        , mapViewport
        , userLocation
        )

import Api
import Debounce
import Html
import Html.App
import Layout exposing (MapView)
import Map
import Models exposing (Settings, MapViewport, LatLng, SearchResult, FacilityType, Ownership, SearchSpec, FacilitySummary, shouldLoadMore, emptySearch)
import Return exposing (..)
import Shared
import Suggest
import UserLocation
import Utils exposing (perform)


type alias Model =
    { suggest : Suggest.Model
    , mapViewport : MapViewport
    , userLocation : UserLocation.Model
    , results : Maybe SearchResult
    , d : Debounce.State
    }


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
    | Private PrivateMsg
    | UnhandledError String
    | Search SearchSpec


init : Settings -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init settings mapViewport userLocation =
    let
        ( suggestModel, suggestCmd ) =
            Suggest.empty settings mapViewport

        model =
            { suggest = suggestModel
            , mapViewport = mapViewport
            , userLocation = userLocation
            , results = Nothing
            , d = Debounce.init
            }
    in
        model
            ! [ searchAllFacilitiesStartingFrom mapViewport.center
              , Map.removeHighlightedFacilityMarker
              , Map.fitContentUsingPadding False
              , Cmd.map (Private << SuggestMsg) suggestCmd
              ]


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Private msg ->
            case msg of
                SuggestMsg msg ->
                    case msg of
                        Suggest.FacilityClicked facilityId ->
                            Return.singleton model
                                |> perform (FacilityClicked facilityId)

                        Suggest.ServiceClicked serviceId ->
                            Return.singleton model
                                |> perform (ServiceClicked serviceId)

                        Suggest.LocationClicked locationId ->
                            Return.singleton model
                                |> perform (LocationClicked locationId)

                        Suggest.Search search ->
                            Return.singleton model
                                |> perform (Search search)

                        Suggest.UnhandledError msg ->
                            Return.singleton model
                                |> perform (UnhandledError msg)

                        _ ->
                            Suggest.update { mapViewport = model.mapViewport } msg model.suggest
                                |> mapBoth (Private << SuggestMsg) (setSuggest model)

                ApiSearch initial (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            if initial then
                                Map.resetFacilityMarkers results.items False
                            else
                                Map.addFacilityMarkers results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << (ApiSearch False)) results
                            else
                                Cmd.none

                        updatedModel =
                            if initial then
                                { model | results = Just results }
                            else
                                -- TODO: incorporate other pages' results
                                model
                    in
                        updatedModel ! [ loadMore, addFacilities ]

                ApiSearch _ (Api.SearchFailed e) ->
                    Return.singleton model
                        |> perform (UnhandledError (toString e))

                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( { model | mapViewport = mapViewport }, debCmd (Private PerformSearch) )

                MapMsg _ ->
                    ( model, Cmd.none )

                UserLocationMsg msg ->
                    UserLocation.update s msg model.userLocation
                        |> mapBoth (Private << UserLocationMsg) (\m -> { model | userLocation = m })

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


setSuggest : Model -> Suggest.Model -> Model
setSuggest model s =
    { model | suggest = s }


view : Model -> MapView Msg
view model =
    { headerClasses = []
    , content =
        Layout.contentWithTopBar
            (suggestionInput model)
            (suggestionsBody model)
    , expandedContent =
        Suggest.expandedView model.suggest
            |> Layout.mapExpandedView (Private << SuggestMsg)
            |> Just
    , toolbar = [ userLocationView model ]
    , bottom = []
    , modal = Shared.lmap (Private << SuggestMsg) (Suggest.mobileAdvancedSearch model.suggest)
    }


suggestionInput model =
    Html.App.map (Private << SuggestMsg) (Suggest.viewInput model.suggest)


suggestionsBody model =
    Shared.lmap (Private << SuggestMsg) (Suggest.viewBody model.suggest)


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.view model.userLocation)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map (Private << MapMsg) Map.subscriptions
        , Sub.map (Private << SuggestMsg) Suggest.subscriptions
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
    Api.search (Private << ApiSearch True) { emptySearch | latLng = Just latLng }
