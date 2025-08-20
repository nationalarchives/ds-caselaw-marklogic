# CoRB2 Tools

Perform bulk one-off updates and migrations of data using [CoRB2](https://github.com/marklogic-community/corb2).

## Installation

1. `brew install temurin` to get a working Java (I had to install-uninstall-install)
1. Download the CoRB2 `.jar` from https://github.com/marklogic-community/corb2/releases
1. Download the XCC `.jar` from https://repo1.maven.org/maven2/com/marklogic/marklogic-xcc/11.1.0/ or https://developer.marklogic.com/products/xcc-2/ (I used maven)
1. Place both `.jar` files into this directory

## Running

> [!Note]
> Before you run anything you may need to adjust the command in `corb` to use the correct version of the above `.jar` files.

By default these scripts run against `admin:admin@localhost`. You can adjust this using the following environment variables:

- `ML_HOST` (and `ML_PORT` if you need something other than `8011`)
- `ML_USER`
- `ML_PASS`

### Validate

```shell
./corb validate
```

Run validation tasks on existing documents. `validate.log` shows output.

### Populate `first_published_datetime` sentinel values

```shell
./corb populate_first_published_sentinels
```

As part of [identifying first publication dates for documents](https://github.com/nationalarchives/ds-caselaw-custom-api-client/pull/1172), fill the `first_published_datetime` property of documents with `1970-01-01 00:00:00` where the document is published and where this value is currently empty.

### Migrate NCNs

> [!WARNING]
> **This is a destructive operation!** Do not run against any database which already has structured identifiers.

```shell
./corb migrate-ncn
```

Used to migrate existing `uk:cite` and `uk:summaryOfCite` values to the structured identifiers framework.

`migrate-ncn.log` will show what it writes to the identifiers
