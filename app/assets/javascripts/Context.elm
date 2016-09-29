module Context exposing (Host, Msg, update, subscriptions)

import Models exposing (MapViewport)
import Commands


type alias Host model msg =
    { setMapViewport : MapViewport -> model -> model
    , msg : Msg -> msg
    }


type Msg
    = MapViewportChanged MapViewport


update : Host model msg -> Msg -> model -> ( model, Cmd msg )
update h msg model =
    case msg of
        MapViewportChanged mapViewport ->
            ( h.setMapViewport mapViewport model, Cmd.none )


subscriptions : Host model msg -> Sub msg
subscriptions h =
    Sub.batch
        [ Commands.mapViewportChanged (h.msg << MapViewportChanged)
        ]
