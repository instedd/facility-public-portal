port module Main exposing (..)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)

main : Program Never
main =
  App.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


-- MODEL

type alias Model = Int

initialModel : Model
initialModel = 0

init : (Model, Cmd Msg)
init = (initialModel, Cmd.none)

-- UPDATE

type alias Msg = ()

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = (model, Cmd.none)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model = Sub.none

-- VIEW

mapControlView : Model -> Html Msg
mapControlView model = div [ class "map-control" ]
                           [ div [ class "row header" ]
                                 [ span [] [ text "Ethiopia" ]
                                 , h1 [] [ text "Ministry of Health" ]
                                 ]
                           , div [ class "row" ]
                                 [ text "Search!" ]
                           ]

view : Model -> Html Msg
view model = div [] [ mapControlView model ]
