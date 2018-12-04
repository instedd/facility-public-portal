module I18n exposing (..)

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

t : TranslationId -> String
t resource = "No hay arroz"