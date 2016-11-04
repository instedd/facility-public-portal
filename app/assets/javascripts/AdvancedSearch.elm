module AdvancedSearch exposing (Model, Msg(..), PrivateMsg, init, update, subscriptions, view)

import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Models exposing (SearchSpec, FacilityType, Ownership, Location, emptySearch, setType, setQuery, setOwnership)
import Return exposing (Return)
import Shared
import LocationSelector


type alias Model =
    { facilityTypes : List FacilityType
    , ownerships : List Ownership
    , q : Maybe String
    , fType : Maybe Int
    , ownership : Maybe Int
    , selector : LocationSelector.Model
    }


type Msg
    = Toggle
    | Perform SearchSpec
    | Private PrivateMsg


type PrivateMsg
    = SetName String
    | SetType Int
    | SetOwnership Int
    | SelectorMsg LocationSelector.Msg


init : List FacilityType -> List Ownership -> List Location -> Model
init facilityTypes ownerships locations =
    { facilityTypes = facilityTypes
    , ownerships = ownerships
    , q = Nothing
    , fType = Nothing
    , ownership = Nothing
    , selector = LocationSelector.init locations
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

        Private (SelectorMsg msg) ->
            LocationSelector.update msg model.selector
                |> Return.mapBoth (Private << SelectorMsg) (\m -> { model | selector = m })

        _ ->
            -- To be handled by host page
            Return.singleton model


subscriptions : Sub Msg
subscriptions =
    Sub.map (Private << SelectorMsg) LocationSelector.subscriptions


view : Model -> List (Html Msg)
view model =
    let
        query =
            Maybe.withDefault "" model.q
    in
        Shared.modalWindow
            [ text "Advanced Search"
            , a [ href "#", class "right", Shared.onClick Toggle ] [ Shared.icon "close" ]
            ]
            [ Html.form [ action "#", method "GET" ]
                [ label [ for "q" ] [ text "Facility name" ]
                , input [ id "q", type' "text", value query, onInput (Private << SetName) ] []
                , label [] [ text "Facility type" ]
                , Html.select [ Shared.onSelect (Private << SetType) ] (selectOptions model.facilityTypes model.fType)
                , label [] [ text "Ownership" ]
                , Html.select [ Shared.onSelect (Private << SetOwnership) ] (selectOptions model.ownerships model.ownership)
                , label [] [ text "Location" ]
                , Html.App.map (Private << SelectorMsg) (LocationSelector.view model.selector)
                ]
            ]
            [ a [ href "#", class "btn-flat", Shared.onClick (Perform (search model)) ] [ text "Search" ] ]


search : Model -> SearchSpec
search model =
    { emptySearch
        | q = model.q
        , location = Maybe.map .id model.selector.selectedLocation
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
