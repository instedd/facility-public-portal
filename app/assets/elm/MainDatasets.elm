port module MainDatasets exposing (Model, Msg, init, main, subscriptions, update, view)

import Dataset exposing (Dataset, FileState, ImportResult, importDataset)
import Dict exposing (Dict)
import Html exposing (Html, a, div, h1, p, pre, span, text)
import Html.App
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (decodeValue)
import Json.Encode


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
    = DatasetUpdated (Result String Dataset)
    | ImportClicked
    | ImportStarted (Result Http.Error ImportResult)
    | ImportProgress ImportLog


port datasetUpdated : (Json.Decode.Value -> msg) -> Sub msg


port watchImport : String -> Cmd msg


port importProgress : (ImportLog -> msg) -> Sub msg


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
        DatasetUpdated result ->
            case result of
                Ok dataset ->
                    { model | dataset = dataset } ! []

                _ ->
                    model ! []

        ImportClicked ->
            model ! [ importDataset ImportStarted ]

        ImportStarted result ->
            case result of
                Ok result ->
                    { model | importState = Just { processId = result.processId, log = [] } }
                        ! [ watchImport result.processId ]

                Err _ ->
                    model ! []

        ImportProgress log ->
            case model.importState of
                Just importState ->
                    { model | importState = Just { importState | log = importState.log ++ [ log.log ] } } ! []

                _ ->
                    model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ datasetUpdated (decodeValue Dataset.decoder >> DatasetUpdated)
        , importProgress ImportProgress
        ]
