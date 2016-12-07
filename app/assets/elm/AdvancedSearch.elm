module AdvancedSearch
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , subscriptions
        , embeddedView
        , modalView
        , isEmpty
        , search
        , sorting
        , updateSorting
        )

import Api
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import I18n exposing (..)
import Json.Decode as Json
import Models exposing (SearchSpec, Service, FacilityType, Ownership, Location, Sorting(..), emptySearch)
import Return exposing (Return)
import Selector
import Shared exposing (onClick)
import Utils exposing (perform)


type alias Model =
    { facilityTypes : List FacilityType
    , ownerships : List Ownership
    , q : Maybe String
    , service : Maybe Int
    , fType : Maybe Int
    , ownership : Maybe Int
    , sort : Maybe Sorting
    , locationSelector : Selector.Model Location
    , serviceSelector : Selector.Model Service
    }


type Msg
    = Toggle
    | Perform SearchSpec
    | Private PrivateMsg
    | UnhandledError String


type PrivateMsg
    = SetName String
    | SetType (Maybe Int)
    | SetOwnership (Maybe Int)
    | LocationSelectorMsg Selector.Msg
    | ServiceSelectorMsg Selector.Msg
    | HideSelectors
    | LocationsFetched (Maybe Int) (List Location)
    | ServicesFetched (Maybe Int) (List Service)
    | FetchFailed Http.Error


init : List FacilityType -> List Ownership -> SearchSpec -> Return Msg Model
init facilityTypes ownerships search =
    Return.singleton
        { facilityTypes = facilityTypes
        , ownerships = ownerships
        , q = search.q
        , service = search.service
        , fType = search.fType
        , ownership = search.ownership
        , sort = search.sort
        , locationSelector = initLocations [] Nothing
        , serviceSelector = initServices [] Nothing
        }
        |> Return.command (fetchLocations search.location)
        |> Return.command (fetchServices search.service)


initLocations : List Location -> Maybe Int -> Selector.Model Location
initLocations locations selection =
    Selector.init locationInputId locations .id .name selection


initServices : List Service -> Maybe Int -> Selector.Model Service
initServices services selection =
    Selector.init serviceInputId services .id .name selection


fetchLocations : Maybe Int -> Cmd Msg
fetchLocations selection =
    Api.getLocations (Private << FetchFailed) (Private << (LocationsFetched selection))


fetchServices : Maybe Int -> Cmd Msg
fetchServices selection =
    Api.getServices (Private << FetchFailed) (Private << (ServicesFetched selection))


update : Model -> Msg -> Return Msg Model
update model msg =
    case msg of
        Private msg ->
            case msg of
                SetName q ->
                    Return.singleton { model | q = Just q }

                SetType fType ->
                    Return.singleton { model | fType = fType }

                SetOwnership o ->
                    Return.singleton { model | ownership = o }

                LocationSelectorMsg msg ->
                    Selector.update msg model.locationSelector
                        |> Return.mapBoth (Private << LocationSelectorMsg) (\m -> { model | locationSelector = m })

                ServiceSelectorMsg msg ->
                    Selector.update msg model.serviceSelector
                        |> Return.mapBoth (Private << ServiceSelectorMsg) (\m -> { model | serviceSelector = m })

                HideSelectors ->
                    Return.singleton
                        { model
                            | locationSelector = Selector.close model.locationSelector
                            , serviceSelector = Selector.close model.serviceSelector
                        }

                LocationsFetched selectedId locations ->
                    Return.singleton
                        { model | locationSelector = initLocations locations selectedId }

                ServicesFetched selectedId services ->
                    Return.singleton
                        { model | serviceSelector = initServices services selectedId }

                FetchFailed e ->
                    Return.singleton model
                        |> perform (UnhandledError (toString e))

        _ ->
            -- Public events
            Return.singleton model


sorting : Model -> Sorting
sorting model =
    Maybe.withDefault Models.Distance model.sort


