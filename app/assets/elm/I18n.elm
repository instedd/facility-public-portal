module I18n exposing (TranslationId(..), t)

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
    | LandingPage
    | Editor
    | AdvancedSearch
    | FacilityName
    | FacilityType
    | Ownership
    | Location
    | Service
    | Search
    | AccessTheMfrApi
    | Dataset
    | DownloadResult
    | SortBy
    | Distance
    | Name
    | WrongLocation
    | Closed
    | ContactMissing
    | InnacurateServices
    | Other
    | DetailedDescription
    | SelectIssueToReport
    | SendReport
    | Logout
    | Account
    | NoInformationAboutFacility



t : TranslationId -> String
t resource =
    Native.I18n.t resource
