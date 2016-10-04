# Importing data

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
| contact_name  | String                    |
| contact_email | String                    |
| contact_phone | String                    |
| last update   | String (ISO-8601 encoded) |


### Services

| Field | Type   |
|-------|--------|
| id    | String |
| name  | String |


### facilities_services

| Field       | Type   |
|-------------|--------|
| facility_id | String |
| service_id  | String |

### locations

| Field     | Type   |
|-----------|--------|
| id        | String |
| name      | String |
| parent_id | String |


## Importing CSV data

The import script assumes CSV files with the following names:
```
data
├── input
    ├── facilities.csv
    ├── facilities_services.csv
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
    ├── MedicalService.csv
    ├── OrganizationUnit.csv
    └── geoloc.csv
```

And then run the following scripts to generate the normalized input files in the `data/input` directory:

```
$ bin/normalize-spa-data data/raw data/input
```