updateSorting : Sorting -> Model -> ( Model, Cmd Msg )
updateSorting sort model =
    let
        updatedModel =
            { model | sort = Just sort }
    in
        Return.singleton updatedModel
            |> Utils.perform (Perform <| search updatedModel)


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Sub.map (Private << LocationSelectorMsg) Selector.subscriptions
        , Sub.map (Private << ServiceSelectorMsg) Selector.subscriptions
        ]


modalView : Model -> List (Html Msg)
modalView model =
    [ Html.form
        [ class "advanced-search"
        , action "#"
        , method "GET"
        , Html.Events.onSubmit (Perform (search model))
        ]
      <|
        Shared.modalWindow
            [ text <| t AdvancedSearch, a [ href "#", class "right", onClick Toggle ] [ Shared.icon "close" ] ]
            (fields model)
            [ submit model ]
    ]


embeddedView : Model -> List (Html Msg)
embeddedView model =
    [ Html.form
        [ class "advanced-search embedded"
        , action "#"
        , method "GET"
        , Html.Events.onSubmit (Perform (search model))
        ]
        (fields model ++ [ div [ class "submit" ] [ submit model ] ])
    ]


fields : Model -> List (Html Msg)
fields model =
    let
        query =
            Maybe.withDefault "" model.q

        viewLocation location =
            [ Html.text location.name
            , Html.span [ class "autocomplete-item-context" ] [ Html.text (Maybe.withDefault "" location.parentName) ]
            ]

        viewService service =
            [ Html.text service.name ]
    in
        [ field
            [ label [ for "q" ] [ text <| t I18n.FacilityName ]
            , input [ id "q", type' "text", value query, onInput (Private << SetName) ] []
            ]
        , field
            [ label [ for "t" ] [ text <| t I18n.FacilityType ]
            , select "t" (Private << SetType) model.facilityTypes model.fType
            ]
        , field
            [ label [ for "o" ] [ text <| t I18n.Ownership ]
            , select "o" (Private << SetOwnership) model.ownerships model.ownership
            ]
        , field
            [ label [ for locationInputId ] [ text <| t I18n.Location ]
            , Html.App.map (Private << LocationSelectorMsg) (Selector.view "" viewLocation model.locationSelector)
            ]
        , field
            [ label [ for serviceInputId ] [ text <| t I18n.Service ]
            , Html.App.map (Private << ServiceSelectorMsg) (Selector.view "pull-up" viewService model.serviceSelector)
            ]
        ]


submit : Model -> Html Msg
submit model =
    Html.button
        [ class "btn-flat"
        , hideSelectorsOnFocus
        , onClick (Perform (search model))
        , type' "submit"
        ]
        [ text <| t Search ]


select : String -> (Maybe Int -> Msg) -> List { id : Int, name : String } -> Maybe Int -> Html Msg
select domId tagger options choice =
    let
        selectedId =
            Maybe.withDefault 0 choice

        toMaybe id =
            if id == 0 then
                Nothing
            else
                Just id

        clearOption =
            Html.option [ value "0" ] [ text "" ]

        selectOption option =
            Html.option
                [ value (toString option.id), selected (option.id == selectedId) ]
                [ text option.name ]
    in
        Html.select [ Shared.onSelect (toMaybe >> tagger) ] <|
            clearOption
                :: (List.map selectOption options)


field : List (Html Msg) -> Html Msg
field content =
    div
        [ class "field", hideSelectorsOnFocus ]
        content


hideSelectorsOnFocus =
    Html.Events.on "focusin" (Json.succeed <| Private HideSelectors)


search : Model -> SearchSpec
search model =
    { emptySearch
        | q = model.q
        , service = Maybe.map .id model.serviceSelector.selection
        , location = Maybe.map .id model.locationSelector.selection
        , fType = model.fType
        , ownership = model.ownership
        , sort = model.sort
    }


isEmpty : Model -> Bool
isEmpty model =
    Models.isEmpty (search model)


locationInputId =
    "location-input"


serviceInputId =
    "service-input"
