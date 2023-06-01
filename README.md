# The National Archives: Find Case Law

This repository is part of the [Find Case Law](https://caselaw.nationalarchives.gov.uk/) project at [The National Archives](https://www.nationalarchives.gov.uk/).

# Marklogic Database Configuration

This folder specifies the configuration of the Marklogic database used by the Case Law public access system.
It uses the [ml-gradle](https://github.com/marklogic/ml-gradle) to manage and maintain a versioned configuration.

For full details of what can be set in the files here, see the [ml-gradle documentation](https://github.com/marklogic-community/ml-gradle/wiki).
The file layout is explaines in the [project layout documentation](https://github.com/marklogic-community/ml-gradle/wiki/Project-layout).

## Setup

1. Access to the Marklogic Docker image is restricted to those who have 'purchased' it on Docker Hub. It's actually FREE to purchase, but you need to fill out [a short form](https://hub.docker.com/_/marklogic/purchase).

2. Install `gradle`. On MacOS, you can use `brew install gradle`.

3. If you're running against anything other than development, copy `gradle-development.properties`
to `gradle-{environment}.properties` and set the credentials and hostname for your Marklogic server.

## Deployment

To deploy a marklogic configuration, run `gradle mlDeploy -PenvironmentName={environment}`.

The `development` environment will be used by default if you don't specify `-PenvironmentName`.

Deployment is idempotent, and will automatically configure databases, roles, triggers and modules.

## Local Setup

### 1. Run a marklogic docker container

A `docker-compose.yml` file for running Marklogic locally is included. Run `docker-compose up -d` to start it; it takes about a minute, and will raise various HTTP errors if you visit `localhost:8000` before that point.

Note: There is currently a [known issue](https://github.com/marklogic/marklogic-docker/issues/212) with [marklogic-docker](https://github.com/marklogic/marklogic-docker) so instead you might need to run:

```docker run -d \
   --name marklogic \
   -p 8000:8000 \
   -p 8001:8001 \
   -p 8002:8002 \
   -p 8011:8011 \
   -e MARKLOGIC_ADMIN_USERNAME=admin \
   -e MARKLOGIC_ADMIN_PASSWORD=admin \
   -e MARKLOGIC_INIT=true \
   -v $(pwd)/.docker/db/data/:/var/opt/MarkLogic/ \
   -v $(pwd)/.docker/db/backup:/var/opt/backup \
   --network caselaw \
   marklogicdb/marklogic-db:11.0.2-centos-1.0.2
```

### 2. Deploy the marklogic configuration

You'll then need to deploy the configuration (see Deployment, above)

### 3. Make clients point to the local docker container

Ensure that `MARKLOGIC_HOST` in `.env` in the editor and public ui is set to `host.docker.internal` in `.env` and that the username and password are both `admin` if you want to use them with the local instance.

### 4. (Optional) Populate data in the local database

To get some example documents onto the local database, there is a `development_scripts/populate.py` that copies documents from the live caselaw site (it doesn't import or fake properties) into it.

There are also other ways other importing data as detailed further down the readme but haven't been tested for a while.

## Release versioning

The releases are currently manually tagged. Please do not deploy to production without tagging a release. 
Currently there is no auto-deployment of releases, but we are using releases & tags to keep track of what has been deployed to
production.

To create a versioned release, use Github's [release process](https://github.com/nationalarchives/ds-caselaw-marklogic/releases)
to create a tag and generate release notes.

When deploying to production, check out the tag you want to deploy using (for example) `git checkout tags/v1.0.0`
then deploy from there. Git will put you into a "detatched head" state, and once you have finished deploying you can
switch back to the main branch (or any branch) by using `git checkout branchname` as normal.

TODO: Automatically deploy main to staging, and tags to production using CodeBuild.

## Bulk import

(This hasn't been used in a long time)

Place the XML files you want to import in the `import` folder of this repo, then run
`gradle importDocuments`. The documents will be imported, and the URI will be set as the
full file path and name within `import`.

You may want to run `gradle publishAllDocuments` (see below) afterwards. All files
are automatically put under management on import, so there is no need to run the manage task.

## Bulk export

To export the latest versions of all documents, for instance for bulk processing, you can use:
` gradle mlExportToZip -PwhereUrisQuery="const dls = require('/MarkLogic/dls'); cts.uris('', [], dls.documentsQuery())" -PenvironmentName=<env> -PexportPath=export.zip`

## Document processing

Two gradle tasks are available for bulk management of documents in a database using
[CoRB](https://github.com/marklogic-community/corb2). In production these should not be
necessary to use, but are provided in order to automate some development tasks and provide
examples for future data migrations.

* `gradle manageAllDocuments`: Enables version management for all documents
* `gradle publishAllDocuments`: Sets the `published` flag for all documents

### Loading data from a backup on S3 (deprecated)

Rather than running an import of a set of files, you can restore from a shared backup. Note that this
bucket is currently only available to dxw developers.

1. First, navigate to http://localhost:8001/, which will ask for basic auth. Username and password are both `admin`.
2. Then add AWS credentials to MarkLogic (under Security > Credentials), so it can pull the backup from a shared S3 bucket.
   The credentials (AWS access ID & secret key) should be for your `dxwbilling` account. You will need to create them in AWS
   if you haven't already.
3. In the Backup/Restore tab in Marklogic for your the `caselaw-content` Judgments database, initiate a restore, using the following as the
   `"directory": s3://tna-judgments-marklogic-backup/`. Set `Forest topology changed` to `true`.
4. Uncheck the `security` database when restoring or your passwords will be wiped.

Assuming you have entered the S3 credentials correctly, this will kick off a restore from s3. Once you have the data locally,
you can then back it up locally using the path `/var/opt/backup` in the management console. It will be backed up to your local
machine in `docker/db/backup`

Depending on the backup state, you may need to run `gradle manageAllDocuments` and `gradle publishAllDocuments` after the restore has finished.

### Marklogic URL Guide

- http://localhost:8000/ this is the query interface where you can browse documents in the `Judgments` database.
- http://localhost:8001/ this is the management console where you can administer your database.
- http://localhost:8002/ this is the monitoring dashboard.
- http://localhost:8011/ this is the application server for the Marklogic REST interface

All four URLs use basic auth, username and password are both `admin`.
