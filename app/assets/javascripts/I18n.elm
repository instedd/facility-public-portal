module I18n exposing (..)

import Native.I18n


type TranslationId
    = SearchHealthFacility
    | Map
    | ApiDocs
    | Services
    | Contact
    | FacilitiesCount { count : Int }
    | ReportAnIssue
    | FullDownload


t : TranslationId -> String
t resource =
    Native.I18n.t resource
