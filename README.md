# Facility Public Portal

## Development

* Install Docker

* First time

```
$ docker-compose run --rm app ./bin/setup
$ docker-compose up
```

* Initial import data

If you already have a `./data/input` directory as described in the [importing guide](docs/importing.md), index it with:

```
$ docker-compose run --rm app ./bin/import-dataset data/input
```

* Upgrade

```
$ docker-compose run --rm app ./bin/update
$ docker-compose up
```

Note that you might need to reimport the data depending on the update.

* Destroy

```
$ docker-compose run --rm app ./bin/rails db:drop
```

Or

```
$ docker-compose down -v
```

### Elm

To compile Elm code, first install Node.js (tested on LTS v4.5.0).
This can be done either via Homebrew or by [downloading the binaries](https://nodejs.org/en/download/), extracting them and adding the corresponding entries to your shell's `PATH` variable.

Then install Elm and this project's dependencies:

```
$ npm install -g elm@0.17.1
$ elm package install
```

Once installed, Elm modules will be automatically built and compiler errors will be displayed by the rails development server.

### Elasticsearch and PostgreSQL

This project needs Elasticsearch v2.4 and PostgreSQL v9.5.
Both are started as docker containers by the docker-compose.

Data from these containers is preserved between restarts. To stop any running instance **and delete data volumes**, use:

```
$ docker-compose down -v
```

To see logs for the running containers use `docker-compose logs -f`.

As a one-time setup, create the development database and initialize Elasticsearch indices with the following commands:

```
$ bin/rake db:setup
$ bin/rake elasticsearch:setup
```

### Ruby and Rails

This project uses Ruby v2.3.1. All Ruby dependencies (including Rails 5) can be installed using Bundler:

```
$ bin/bundle install --path=.bundle
```

After that, the application can be run in development mode as follows:

```
$ bin/rails s
```

## I18n support

See [this guide](docs/i18n.md)

## Importing data

See [this guide](docs/importing.md).
