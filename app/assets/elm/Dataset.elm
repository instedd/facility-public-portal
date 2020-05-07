module Dataset exposing
    ( Dataset
    , Event(..)
    , FileState
    , FileConfig
    , Fileset
    , FilesetTag(..)
    , ImportStartResult
    , empty
    , eventDecoder
    , fileLabel
    , fileMissing
    , humanReadableFileSize
    , humanReadableFileTimestamp
    , importDataset
    , inFileset
    , knownFile
    )

import Date exposing (Date)
import Dict exposing (Dict)
import Http
import Json.Decode exposing ((:=), bool, dict, fail, int, maybe, object1, object2, object3, object4, string, succeed)
import String
import Task
import Time


type FilesetTag
    = Raw
    | Ona


type alias FileState =
    { updated_at : String
    , size : Int
    , md5 : String
    , applied : Bool
    }

type alias FileConfig =
    { drive_enabled : Bool
    , state : Maybe FileState
    , url : Maybe String
    }

type alias Fileset =
    Dict String FileConfig


type alias Dataset =
    { ona : Fileset
    , raw : Fileset
    }


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


empty : Dataset
empty =
    { ona = Dict.empty, raw = Dict.empty }


decoder : Json.Decode.Decoder Dataset
decoder =
    object2
        Dataset
        ("ona" := filesetDecoder)
        ("raw" := filesetDecoder)


filesetDecoder : Json.Decode.Decoder Fileset
filesetDecoder =
    dict <|
        object3
            FileConfig
            ("drive_enabled" := bool)
            ("state" := (maybe <|
                object4
                    FileState
                    ("updated_at" := string)
                    ("size" := int)
                    ("md5" := string)
                    ("applied" := bool)))
            (succeed Nothing)
        


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


importDataset : FilesetTag -> (Result Http.Error ImportStartResult -> msg) -> Cmd msg
importDataset filesetTag handler =
    let
        url =
            if filesetTag == Ona then
                "/datasets/import_ona"

            else
                "/datasets/import"
    in
    Task.perform
        (\error -> handler <| Err error)
        (\result -> handler <| Ok result)
        (Http.post importResultDecoder url Http.empty)


knownFile : String -> Dataset -> Bool
knownFile filename dataset =
    Dict.member filename dataset.ona || Dict.member filename dataset.raw


inFileset : String -> Fileset -> Bool
inFileset =
    Dict.member


fileLabel : Maybe FileState -> String -> (FileState -> String) -> String
fileLabel state default lab =
    case state of
        Nothing ->
            default

        Just st ->
            lab st


humanReadableFileTimestamp : Maybe Date -> FileState -> String
humanReadableFileTimestamp maybeDate state =
    case maybeDate of
        Nothing ->
            ""

        Just currentDate ->
            case Date.fromString state.updated_at of
                Ok fileDate ->
                    moment currentDate fileDate

                Err _ ->
                    ""


moment : Date -> Date -> String
moment referencePoint evaldDate =
    let
        sameDay =
            Date.day referencePoint
                == Date.day evaldDate
                && Date.month referencePoint
                == Date.month evaldDate
                && Date.year referencePoint
                == Date.year evaldDate

        minuteDifference =
            abs <| (evaldDate |> Date.toTime |> Time.inMinutes) - (referencePoint |> Date.toTime |> Time.inMinutes)

        hourDifference =
            minuteDifference / 60

        dayDifference =
            hourDifference / 24

        formattedDate =
            toString <| Date.month evaldDate

        a =
            minuteDifference |> toString |> Debug.log
    in
    if sameDay then
        if minuteDifference > 10 then
            "Today"

        else
            "Now"

    else if dayDifference == 1 then
        "Yesterday"

    else
        String.concat [ toString <| Date.month evaldDate, " ", toString <| Date.day evaldDate, ", ", toString <| Date.year evaldDate ]


humanReadableFileSize : FileState -> String
humanReadableFileSize state =
    let
        s = if state.size >= 1024 then
                [ toString (state.size // 1024), " KB" ]

            else
                [ toString state.size, " B" ]
    in
    String.concat s


fileMissing : FileState -> Bool
fileMissing f =
    f.size == 0
