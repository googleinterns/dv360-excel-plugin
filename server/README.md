# Rules Builder Server

 [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://choosealicense.com/licenses/apache-2.0/)
 ![](https://github.com/googleinterns/dv360-excel-plugin/workflows/Dart%20CI/badge.svg)

A server for the Excel rules builder plugin for [Display & Video 360](https://marketingplatform.google.com/about/display-video-360/). This project aims to allow users to create bulk automation and scheduled rules for DV360 line items. 

**Supported rule types**:
1. Activate/Pause line items
2. Change bidding strategy for line items
3. Duplicate line items

## Table of contents
* [Overview](#overview)
* [Dependencies](#dependencies)
* [Setup](#setup)
* [Running Locally](#running-locally)
* [Deploying to Google Cloud App Engine](#deploying-to-google-cloud-app-engine)
* [License](#license)

## Overview

<p align="center">
  <img src="images/overview.png?raw=true" align="center" width="80%" height="80%" alt="Overview">
</p>

## Dependencies

**Install Dart**:
``` bash
sudo apt-get update
sudo apt-get install wget gnupg
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart
```

**Install Protoc**:
``` bash
sudo apt-get install protobuf-compiler
PATH="$PATH:/usr/lib/dart/bin" pub global activate protoc_plugin
```

**Install server dependencies**:
``` bash
cd app
PATH="$PATH:/usr/lib/dart/bin" pub get 
```

**Install the Aqueduct command line tool**:
``` bash
PATH="$PATH:/usr/lib/dart/bin" pub global activate aqueduct
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

**Install the Cloud SDK**:

Follow the instructions [here](https://cloud.google.com/sdk/docs/quickstart).

## Setup

**Generate protobufs**:
``` bash
PATH="$PATH:$HOME/.pub-cache/bin" protoc --dart_out=pkg/proto/lib -I=pkg/proto/lib pkg/proto/lib/*.proto
```

**Set up API key and OAuth Client**:

Go [here](https://console.cloud.google.com/apis/credentials) and set up an API key and Oauth.

**Create a new App Engine project**:
1. Create a new App Engine project [here](https://console.cloud.google.com/appengine/start).
2. For language, select Other and choose a Flexible environment.

**Set up Firestore**:

Follow the instructions [here](https://console.cloud.google.com/firestore) and select *Native* mode.

**Set up Scheduler**:

Follow the instructions [here](https://console.cloud.google.com/cloudscheduler).

**Generate a refresh token encryption key**:
``` bash
PATH="$PATH:/usr/lib/dart/bin" pub global activate encrypt
secure-random
```

**Securing the Server with IAP**:

To optionally use Google Cloud Identity-Aware Proxy, set it up for your application [here](https://console.cloud.google.com/security/iap).

If you have trouble using the web UI, try using the command line interface:
``` bash
gcloud alpha iap web enable --oauth2-client-id=INSERT_CLIENT_ID  --oauth2-client-secret=INSERT_CLIENT_SECRET --resource-type=app-engine
```

Then, allow [CORS preflight](https://cloud.google.com/iap/docs/customizing#allowing_http_options_requests_cors_preflight): 

``` bash
gcloud iap settings set cors.json --project=INSERT_PROJECT_ID --resource-type=app-engine
```

cors.json:
``` json
{"access_settings":{"cors_settings":{"allow_http_options":{"value": true}}}}
```

**Setting Up**:

1. In `app.yaml`, add the App Engine service name where indicated.
2. In `env_variables.yaml`, add the client ID, client, secret, refresh token encryption key, and the Google Cloud project ID (you can find this in the project info panel on the [console](https://console.cloud.google.com) where indicated.

## Running locally

**Generate local ApplicationDefaultCredentials**:
``` bash
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/datastore,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/cloud-scheduler,https://www.googleapis.com/auth/doubleclickbidmanager
```

**Set the environment variables**:

Look at `env_variables.yaml` and set them to the correct values.

**Start the server**:
``` bash
cd app
PATH="$PATH:/usr/lib/dart/bin" aqueduct serve
```

**Running Tests**:
``` bash
cd app
PATH="$PATH:/usr/lib/dart/bin" pub run test  
```

## Deploying to Google Cloud App Engine

**Deploying to App Engine**:

Run the following command to deploy to App Engine:
``` bash
gcloud app deploy
```

## License

[Apache License 2.0](https://choosealicense.com/licenses/apache-2.0/)
