module Dataset exposing (Dataset, FileState, ImportResult, decoder, importDataset)

import Dict exposing (Dict)
import Http
import Json.Decode exposing ((:=), bool, dict, int, maybe, object1, object4, string)
import Task


type alias FileState =
    { updated_at : String
    , size : Int
    , md5 : String
    , applied : Bool
    }


type alias Dataset =
    Dict String (Maybe FileState)


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


type alias ImportResult =
    { processId : String
    }


importResultDecoder : Json.Decode.Decoder ImportResult
importResultDecoder =
    object1
        ImportResult
        ("process_id" := string)


importDataset : (Result Http.Error ImportResult -> msg) -> Cmd msg
importDataset handler =
    let
        url =
            "/datasets/import"
    in
    Task.perform
        (\error -> handler <| Err error)
        (\result -> handler <| Ok result)
        (Http.post importResultDecoder url Http.empty)
