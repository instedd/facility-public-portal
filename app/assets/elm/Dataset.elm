module Dataset exposing (Dataset, FileState, decoder)

import Dict exposing (Dict)
import Json.Decode exposing ((:=), bool, dict, int, maybe, object4, string)


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
