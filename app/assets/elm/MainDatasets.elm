port module MainDatasets exposing (Model, Msg, init, main, subscriptions, update, view)

import Dataset exposing (Dataset, FileState)
import Dict exposing (Dict)
import Html exposing (Html, div, h1, p, text)
import Html.App
import Json.Decode exposing (decodeValue)
import Json.Encode


type alias Model =
    { dataset : Dataset
    }


type Msg
    = DatasetUpdated (Result String Dataset)


port datasetUpdated : (Json.Decode.Value -> msg) -> Sub msg


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
    { dataset = Dict.empty } ! []


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Dataset" ]
        , p []
            [ text "Drop your files here to update the dataset."
            , text "You could also import ONA files."
            , text "You'll be able to review before new data is deployed."
            ]
        , datasetView model.dataset
        ]


datasetView : Dataset -> Html msg
datasetView dataset =
    dataset
        |> Dict.toList
        |> List.map fileView
        |> div []


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


subscriptions : Model -> Sub Msg
subscriptions model =
    datasetUpdated (decodeValue Dataset.decoder >> DatasetUpdated)
