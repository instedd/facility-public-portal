module AppSearch exposing (Model, Msg(..), PrivateMsg, init, restoreCmd, view, update, subscriptions, mapViewport, userLocation)

import Api
import Map
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events as Events
import Models exposing (Settings, MapViewport, SearchSpec, SearchResult, Facility, LatLng, FacilitySummary, shouldLoadMore)
import Shared exposing (MapView, icon, classNames)
import Utils exposing (mapTCmd)
import UserLocation
import Suggest
import Debounce


type alias Model =
    { suggest : Suggest.Model, query : SearchSpec, mapViewport : MapViewport, userLocation : UserLocation.Model, results : Maybe SearchResult, mobileFocusMap : Bool, d : Debounce.State, advancedSearch : Maybe AdvancedSearch }


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
    | ToggleAdvancedSearch


type Msg
    = FacilityClicked Int
    | ServiceClicked Int
    | LocationClicked Int
    | Search SearchSpec
    | ClearSearch
    | Private PrivateMsg
    | UnhandledError


type alias AdvancedSearch =
    { name: String, facilityType: String }


restoreCmd : Cmd Msg
restoreCmd =
    Cmd.batch [ Map.removeHighlightedFacilityMarker, Map.fitContentUsingPadding True ]


init : Settings -> SearchSpec -> MapViewport -> UserLocation.Model -> Maybe AdvancedSearch -> ( Model, Cmd Msg )
init s query mapViewport userLocation advancedSearch =
    { suggest = Suggest.init (queryText query), query = query, mapViewport = mapViewport, userLocation = userLocation, results = Nothing, mobileFocusMap = True, d = Debounce.init, advancedSearch = Nothing }
        ! [ Api.search (Private << ApiSearch) { query | latLng = Just mapViewport.center }
          , restoreCmd
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
                            Map.resetFacilityMarkers results.items

                        loadMore =
                            if shouldLoadMore results model.mapViewport then
                                Api.searchMore (Private << ApiSearchMore) results
                            else
                                Cmd.none
                    in
                        { model | results = Just results }
                            ! [ loadMore, Map.fitContent, addFacilities ]

                ApiSearch (Api.SearchFailed _) ->
                    ( model, Utils.performMessage UnhandledError )

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

                ApiSearchMore _ ->
                    ( model, Utils.performMessage UnhandledError )

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

                Deb a ->
                    Debounce.update cfg a model

                ToggleAdvancedSearch ->
                    if not (isAdvancedSearchOpen model) then
                        ( { model | advancedSearch = Just { name = "", facilityType = "" } }, Cmd.none )
                    else
                        ( { model | advancedSearch = Nothing }, Cmd.none )

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
    let
        onlyMobile =
            ( "hide-on-large-only", True )

        hideOnMobileMapFocused =
            ( "hide-on-med-and-down", model.mobileFocusMap )

        hideOnMobileListingFocused =
            ( "hide-on-med-and-down", not model.mobileFocusMap )

        hideOnSuggestions =
            ( "hide", Suggest.hasSuggestionsToShow model.suggest )

        content =
            ( "content", True )
    in
        { headerClass = classNames [ hideOnMobileListingFocused ]
        , content =
            [ div
                [ classList [ onlyMobile, hideOnMobileMapFocused ] ]
                [ mobileBackHeader ]
            , suggestionInput model
            , div
                [ classList [ hideOnSuggestions, hideOnMobileMapFocused, content ] ]
                [ searchResults model ]
            ]
                ++ suggestionItems model
                ++ advancedSearchFooter
        , toolbar =
            [ userLocationView model ]
        , bottom =
            [ div
                [ classList [ hideOnMobileListingFocused ] ]
                [ mobileFocusToggleView ]
            ]
        , modal = advancedSearchWindow model
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


advancedSearchFooter : List (Html Msg)
advancedSearchFooter =
    [ div
        [ class "footer" ]
        [ a [ href "#", Shared.onClick (Private ToggleAdvancedSearch) ] [ text "Advanced Search" ] ]
    ]


isAdvancedSearchOpen : Model -> Bool
isAdvancedSearchOpen model =
    case model.advancedSearch of
        Nothing ->
            False
        _ ->
            True


advancedSearchWindow : Model -> List (Html Msg)
advancedSearchWindow model =
    if isAdvancedSearchOpen model then
        Shared.modalWindow
            [ text "Advanced Search"
            , a [ href "#", class "right", Shared.onClick (Private ToggleAdvancedSearch) ] [ Shared.icon "close" ]
            ]
            [ Html.form [ action "#", method "GET" ]
                [ text "Facility name"
                , input [ type' "text" ] []
                , text "Facility type"
                , Html.select [] [ Html.option [] [ text "Medium Clinic" ]
                                , Html.option [] [ text "Referral Hospital" ]
                                , Html.option [] [ text "Health Post" ] ]
                ]
            ]
            [ a [ href "#", class "btn-flat", Shared.onClick (Private ToggleAdvancedSearch) ] [ text "Search" ] ]
    else
        []

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
