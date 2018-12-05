module Debounce.Helpers exposing (deferredCmd)

import Process
import Task exposing (Task)


deferredCmd : Float -> a -> Cmd a
deferredCmd delay a =
    Task.perform (always a) (Process.sleep delay)
