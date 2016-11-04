module MainMenu exposing (..)

import Html exposing (..)
import Html.App
import Menu
import Shared


type alias Flags =
    { contactEmail : String
    , locale : String
    , locales : List ( String, String )
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
    ( { fakeLocation = Nothing
      , contactEmail = flags.contactEmail
      , locale = flags.locale
      , locales = flags.locales
      , facilityTypes = []
      , ownerships = []
      , locations = []
      }
    , Cmd.none
    )


update msg model =
    ( model, Cmd.none )


view model =
    div []
        [ Shared.header []
        , Menu.menuContent model Menu.ApiDoc
        ]
