# Facility Public Portal

## Development

### Elm

To compile Elm code, first install Node.js (tested on LTS v4.5.0).
This can be done either via Homebrew or by [downloading the binaries](https://nodejs.org/en/download/), extracting them and adding the corresponding entries to your shell's `PATH` variable.

Then install Elm and this project's dependencies:

```
$ npm install -g elm@0.17.1
$ elm package install
```

Once  installed, Elm files will be automatically compiled as part of the Rails asset pipeline.

### Elasticsearch and PostgreSQL

This project needs Elasticsearch v2.4 and PostgreSQL v9.5 (**TODO** do we really need Postgres?).
Both can be run in development using Docker:

```
$ docker-compose up -d
```

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
