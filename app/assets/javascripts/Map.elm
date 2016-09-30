module Map exposing (Host, subscriptions)

import Models exposing (MapViewport)
import Commands


type alias Host msg =
    { mapViewportChanged : MapViewport -> msg
    , facilityMarkerClicked : Int -> msg
    }


subscriptions : Host msg -> Sub msg
subscriptions h =
    Sub.batch
        [ Commands.mapViewportChanged h.mapViewportChanged
        , Commands.facilityMarkerClicked h.facilityMarkerClicked
        ]
