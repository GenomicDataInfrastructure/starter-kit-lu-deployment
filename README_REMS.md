# Steps to reproduce this REMS setup
1. Clone [the Starter Kit REMS repository](https://github.com/GenomicDataInfrastructure/starter-kit-rems/tree/main) (`https://github.com/GenomicDataInfrastructure/starter-kit-rems/tree/main`) into `rems` directory.
2. In `docker-compose.yml`, rename services `app` to `rems_app` and `db` to `rems_db`. In `depends_on` section, rename `db` to `rems_db`.
3. In `config.edn` change `db` into `rems_db` in the database connection string: ` :database-url "postgresql://rems_db:5432/ (...redacted...)"`
4. Follow the _Create a JWK pair for GA4GH visas_ section of rems/README.md:
```
cd rems
pip install "Authlib>=1.2.0"
python generate_jwks.py
```
5. Run:
```
docker compose -f docker-compose-rems.yml up -d rems_db
docker compose -f docker-compose-rems.yml run --rm -e CMD="migrate" rems_app
docker compose -f docker-compose-rems.yml up -d rems_app
```
6. Consecutive runs can be started with `docker compose up -d`

# Additional steps
## Configuring LS:AAI
1. If you are developing on localhost, you could use the  “Test LS:AAI secrets” (you would need to reach out to GDI team). This will give you the `:oidc-client-id` and `:oidc-client-secret` and allow to skip the next point and go directly to point #3.
2. If you don't have LS:AAI OIDC _client id_ and _client secret_, follow the steps from the documentation: [How to connect a service to the Life Science AAI](https://docs.google.com/document/d/17pNXM_psYOP5rWF302ObAJACsfYnEWhjvxAHzcjvfIE/view).
3. Fill `:oidc-client-id` and `:oidc-client-secret` in `config.edn`.
4. In case your client is in the test mode, you also need to enable the LS AAI test group membership for yourself here https://signup.aai.lifescience-ri.eu/fed/registrar/?vo=lifescience_test to be able to test it.

## Make yourself REMS owner
Please follow the steps from [the official repository](https://github.com/GenomicDataInfrastructure/starter-kit-rems/tree/main#using-rems). 

Below our notes:
```
export REMS_OWNER=<username>
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar grant-role owner $REMS_OWNER
```

The username must be the one that you see when you go to `/profile` under “username”.

## Create an API key and make a robot to get ga4gh visa
```
export API_KEY=redacted0-0000-0000-0000-0000000000000
export REMS_OWNER=<username>
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add $API_KEY starter-kit yohan key
curl -X POST http://localhost:3000/api/users/create \
    -H "content-type: application/json" \
    -H "x-rems-api-key: $API_KEY" \
    -H "x-rems-user-id: $REMS_OWNER" \
    -d '{
        "userid": "robot", "name": "Permission Robot", "email": null
    }'
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar grant-role reporter robot
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add robot-key this is a test key
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key set-users robot-key robot
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key allow robot-key get '/api/permissions/.*'


APIK=redacted0-0000-0000-0000-0000000000000
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key add $APIK robor API key
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key set-users $APIK robot
docker exec rems_app java -Drems.config=/rems/config/config.edn -jar rems.jar api-key allow $APIK get '/api/permissions/.*'
```

Then you can get the visas for any users using the robot:

```
export ELIXIR_ID=<username>
export THE_HOST=127.0.0.1:3000
curl https://$THE_HOST/api/permissions/$ELIXIR_ID?expired=false \
    -H "content-type: application/json" \
    -H "x-rems-api-key: robot-key" \
    -H "x-rems-user-id: robot"
```

## Creating resources in the instance
1. Use the web UI on https://$THE_HOST/catalogue to create Organisation, Licence, Workflow, Form, resource and a catalogue item.

---

# Additional relevant resources
* Documentation of LS:AAI for Service Providers: <https://lifescience-ri.eu/ls-login/documentation/service-provider-documentation/service-provider-documentation.html>
