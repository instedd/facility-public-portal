module Context exposing (Context, Msg, update, subscriptions)

import Models exposing (MapViewport)
import Commands


type alias Context model msg =
    { setMapViewport : MapViewport -> model -> model
    , wrapMessage : Msg -> msg
    }


type Msg
    = MapViewportChanged MapViewport


update : Context model msg -> Msg -> model -> ( model, Cmd msg )
update context msg model =
    case msg of
        MapViewportChanged mapViewport ->
            ( context.setMapViewport mapViewport model, Cmd.none )


subscriptions : Context model msg -> Sub msg
subscriptions context =
    Sub.batch
        [ Commands.mapViewportChanged (context.wrapMessage << MapViewportChanged)
        ]
