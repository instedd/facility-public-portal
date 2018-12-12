port module MainDatasets exposing (Model, Msg, init, main, subscriptions, update, view)

import Dataset
    exposing
        ( Dataset
        , Event(..)
        , FileState
        , ImportStartResult
        , eventDecoder
        , fileLabel
        , humanReadableFileSize
        , humanReadableFileTimestamp
        , importDataset
        )
import Date exposing (Date)
import Dict exposing (Dict)
import Dom.Scroll exposing (toBottom)
import Html exposing (Html, a, div, h1, p, pre, span, text)
import Html.App
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (decodeValue, string)
import Process
import Spinner exposing (spinner)
import String
import Task
import Time exposing (Time)
import Utils


type alias Model =
    { dataset : Dataset
    , importState : Maybe ImportState
    , currentDate : Maybe Date
    , uploading : Dict String ()
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
    | NoOp
    | DroppedFileEvent (Result String String)
    | CurrentTime Time
    | UploadingFile String
    | UploadedFile String


port datasetEvent : (Json.Decode.Value -> msg) -> Sub msg


port droppedFileEvent : (Json.Decode.Value -> msg) -> Sub msg


port uploadedFile : (String -> msg) -> Sub msg


port uploadingFile : (String -> msg) -> Sub msg


port requestFileUpload : String -> Cmd msg


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
    { dataset = Dict.empty
    , importState = Nothing
    , currentDate = Nothing
    , uploading = Dict.empty
    }
        ! [ Task.perform Utils.notFailing CurrentTime Time.now ]


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
                datasetView model

            Just importState ->
                importView importState
        , div [ class "card-panel actions right-align" ]
            [ a
                [ id "import-button"
                , class "btn btn-large"
                , onClick ImportClicked
                ]
                (case model.importState of
                    Nothing ->
                        [ text "Preview" ]

                    Just _ ->
                        [ spinner [ id "import-spinner" ] Spinner.White ]
                )
            ]
        ]


datasetView : Model -> Html msg
datasetView model =
    model.dataset
        |> Dict.toList
        |> List.map (\(filename, fileState) -> fileView model.currentDate (filename, fileState) (Dict.member filename model.uploading))
        |> div [ class "row" ]


importView : ImportState -> Html msg
importView importState =
    pre [ id "import-log" ] (importState.log |> List.map text)


fileView : Maybe Date -> ( String, Maybe FileState ) -> Bool -> Html msg
fileView currentDate ( name, state ) isUploading =
    div [ class "col m4 s12" ]
        [ div [ class <| appliedClass "card-panel z-depth-0 file-card file-applied" state ]
            [ div [] [ text name ]
            , fileLineView <| fileLabel state humanReadableFileSize
            , fileLineView <| fileLabel state (humanReadableFileTimestamp currentDate)
            , fileLineView <| if isUploading then "Uploading..." else ""
            ]
        ]


appliedClass : String -> Maybe FileState -> String
appliedClass baseClass state =
    case state of
        Nothing ->
            baseClass

        Just fileState ->
            if fileState.applied then
                String.concat [ baseClass, "file-applied" ]

            else
                baseClass


fileLineView : String -> Html msg
fileLineView line =
    div [ class "file-info" ] [ text line ]


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
                            { model | importState = Just { importState | log = importState.log ++ [ log.log ] } }
                                ! [ scrollToBottom "import-log" ]

                        _ ->
                            model ! []

                Ok (ImportComplete result) ->
                    model ! [ delayMessage 1000 ImportFinished ]

                Err message ->
                    Debug.crash message

        ImportClicked ->
            case model.importState of
                Just _ ->
                    model ! []

                Nothing ->
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

        NoOp ->
            model ! []

        DroppedFileEvent result ->
            case result of
                Ok filename ->
                    model ! handleFileDrop filename model.dataset

                Err _ ->
                    model ! []

        CurrentTime now ->
            { model | currentDate = Just (Date.fromTime now) } ! []

        UploadingFile filename ->
            fileUploading model filename ! []

        UploadedFile filename ->
            fileUploaded model filename ! []


fileUploading : Model -> String -> Model
fileUploading model filename =
    { model | uploading = Dict.insert filename () model.uploading }


fileUploaded : Model -> String -> Model
fileUploaded model filename =
    { model | uploading = Dict.remove filename model.uploading }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ datasetEvent (decodeValue Dataset.eventDecoder >> DatasetEvent)
        , droppedFileEvent (decodeValue string >> DroppedFileEvent)
        , Time.every Time.minute CurrentTime
        , uploadingFile UploadingFile
        , uploadedFile UploadedFile
        ]


delayMessage : Float -> msg -> Cmd msg
delayMessage delay msg =
    let
        handler =
            always msg
    in
    Process.sleep delay
        |> Task.perform handler handler


scrollToBottom : String -> Cmd Msg
scrollToBottom nodeId =
    let
        handler =
            always NoOp
    in
    toBottom nodeId
        |> Task.perform handler handler


handleFileDrop : String -> Dataset -> List (Cmd msg)
handleFileDrop filename dataset =
    if Dataset.knownFile filename dataset then
        [ requestFileUpload filename ]

    else
        []
