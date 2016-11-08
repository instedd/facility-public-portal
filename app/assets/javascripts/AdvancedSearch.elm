module AdvancedSearch
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , subscriptions
        , view
        , isEmpty
        )

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as Json
import Selector
import Models exposing (SearchSpec, Service, FacilityType, Ownership, Location, emptySearch)
import Return exposing (Return)
import Shared exposing (onClick)


type alias Model =
    { facilityTypes : List FacilityType
    , ownerships : List Ownership
    , q : Maybe String
    , service : Maybe Int
    , fType : Maybe Int
    , ownership : Maybe Int
    , locationSelector : Selector.Model Location
    , serviceSelector : Selector.Model Service
    }


type Msg
    = Toggle
    | Perform SearchSpec
    | Private PrivateMsg


type PrivateMsg
    = SetName String
    | SetType Int
    | SetOwnership Int
    | LocationSelectorMsg Selector.Msg
    | ServiceSelectorMsg Selector.Msg
    | HideSelectors


init : List FacilityType -> List Ownership -> List Location -> List Service -> SearchSpec -> Model
init facilityTypes ownerships locations services search =
    { facilityTypes = facilityTypes
    , ownerships = ownerships
    , q = search.q
    , service = search.service
    , fType = search.fType
    , ownership = search.ownership
    , locationSelector = Selector.init "location-input" locations .id .name search.location
    , serviceSelector = Selector.init "service-input" services .id .name search.service
    }


update : Model -> Msg -> Return Msg Model
update model msg =
    case msg of
        Private (SetName q) ->
            Return.singleton { model | q = Just q }

        Private (SetType fType) ->
            Return.singleton { model | fType = Just fType }

        Private (SetOwnership o) ->
            Return.singleton { model | ownership = Just o }

        Private (LocationSelectorMsg msg) ->
            Selector.update msg model.locationSelector
                |> Return.mapBoth (Private << LocationSelectorMsg) (\m -> { model | locationSelector = m })

        Private (ServiceSelectorMsg msg) ->
            Selector.update msg model.serviceSelector
                |> Return.mapBoth (Private << ServiceSelectorMsg) (\m -> { model | serviceSelector = m })

        Private HideSelectors ->
            Return.singleton
                { model
                    | locationSelector = Selector.close model.locationSelector
                    , serviceSelector = Selector.close model.serviceSelector
                }

        _ ->
            -- Public events
            Return.singleton model


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ Sub.map (Private << LocationSelectorMsg) Selector.subscriptions
        , Sub.map (Private << ServiceSelectorMsg) Selector.subscriptions
        ]


view : Model -> List (Html Msg)
view model =
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
        Shared.modalWindow
            [ text "Advanced Search"
            , a [ href "#", class "right", onClick Toggle ] [ Shared.icon "close" ]
            ]
            [ Html.form [ action "#", method "GET" ]
                [ field
                    [ label [ for "q" ] [ text "Facility name" ]
                    , input [ id "q", type' "text", value query, onInput (Private << SetName) ] []
                    ]
                , field
                    [ label [] [ text "Facility type" ]
                    , Html.select [ Shared.onSelect (Private << SetType) ] (selectOptions model.facilityTypes model.fType)
                    ]
                , field
                    [ label [] [ text "Ownership" ]
                    , Html.select [ Shared.onSelect (Private << SetOwnership) ] (selectOptions model.ownerships model.ownership)
                    ]
                , field
                    [ label [] [ text "Location" ]
                    , Html.App.map (Private << LocationSelectorMsg) (Selector.view viewLocation model.locationSelector)
                    ]
                , field
                    [ label [] [ text "Service" ]
                    , Html.App.map (Private << ServiceSelectorMsg) (Selector.view viewService model.serviceSelector)
                    ]
                ]
            ]
            [ a
                [ href "#"
                , class "btn-flat"
                , hideSelectorsOnFocus
                , onClick (Perform (search model))
                ]
                [ text "Search" ]
            ]


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
    }


selectOptions : List { id : Int, name : String } -> Maybe Int -> List (Html a)
selectOptions options choice =
    let
        selectedId =
            Maybe.withDefault 0 choice
    in
        [ Html.option [ value "0" ] [ text "" ] ]
            ++ (List.map
                    (\option ->
                        Html.option
                            [ value (toString option.id), selected (option.id == selectedId) ]
                            [ text option.name ]
                    )
                    options
               )


isEmpty : Model -> Bool
isEmpty model =
    Models.isEmpty (search model)
