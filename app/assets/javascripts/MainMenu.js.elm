module MainMenu exposing (..)

import Html exposing (Html, div)
import Html.App
import Html.Attributes exposing (class)
import Menu
import Shared
import Navigation
import UrlParser exposing (..)
import String


type alias Flags =
    { contactEmail : String
    , authenticated : Bool
    , menuItem : String
    }


type Msg
    = ToggleMenu


type alias Model =
    { settings : Menu.Settings
    , currentPage : Menu.Item
    , menu : Menu.Model
    }


main : Program Flags
main =
    Html.App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        settings =
            { contactEmail = flags.contactEmail
            , showEdition = flags.authenticated
            }
    in
        { settings = settings, currentPage = Menu.parseItem flags.menuItem, menu = Menu.Closed } ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update ToggleMenu model =
    ( { model | menu = Menu.toggle model.menu }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        mobileView =
            div [ class "hide-on-large-only" ]
                [ Shared.header [ Menu.anchor ToggleMenu ]
                , Menu.sideMenu model.settings model.currentPage model.menu ToggleMenu
                ]

        desktopMenu =
            div [ class "hide-on-med-and-down" ]
                [ Menu.fixedMenu model.settings model.currentPage ]
    in
        div
            []
            [ desktopMenu
            , mobileView
            ]
