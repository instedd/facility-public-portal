module AppSearch exposing (Model, Msg(..), PrivateMsg, init, view, update, subscriptions, mapViewport, userLocation)

import Api
import Map
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Models exposing (Settings, MapViewport, SearchSpec, SearchResult, Facility, LatLng, shouldLoadMore)
import Shared exposing (icon)
import Utils exposing (mapTCmd)
import UserLocation
import Suggest


type alias Model =
    { suggest : Suggest.Model, query : SearchSpec, mapViewport : MapViewport, userLocation : UserLocation.Model, results : Maybe SearchResult, mobileFocusMap : Bool }


type PrivateMsg
    = ApiSearch Api.SearchMsg
      -- ApiSearchMore will keep markers of map. Used for load more and for map panning
    | ApiSearchMore Api.SearchMsg
    | UserLocationMsg UserLocation.Msg
    | MapMsg Map.Msg
    | SuggestMsg Suggest.Msg
    | ToggleMobileFocus


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search SearchSpec
    | Private PrivateMsg


init : Settings -> SearchSpec -> MapViewport -> UserLocation.Model -> ( Model, Cmd Msg )
init s query mapViewport userLocation =
    { suggest = Suggest.init (queryText query), query = query, mapViewport = mapViewport, userLocation = userLocation, results = Nothing, mobileFocusMap = True }
        ! [ Api.search (Private << ApiSearch) { query | latLng = Just mapViewport.center }
          , Map.removeHighlightedFacilityMarker
          ]


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

                UserLocationMsg msg ->
                    mapTCmd (\m -> { model | userLocation = m }) (Private << UserLocationMsg) <|
                        UserLocation.update s msg model.userLocation

                SuggestMsg msg ->
                    case msg of
                        Suggest.FacilityClicked facilityId ->
                            ( model, Utils.performMessage (FacilityClicked facilityId) )

                        Suggest.ServiceClicked serviceId ->
                            ( model, Utils.performMessage (ServiceClicked serviceId) )

                        Suggest.LocationClicked locationId ->
                            ( model, Utils.performMessage (LocationClicked locationId) )

                        Suggest.Search q ->
                            ( model, Utils.performMessage (Search <| { q = Just q, s = Nothing, l = Nothing, latLng = Nothing }) )

                        _ ->
                            wrapSuggest model <| Suggest.update { mapViewport = model.mapViewport } msg model.suggest

                ToggleMobileFocus ->
                    ( { model | mobileFocusMap = (not model.mobileFocusMap) }, Cmd.none )

        _ ->
            -- public events
            ( model, Cmd.none )


wrapSuggest : Model -> ( Suggest.Model, Cmd Suggest.Msg ) -> ( Model, Cmd Msg )
wrapSuggest model =
    mapTCmd (\s -> { model | suggest = s }) (Private << SuggestMsg)


view : Model -> Html Msg
view model =
    let
        onlyMobile =
            ( "hide-on-med-and-up", True )

        hideOnMobileMapFocused =
            ( "hide-on-small-only", model.mobileFocusMap )

        hideOnMobileListingFocused =
            ( "hide-on-small-only", not model.mobileFocusMap )

        hideOnSuggestions =
            ( "hide", Suggest.hasSuggestionsToShow model.suggest )
    in
        div []
            [ Shared.controlStack
                ([ div [ classList [ hideOnMobileListingFocused ] ] [ Shared.header ]
                 , div
                    [ classList [ onlyMobile, hideOnMobileMapFocused ] ]
                    [ mobileBackHeader ]
                 , suggestionInput model
                 , div
                    [ classList [ hideOnSuggestions, hideOnMobileMapFocused ] ]
                    [ searchResults model ]
                 ]
                    ++ suggestionItems model
                )
            , div
                [ classList [ hideOnMobileListingFocused, onlyMobile ] ]
                [ mobileFocusToggleView ]
            , userLocationView model
            ]


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
    Html.App.map (Private << SuggestMsg) (Suggest.viewInput model.suggest)


suggestionItems model =
    (List.map (Html.App.map (Private << SuggestMsg)) (Suggest.viewSuggestions model.suggest))


userLocationView model =
    div [ class "floating-actions" ]
        [ Html.App.map (Private << UserLocationMsg) (UserLocation.viewMapControl model.userLocation)
        ]


mobileFocusToggleView =
    a
        [ href "#!"
        , id "bottom-action"
        , class "z-depth-1"
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
        div [ class "collection results content" ] entries


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
