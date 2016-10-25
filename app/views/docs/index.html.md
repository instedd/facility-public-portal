# API

## i18n

All api endpoints allows a `locale` parameter to specify the language or locale set to use. This affects the data returned and how to make searches: for example if English or Amharic versions of services' name should be used.

| Value | Locale |
|---|---|
| en | English |
| am | Amharic |

```
$ curl 'vitalwave.instedd.org/api/facilities/85?locale=en'
$ curl 'vitalwave.instedd.org/api/facilities/85?locale=am'
```

## Discovery

The suggest endpoint allows discovery in a human friendly manner. A response will include facilities, locations and services that match the search criteria.

* For the informed facilites, [details api](#facility-details) can be used.
* For informed services and location, [search api](#search) can be used to get a list of facilities.

No paging is supported in this endpoint.

*`GET /api/suggest`*

### Parameters

| Name | Type | Description |
|---|---|---|
| q | string | Text to be searched. |
| lat | float | Lat/Lng coordinates used to prioritize the results.  |
| lng | float | Lat/Lng coordinates used to prioritize the results.  |

### Sample

```
$ curl 'vitalwave.instedd.org/api/suggest?q=ur&lat=8.979780521754858&lng=38.758907318115234'
{
  "facilities": [
    {
      "id": 3190,
      "name": "Urufa",
    },
    {
      "id": 1927,
      "name": "Uraga Midhidi Health Center",
    },
    {
      "id": 2588,
      "name": "Urmadag Godane Health Center",
    }
  ],
  "services": [
    {
      "id": 168,
      "name": "Urine chemistry/pregnancy testing",
      "facility_count": 2543
    }
  ],
  "locations": [
    {
      "id": 113,
      "name": "Uraga",
      "facility_count": 10,
    }
  ]
}
```

## Search

The search endpoint allows filtering the facilities based on certain criteria:

* full text search
* services based search
* location based search
* type based search

If provided, results will be returned ordered by a geolocation coordinate.

Paging is supported to interate the whole results.


*`GET /api/search`*

### Parameters

| Name | Type | Description |
|---|---|---|
| q | string | Text to be searched. |
| s | integer | service id that must be handled by the informed facility. |
| l | integer | location id where the informed facility should belong to. |
| t | integer | facility type id of the informed facility. |
| lat | float | Lat/Lng coordinates used to prioritize the results.  |
| lng | float | Lat/Lng coordinates used to prioritize the results.  |
| size | integer | amount of facilities to be informed per page (default 50) |
| from | integer | result pagination offset (default 0) |


### Sample


```
$ curl 'vitalwave.instedd.org/api/search?l=113&size=7&lat=8.9797&lng=38.7589'
{
  "items": [
    {
      "id": 1462,
      "name": "Haroo Flaruu",
      /* ... stripped content ... */
    },
    {
      "id": 2447,
      "name": "Raro Nensebo Health Center",
      /* ... stripped content ... */
    },
    {
      "id": 3660,
      "name": "Uddessa Mudi Health Center",
      /* ... stripped content ... */
    },
    {
      "id": 2664,
      "name": "Kofole Goyyo Health Center",
      /* ... stripped content ... */
    },
    {
      "id": 1927,
      "name": "Uraga Midhidi Health Center",
      /* ... stripped content ... */
    },
    {
      "id": 202,
      "name": "Harsu Wokio Health Center",
      /* ... stripped content ... */
    },
    {
      "id": 3533,
      "name": "Haro Wachu Health Center",
      /* ... stripped content ... */
    }
  ],
  "next_url": "/api/search?from=7&l=113&lat=8.9797&lng=38.7589&size=7"
}
```

The `next_url` contains the path to be requested for the following page of results. If there is no `next_url` entry there is no more results.


```
$ curl 'vitalwave.instedd.org/api/search?from=7&l=113&size=7&lat=8.9797&lng=38.7589'
{
  "items": [
    {
      "id": 85,
      "name": "Burkitu Marmara Health Center",
      /* ... stripped content ... */
    },
    {
      "id": 643,
      "name": "Hadha Raro",
      /* ... stripped content ... */
    },
    {
      "id": 3799,
      "name": "Yabitu Koba Health Center",
      /* ... stripped content ... */
    }
  ]
}
```

Items in search result contains fields that describe the facility in the same way the [facility details api](#facility-details) will do.

## Facility Details

Given an `id` of a facility the details endpoint allows getting all the known information of a facility.

*`GET /api/facilities/:id`*

### Sample

```
$ curl 'vitalwave.instedd.org/api/facilities/85'
{
  "id": 85,
  "name": "Burkitu Marmara Health Center",
  "facility_type": "Health Center",
  "contact_name": "Getachew",
  "contact_email": null,
  "contact_phone": null,
  "position": {
    "lat": 6.08633,
    "lng": 38.43375
  },
  "service_ids": [
    109,
    219,
    110,
    /* ... stripped content ... */
  ],
  "service_names": [
    "Hiv test",
    "Antenatal care (anc)",
    "Snellens chart",
    /* ... stripped content ... */
  ],
}
```

## Faciliy Types

The facility types endpoint allows listing the types of all facilities.

*`GET /api/facility_types`*

### Sample
```
$ curl 'vitalwave.instedd.org/api/facility_types'
[
  {
    "id": 1,
    "name": "Health Center",
    "priority": 1
  },
  {
    "id": 2,
    "name": "Primary Hospital",
    "priority": 2
  },
  {
    "id": 3,
    "name": "General Hospital",
    "priority": 3
  },
  {
    "id": 4,
    "name": "Referral Hospital",
    "priority": 4
  }
]
```
