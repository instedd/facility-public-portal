module MainMenu exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Menu
import Shared
import Models
import Navigation
import Routing
import UrlParser exposing (..)
import String


type alias Flags =
    { contactEmail : String
    , locale : String
    , locales : List ( String, String )
    }


type Msg
    = ToggleMenu


type alias Model =
    { settings : Models.Settings
    , currentPage : Menu.Item
    , menu : Menu.Model
    }


main : Program Flags
main =
    Navigation.programWithFlags routeParser
        { init = init
        , view = view
        , update = update
        , urlUpdate = (\route model -> ( model, Cmd.none ))
        , subscriptions = always Sub.none
        }


init : Flags -> Result String Menu.Item -> ( Model, Cmd Msg )
init flags route =
    let
        currentPage =
            Result.withDefault Menu.LandingPage route

        settings =
            { fakeLocation = Nothing
            , contactEmail = flags.contactEmail
            , locale = flags.locale
            , locales = flags.locales
            , facilityTypes = []
            , ownerships = []
            }
    in
        { settings = settings, currentPage = currentPage, menu = Menu.Closed } ! []


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


routeParser : Navigation.Parser (Result String Menu.Item)
routeParser =
    let
        matchers =
            oneOf
                [ format Menu.ApiDoc (s "docs")
                , format Menu.LandingPage (s "")
                ]

        parser location =
            location.pathname
                |> String.dropLeft 1
                |> parse identity matchers
    in
        Navigation.makeParser parser
