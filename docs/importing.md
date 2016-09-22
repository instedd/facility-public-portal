# Importing data

Import CSV facilities information as follows:

```
$ curl -XPUT localhost:9200/fpp/_settings -d '{"index" : {"refresh_interval" : "-1"} }'
$ bin/import-dataset "data-normalized.csv"
$ curl -XPUT localhost:9200/fpp/_settings -d '{"index" : {"refresh_interval" : "1s"} }'
$ curl -XPOST localhost:9200/fpp/_forcemerge?max_num_segments=5
```

The input file needs to have the following fields:

  - resmap-id
  - name
  - lat
  - long
  - services
  - administrative_boundaries
  - administrative_boundaries-1
  - administrative_boundaries-2
  - administrative_boundaries-3
  - administrative_boundaries-4
  - report_to
  - poc_email
  - poc_phonenumber
  - pocname
  - facility_type
  - last update


The script `bin/transform-dataset` might be handy to transform other CSV schemas into the expected one.
