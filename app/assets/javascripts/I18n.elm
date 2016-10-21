module I18n exposing (..)

import Native.I18n


type TranslationId
    = SearchHealthFacility
    | Map
    | ApiDocs
    | Contact


t : TranslationId -> String
t resource =
    Native.I18n.t resource
