module AdvancedSearch exposing (Model, Msg(..), PrivateMsg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Models exposing (SearchSpec, FacilityType, Ownership, Location, setType, setQuery, setOwnership)
import Return exposing (Return)
import Shared


type alias Model =
    { search : SearchSpec }


type Msg
    = Toggle
    | Perform SearchSpec
    | Private PrivateMsg


type PrivateMsg
    = SetName String
    | SetType Int
    | SetOwnership Int


init : Model
init =
    { search = Models.emptySearch }


update : Model -> Msg -> Return Msg Model
update model msg =
    case msg of
        Private (SetName q) ->
            model
                |> updateSearch setQuery q
                |> Return.singleton

        Private (SetType fType) ->
            model
                |> updateSearch setType fType
                |> Return.singleton

        Private (SetOwnership o) ->
            model
                |> updateSearch setOwnership o
                |> Return.singleton

        _ ->
            -- To be handled by host page
            Return.singleton model


updateSearch : (a -> SearchSpec -> SearchSpec) -> a -> Model -> Model
updateSearch f x model =
    { model | search = f x model.search }


view : Model -> List FacilityType -> List Ownership -> List (Html Msg)
view model types ownerships =
    let
        search =
            model.search

        query =
            Maybe.withDefault "" search.q
    in
        Shared.modalWindow
            [ text "Advanced Search"
            , a [ href "#", class "right", Shared.onClick Toggle ] [ Shared.icon "close" ]
            ]
            [ Html.form [ action "#", method "GET" ]
                [ label [ for "q" ] [ text "Facility name" ]
                , input [ id "q", type' "text", value query, onInput (Private << SetName) ] []
                , label [] [ text "Facility type" ]
                , Html.select [ Shared.onSelect (Private << SetType) ] (selectOptions types search.fType)
                , label [] [ text "Ownership" ]
                , Html.select [ Shared.onSelect (Private << SetOwnership) ] (selectOptions ownerships search.ownership)
                ]
            ]
            [ a [ href "#", class "btn-flat", Shared.onClick (Perform search) ] [ text "Search" ] ]


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
