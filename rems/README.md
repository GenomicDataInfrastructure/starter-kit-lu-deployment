![](logo_small.png)

# REMS Starter Kit for GDI

This repository provides a basic local deployment of REMS with GDI branding. This is only provided as an example deployment for getting familiar with REMS, **and should not be used as a production deployment.** A production database should be deployed separately from the application with non-default configurations, and be secured following best practices.

See [REMS repository](https://github.com/CSCfi/rems) for more documentation regarding deployment and configuration options.

### Requirements
This starter kit was development on linux, the following tools are required:
- docker
- docker-compose
- python3
- curl

## Preliminary Requirements

### Register an OIDC RP client for authentication
You can request a ready-made and configured test client from GDI Slack, or create your own OIDC RP client at [Life Science AAI service registration](https://spreg-legacy.aai.elixir-czech.org/).

Using the ready-made test client requires
- [LS AAI Test group membership](https://signup.aai.lifescience-ri.eu/fed/registrar/?vo=lifescience_test) (self-service)
- LS AAI Perun GDI test group membership (added by the test OIDC RP owner)

Place your OIDC RP credentials to the [config.edn](config.edn#L7-L8).

### Create a JWK pair for GA4GH visas
JWK is used to sign GA4GH visas which hold permissions for third parties.
```
pip install "Authlib>=1.2.0"
python generate_jwks.py
```
JWKs are stored in `private-key.jwk` and `public-key.jwk`.

## Starting REMS

- REMS will be served at <http://localhost:3000>
- Swagger API is available at <http://localhost:3000/swagger-ui/index.html>

### First time setup

Start and initialise the database
```
docker-compose up -d db
docker-compose run --rm -e CMD="migrate" app
```

Start REMS app
```
docker-compose up -d app
```

### Re-deployments

For re-deployments, when you already have an initialised database, you can simply run
```
docker-compose up -d
```

## Using REMS

### Get admin access

Read your username from http://localhost:3000/profile and grant yourself the `owner` role
```
export REMS_OWNER=<username>
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar grant-role owner $REMS_OWNER
```
A new `Administration` tab should now show up in the web interface.

### Load test data

Create an api key
```
export API_KEY=<some api key>
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add $API_KEY this is a test key
```

The purpose of this script is to quickly create dummy data for testing. If you want more freedom over REMS management, see the section below this one.

**This script is intended only to be run once on an empty database.**
```
./test_data.sh
```

You can now apply for access to the test dataset <localhost:3000/application?items=1> the application should be auto-approved.

### Create your own data

See [REMS repository](https://github.com/CSCfi/rems/blob/master/manual/owner.md) for documentation.

### Getting permissions out of REMS

Getting the permissions in [GA4GH passport format](https://github.com/ga4gh-duri/ga4gh-duri.github.io/blob/master/researcher_ids/ga4gh_passport_v1.md).

In a real deployment you would create a robot account, and an api key, and then register REMS as a visa provider in Life Science AAI. LS AAI would then provide REMS permissions in the `ga4gh_passport_v1` claim in your third party service.

### Create a robot user and an api key

Creating the robot user
```
curl -X POST http://localhost:3000/api/users/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
        "userid": "robot", "name": "Permission Robot", "email": null
    }'
```

Grant the robot the `reporter` role, so that it has privileges to get anyone's permissions, and then add an api key to the database and whitelist it so that only the robot can use it on the permission API.
```
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar grant-role reporter robot
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add robot-key this is a test key
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key set-users robot-key robot
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key allow robot-key get '/api/permissions/.*'
```

Using the robot and api key to get visas from the API
```
export ELIXIR_ID=<your username here>
curl http://localhost:3000/api/permissions/$ELIXIR_ID?expired=false \
    -H "content-type: application/json" \
    -H "x-rems-api-key: robot-key" \
    -H "x-rems-user-id: robot"
```
