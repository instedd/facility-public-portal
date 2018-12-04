port module MainDatasets exposing (Model, Msg, init, main, subscriptions, update, view)

import Html exposing (Html, div, h1, p, text)
import Html.App


type alias Model =
    Maybe FileState


type alias FileState =
    { updated_at : String
    , size : Int
    , md5 : String
    , applied : Bool
    }


type alias Dataset =
    { categories : FileState }


type Msg
    = DatasetUpdated Dataset


port datasetUpdated : (Dataset -> msg) -> Sub msg


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
    Nothing ! []


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Dataset" ]
        , p []
            [ text "Drop your files here to update the dataset."
            , text "You could also import ONA files."
            , text "You'll be able to review before new data is deployed."
            ]
        , datasetView model
        ]


datasetView : Model -> Html msg
datasetView model =
    case model of
        Nothing ->
            div [] []

        Just dataset ->
            text dataset.updated_at


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DatasetUpdated dataset ->
            Just dataset.categories ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    datasetUpdated DatasetUpdated
