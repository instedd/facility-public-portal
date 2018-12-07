port module MainDatasets exposing (Model, Msg, init, main, subscriptions, update, view)

import Dataset exposing (Dataset, Event(..), FileState, ImportStartResult, eventDecoder, importDataset)
import Dict exposing (Dict)
import Html exposing (Html, a, div, h1, p, pre, span, text)
import Html.App
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (decodeValue)
import Json.Encode
import Process
import Task


type alias Model =
    { dataset : Dataset
    , importState : Maybe ImportState
    }


type alias ImportState =
    { processId : String
    , log : List String
    }


type alias ImportLog =
    { processId : String
    , log : String
    }


type Msg
    = DatasetEvent (Result String Dataset.Event)
    | ImportClicked
    | ImportStarted (Result Http.Error ImportStartResult)
    | ImportFinished


port datasetEvent : (Json.Decode.Value -> msg) -> Sub msg


main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : ( Model, Cmd Msg )
init =
    { dataset = Dict.empty, importState = Nothing } ! []


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Dataset" ]
        , p []
            [ text "Drop your files here to update the dataset."
            , text "You could also import ONA files."
            , text "You'll be able to review before new data is deployed."
            ]
        , case model.importState of
            Nothing ->
                datasetView model.dataset

            Just importState ->
                importView importState
        , div [ class "actions right-align" ]
            [ a
                [ class "btn btn-large"
                , onClick ImportClicked
                ]
                [ text "Preview" ]
            ]
        ]


datasetView : Dataset -> Html msg
datasetView dataset =
    dataset
        |> Dict.toList
        |> List.map fileView
        |> div []


importView : ImportState -> Html msg
importView importState =
    pre [] (importState.log |> List.map text)


fileView : ( String, Maybe FileState ) -> Html msg
fileView ( name, state ) =
    div [] [ text name ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DatasetEvent result ->
            case result of
                Ok (DatasetUpdated dataset) ->
                    { model | dataset = dataset } ! []

                Ok (ImportLog log) ->
                    case model.importState of
                        Just importState ->
                            { model | importState = Just { importState | log = importState.log ++ [ log.log ] } } ! []

                        _ ->
                            model ! []

                Ok (ImportComplete result) ->
                    model ! [ delayMessage 1000 ImportFinished ]

                Err message ->
                    Debug.crash message

        ImportClicked ->
            model ! [ importDataset ImportStarted ]

        ImportStarted result ->
            case result of
                Ok result ->
                    { model | importState = Just { processId = result.processId, log = [] } }
                        ! []

                Err _ ->
                    model ! []

        ImportFinished ->
            { model | importState = Nothing } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    datasetEvent (decodeValue Dataset.eventDecoder >> DatasetEvent)


delayMessage : Float -> msg -> Cmd msg
delayMessage delay msg =
    let
        handler =
            always msg
    in
    Process.sleep delay
        |> Task.perform handler handler
