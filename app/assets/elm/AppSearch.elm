module AppSearch exposing (Model, Msg(..), PrivateMsg, init, restoreCmd, view, update, subscriptions, mapViewport, userLocation)

import Api
import Map
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Models exposing (Settings, MapViewport, SearchSpec, SearchResult, Facility, LatLng, FacilitySummary, FacilityType, Ownership, shouldLoadMore, emptySearch)
import Shared exposing (MapView, icon, classNames)
import Utils exposing (perform)
import UserLocation
import Suggest
import Debounce
import Return exposing (..)


type alias Model =
    { suggest : Suggest.Model
    , query : SearchSpec
    , mapViewport : MapViewport
    , userLocation : UserLocation.Model
    , results : Maybe SearchResult
    , mobileFocusMap : Bool
    , d : Debounce.State
    }


type PrivateMsg
    = ApiSearch Api.SearchMsg
      -- ApiSearchMore will keep markers of map. Used for load more and for map panning
    | ApiSearchMore Api.SearchMsg
    | UserLocationMsg UserLocation.Msg
    | MapMsg Map.Msg
    | SuggestMsg Suggest.Msg
    | ToggleMobileFocus
    | Deb (Debounce.Msg Msg)
    | PerformSearch


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search SearchSpec
    | ClearSearch
    | Private PrivateMsg
    | UnhandledError String


restoreCmd : Cmd Msg
restoreCmd =
    Cmd.batch [ Map.removeHighlightedFacilityMarker, Map.fitContentUsingPadding True ]


init : Settings -> SearchSpec -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init s query mapViewport userLocation =
    let
        ( suggestModel, suggestCmd ) =
            Suggest.init s query

        model =
            { suggest = suggestModel
            , query = query
            , mapViewport = mapViewport
            , userLocation = userLocation
            , results = Nothing
            , mobileFocusMap = True
            , d = Debounce.init
            }
    in
        model
            ! [ Api.search (Private << ApiSearch) { query | latLng = Just mapViewport.center }
              , restoreCmd
              , Cmd.map (Private << SuggestMsg) suggestCmd
              ]


update : Settings -> Msg -> Model -> ( Model, Cmd Msg )
update s msg model =
    case msg of
        Private msg ->
            case msg of
                MapMsg (Map.MapViewportChanged mapViewport) ->
                    ( { model | mapViewport = mapViewport }, debCmd (Private PerformSearch) )

                PerformSearch ->
                    let
                        query =
                            model.query

                        loadMore =
                            Api.search (Private << ApiSearchMore) { query | latLng = Just model.mapViewport.center }
                    in
                        ( model, loadMore )

                MapMsg _ ->
                    ( model, Cmd.none )

                ApiSearch (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            Map.resetFacilityMarkers results.items True

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << ApiSearchMore) results
                            else
                                Cmd.none
                    in
                        { model | results = Just results }
                            ! [ loadMore, addFacilities ]

                ApiSearch (Api.SearchFailed e) ->
                    Return.singleton model
                        |> perform (UnhandledError (toString e))

                ApiSearchMore (Api.SearchSuccess results) ->
                    let
                        addFacilities =
                            Map.addFacilityMarkers results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << ApiSearchMore) results
                            else
                                Cmd.none
                    in
                        -- TODO append/merge or replace results items to current results. The order might not be trivial
                        model ! [ loadMore, addFacilities ]

                ApiSearchMore (Api.SearchFailed e) ->
                    Return.singleton model
                        |> perform (UnhandledError (toString e))

                UserLocationMsg msg ->
                    UserLocation.update s msg model.userLocation
                        |> mapBoth (Private << UserLocationMsg) (setUserLocation model)

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
                                |> perform (Search <| search)

                        Suggest.UnhandledError msg ->
                            Return.singleton model
                                |> perform (UnhandledError msg)

                        _ ->
                            Suggest.update { mapViewport = model.mapViewport } msg model.suggest
                                |> mapBoth (Private << SuggestMsg) (setSuggest model)

                ToggleMobileFocus ->
                    ( { model | mobileFocusMap = (not model.mobileFocusMap) }, Cmd.none )

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


setUserLocation : Model -> UserLocation.Model -> Model
setUserLocation model l =
    { model | userLocation = l }


setSuggest : Model -> Suggest.Model -> Model
setSuggest model s =
    { model | suggest = s }


view : Model -> MapView Msg
view model =
    let
        anySuggestion =
            Suggest.hasSuggestionsToShow model.suggest

        onlyMobile =
            ( "hide-on-large-only", True )

        hideOnMobileMapFocused =
            ( "hide-on-med-and-down", model.mobileFocusMap )

        hideOnMobileListingFocused =
            ( "hide-on-med-and-down", not model.mobileFocusMap )

        hideOnSuggestions =
            ( "hide", anySuggestion )
    in
        { headerClass = classNames [ hideOnMobileListingFocused ]
        , content =
            [ div
                [ classList [ onlyMobile, hideOnMobileMapFocused ] ]
                [ mobileBackHeader ]
            , suggestionInput model
            , div
                [ classList [ hideOnSuggestions, hideOnMobileMapFocused, ( "content expand", True ) ] ]
                [ searchResults model ]
            ]
                ++ suggestionItems model
        , toolbar =
            [ userLocationView model ]
        , bottom =
            if (model.mobileFocusMap && not anySuggestion) then
                [ mobileFocusToggleView ]
            else
                []
        , modal = List.map (Html.App.map (Private << SuggestMsg)) (Suggest.advancedSearchWindow model.suggest)
        }


mobileBackHeader =
    nav [ id "TopNav", class "z-depth-0" ]
        [ a
            [ href "#!"
            , class "nav-back"
            , Shared.onClick (Private ToggleMobileFocus)
            ]
            [ Shared.icon "arrow_back"
            , span [] [ text "Search Results" ]
            ]
        ]


suggestionInput model =
    let
        close =
            a [ href "#", Shared.onClick ClearSearch ] [ icon "close" ]
    in
        Suggest.viewInputWith (Private << SuggestMsg) model.suggest close


suggestionItems model =
    (List.map (Html.App.map (Private << SuggestMsg)) (Suggest.viewSuggestions model.suggest))


userLocationView model =
    Html.App.map (Private << UserLocationMsg) (UserLocation.view model.userLocation)


mobileFocusToggleView =
    a
        [ href "#"
        , Shared.onClick (Private ToggleMobileFocus)
        ]
        [ text "List results" ]


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


searchResults : Model -> Html Msg
searchResults model =
    let
        entries =
            case model.results of
                -- searching
                Nothing ->
                    []

                Just results ->
                    case results.items of
                        [] ->
                            [ div
                                [ class "no-results" ]
                                [ span [ class "search-icon" ] [ icon "find_in_page" ]
                                , text "No results found"
                                ]
                            ]

                        items ->
                            List.map facilityRow items
    in
        div [ class "collection results" ] entries


facilityRow : FacilitySummary -> Html Msg
facilityRow f =
    a
        [ class "collection-item result avatar"
        , Events.onClick <| FacilityClicked f.id
        ]
        [ icon "local_hospital"
        , span [ class "title" ] [ text f.name ]
        , p [ class "sub" ] [ text f.facilityType ]
        ]
