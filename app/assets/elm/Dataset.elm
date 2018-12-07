module Dataset exposing (Dataset, Event(..), FileState, ImportStartResult, eventDecoder, importDataset)

import Dict exposing (Dict)
import Http
import Json.Decode exposing ((:=), bool, dict, fail, int, maybe, object1, object2, object4, string)
import Task


type alias FileState =
    { updated_at : String
    , size : Int
    , md5 : String
    , applied : Bool
    }


type alias Dataset =
    Dict String (Maybe FileState)


type alias Log =
    { processId : String
    , log : String
    }


type alias ImportResult =
    { processId : String
    , exitCode : Int
    }


type Event
    = DatasetUpdated Dataset
    | ImportLog Log
    | ImportComplete ImportResult


decoder : Json.Decode.Decoder Dataset
decoder =
    dict <|
        maybe <|
            object4
                FileState
                ("updated_at" := string)
                ("size" := int)
                ("md5" := string)
                ("applied" := bool)


eventDecoder : Json.Decode.Decoder Event
eventDecoder =
    Json.Decode.andThen
        ("type" := string)
        (\eventType ->
            case eventType of
                "datasets_update" ->
                    object1 DatasetUpdated ("datasets" := decoder)

                "import_log" ->
                    object1 ImportLog <|
                        object2
                            Log
                            ("pid" := string)
                            ("log" := string)

                "import_complete" ->
                    object1 ImportComplete <|
                        object2
                            ImportResult
                            ("pid" := string)
                            ("exit_code" := int)

                _ ->
                    fail ("Unexpected event type: " ++ eventType)
        )


type alias ImportStartResult =
    { processId : String
    }


importResultDecoder : Json.Decode.Decoder ImportStartResult
importResultDecoder =
    object1
        ImportStartResult
        ("process_id" := string)


importDataset : (Result Http.Error ImportStartResult -> msg) -> Cmd msg
importDataset handler =
    let
        url =
            "/datasets/import"
    in
    Task.perform
        (\error -> handler <| Err error)
        (\result -> handler <| Ok result)
        (Http.post importResultDecoder url Http.empty)
