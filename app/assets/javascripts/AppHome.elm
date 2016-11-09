module AppHome exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api
import Html.App
import Map
import Models exposing (Settings, MapViewport, LatLng, SearchResult, FacilityType, Ownership, SearchSpec, shouldLoadMore, emptySearch)
import Shared exposing (MapView)
import Utils exposing (perform)
import UserLocation
import Suggest
import Debounce
import Return exposing (..)


type alias Model =
    { suggest : Suggest.Model
    , mapViewport : MapViewport
    , userLocation : UserLocation.Model
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
    | UnhandledError
    | Search SearchSpec


init : Settings -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init settings mapViewport userLocation =
    let
        ( suggestModel, suggestCmd ) =
            Suggest.empty settings

        model =
            { suggest = suggestModel
            , mapViewport = mapViewport
            , userLocation = userLocation
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

                        Suggest.UnhandledError ->
                            Return.singleton model
                                |> perform UnhandledError

                        _ ->
                            Suggest.update { mapViewport = model.mapViewport } msg model.suggest
                                |> mapBoth (Private << SuggestMsg) (setSuggest model)

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
                    Return.singleton model
                        |> perform UnhandledError

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
    { headerClass = ""
    , content = suggestionInput model :: (suggestionItems model)
    , toolbar = [ userLocationView model ]
    , bottom = []
    , modal = List.map (Html.App.map (Private << SuggestMsg)) (Suggest.advancedSearchWindow model.suggest)
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
    Api.search (Private << (ApiSearch True)) { emptySearch | latLng = Just latLng }
