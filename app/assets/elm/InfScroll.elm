module InfScroll exposing (Msg, Config(..), update, view)

{-|
This modules implements infinite scroll ui pattern.

@docs Config
@docs update
@docs view
@docs Msg
-}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on)
import Json.Decode as Json
import Task
import Process

type alias Pos =
  { scrolledHeight : Int
  , contentHeight : Int
  , containerHeight : Int
  }

{-|
  Messages to be wrapped.
-}
type Msg = Scroll Pos

{-|
  Configuration of the InfScroll component.
-}
type Config model item msg
    = Config { loadMore : model -> msg
      , msgWrapper : Msg -> msg
      , itemView : item -> Html msg
      , loadingIndicator : Html msg
      , hasMore : model -> Bool
      }

{-|
  Handle update messages of the InfScroll component.
-}
update : Config model item msg -> model -> Msg -> (model, Cmd msg)
update (Config cfg) model msg =
    case msg of
        Scroll pos ->
          let
            bottom = toFloat <| pos.scrolledHeight + pos.containerHeight
            threashold = toFloat pos.contentHeight - (toFloat pos.containerHeight * 0.2)
            shouldLoadMore = bottom > threashold
          in
            if shouldLoadMore then
              (model, performMessage <| cfg.loadMore model )
            else
              (model, Cmd.none)

{-|
  Handle rendering of the InfScroll component.
-}
view : Config model item msg -> model -> List item -> Html msg
view (Config cfg) model items =
  div [ class "inf-scroll-container", onScroll (cfg.msgWrapper << Scroll) ]
    ((List.map cfg.itemView items) ++ (if (cfg.hasMore model) then [cfg.loadingIndicator] else []))

performMessage : msg -> Cmd msg
performMessage msg =
    Task.perform unreachable identity (Task.succeed msg)

onScroll : (Pos -> action) -> Attribute action
onScroll tagger =
  on "scroll" (Json.map tagger decodeScrollPosition)

decodeScrollPosition : Json.Decoder Pos
decodeScrollPosition =
  Json.map3 Pos
    scrollTop
    scrollHeight
    (maxInt offsetHeight clientHeight)

scrollTop : Json.Decoder Int
scrollTop =
  Json.at [ "target", "scrollTop" ] Json.int

scrollHeight : Json.Decoder Int
scrollHeight =
  Json.at [ "target", "scrollHeight" ] Json.int

offsetHeight : Json.Decoder Int
offsetHeight =
  Json.at [ "target", "offsetHeight" ] Json.int

clientHeight : Json.Decoder Int
clientHeight =
  Json.at [ "target", "clientHeight" ] Json.int

maxInt : Json.Decoder Int -> Json.Decoder Int -> Json.Decoder Int
maxInt x y =
  Json.map2 Basics.max x y
