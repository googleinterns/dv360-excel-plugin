# Rules Builder Server 

## Running Locally 

Use `aqueduct serve` to run the application locally.

## Running Tests 

Use `pub run test` to run all the tests.

## Setting Up

1. In `Dockerfile`, add the Google Cloud project name where indicated.
2. In `app.yaml`, add the App Engine service name where indicated.
3. In `env_variables.yaml`, add the client ID, client, secret, refresh token encryption key, and project ID where indicated.

## Securing the Server
To use Google Cloud Identity-Aware Proxy, set it up for your application.

Then, allow [CORS preflight](https://cloud.google.com/iap/docs/customizing#allowing_http_options_requests_cors_preflight): 

```
gcloud iap settings set cors.json --project=spreadsheet-dv360-plugin --resource-type=app-engine
```
cors.json:
```
{"access_settings":{"cors_settings":{"allow_http_options":{"value": true}}}}
```

# Deploying to App Engine

Use `gcloud app deploy` to deploy to App Engine.