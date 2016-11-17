# Importing data

This document describe [the schema supported](#input-data-schema) by the application and [how to build](#normalizing-spa-census-information) it from the SPA-2014 census.

## Input data schema

This tool can import data using the following schema, where each table is stored in a CSV file with headers.

### Facilities

| Field         | Type                      |
|---------------|---------------------------|
| id            | String                    |
| name          | String                    |
| lat           | Float                     |
| lng           | Float                     |
| location_id   | String                    |
| facility_type | String                    |
| ownership     | String                    |
| contact_name  | String                    |
| contact_email | String                    |
| contact_phone | String                    |
| last update   | String (ISO-8601 encoded) |


### Services

| Field   | Type   |
|---------|--------|
| id      | String |
| name:en | String |
| name:am | String |

**note:** there should be a `name:LOCALE` column for each of the enabled locales of the application.

### facilities_services

| Field       | Type   |
|-------------|--------|
| facility_id | String |
| service_id  | String |


### facility_types

| Field    | Type   |
|----------|--------|
| name     | String |
| priority | Int    |

### locations

| Field     | Type   |
|-----------|--------|
| id        | String |
| name      | String |
| parent_id | String |


The priority of a facility type can be used to decide which facilities will be displayed in lower zoom levels.
If a facility's type doesn't have a corresponding entry in the `facilities` table it will be assigned the lowest priority.

## Importing CSV data

The import script assumes CSV files with the following names:
```
data
├── input
    ├── facilities.csv
    ├── facilities_services.csv
    ├── facility_types.csv
    ├── locations.csv
    └── services.csv
```

To import CSV data run the following:

```
$ bin/import-dataset data/input
```

## Normalizing SPA Census information

To import data from raw CSV exports of SPA results, store raw files as follows:

```
data
├── input
└── raw
    ├── ContactInfo.csv
    ├── Facility.csv
    ├── FacilityService.csv
    ├── FacilityType.csv
    ├── geoloc.csv
    ├── i18n.csv
    ├── MedicalService.csv
    ├── OrganizationUnit.csv
    └── ownership.csv
```

And then run the following scripts to generate the normalized input files in the `data/input` directory:

```
$ bin/normalize-spa-data data/raw data/input
```

### SPA data internationalization

The `i18n.csv` file is not actually part of the SPA result.
It's schema depends of the desired locales.
There should be one column for each locale.

| Field         | Type                      |
|---------------|---------------------------|
| en            | String                    |
| am            | String                    |

Each row will contain the equivalent text that appear across the spa raw data.

| en      | am           |
|---------|--------------|
| Tb test | የነቀርሳ ምርመራ |

In the above sample when a the service english name "Tb test" will be translated to "የነቀርሳ ምርመራ" when generating the `services.csv` `name:en` and `name:am` columns.

### Normalizing Resourcemap information


