module MainMenu exposing (..)

import Models exposing (..)
import Shared
import Menu
import Html exposing (..)
import Html.App


type alias Flags =
    { contactEmail : String
    }


main : Program Flags
main =
    Html.App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


init flags =
    ( { fakeLocation = Nothing, contactEmail = flags.contactEmail }, Cmd.none )


update msg model =
    ( model, Cmd.none )


view model =
    div []
        [ Shared.header []
        , Menu.menuContent model Menu.ApiDoc
        ]
