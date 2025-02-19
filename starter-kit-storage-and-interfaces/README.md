# starter-kit-storage-and-interfaces

There exist two compose files at the root of the repo. Details on how to use them are provided below.

**Note:** Before deploying the stack, please make sure that all configuration files are in place. The following files need to be created from their respective examples:

```shell
cp ./config/config.yaml.example ./config/config.yaml
cp ./config/iss.json.example ./config/iss.json
cp ./.env.example ./.env
```

no further editing to the above files is required for running the stack locally.

## Starting the full stack with LS-AAI-mock

To bootstrap the *full stack* of `storage-and-interfaces` services use the file `docker-compose.yml`. Note that this requires a running [`LS-AAI-mock`](https://github.com/GenomicDataInfrastructure/starter-kit-lsaai-mock) service. To configure the LS-AAI-mock service follow the instructions below.

First clone the [startet-kit-lsaai-mock](https://github.com/GenomicDataInfrastructure/starter-kit-lsaai-mock) repo.

Add the `sda-auth` client by creating a file `configuration/aai-mock/clients/client1.yaml` with the following contents:

```ini
client-name: "auth"
client-id: "XC56EL11xx"
client-secret: "wHPVQaYXmdDHg"
redirect-uris: ["http://localhost:8085/elixir/login"]
token-endpoint-auth-method: "client_secret_basic"
scope: ["openid", "profile", "email", "ga4gh_passport_v1", "eduperson_entitlement"]
grant-types: ["authorization_code"]
post-logout-redirect-uris: ["http://localhost:8085/elixir/login"]
```

Now that everything should be configured properly, from the root folder of the `starter-kit-lsaai-mock` run:

```shell
docker compose up -d
```

## Starting storage-and-interfaces with LS-AAI-mock

From the root of the `starter-kit-storage-and-interfaces` folder and run:

```shell
docker compose up -d
```

Note that the above two commands need to be run in that specific order because the `LS-AAI-mock` compose creates the external network `my-app-network` which is used to communicate with the `aai-mock` service.

## Starting the stack in standalone demo mode

The file `docker-compose-demo.yml` is used to start the `storage-and-interfaces` services in *demo* mode with an example dataset preloaded and ingested to the sensitive data archive when the deployment is done. This comes with its own python implementation of a mock-oidc in place of LS-AAI and can be run as standalone for demonstration purposes.

The files imported by the data loading script come from [here:](https://github.com/ga4gh/htsget-refserver/tree/main/data/gcp/gatk-test-data/wgs_bam)

To deploy use the following command:

```shell
docker compose -f docker-compose-demo.yml up -d
```

After deployment is done, follow the instructions below to test that the demo worked as expected.

### **Download unencrypted files directly**

### Get token for downloading data

For the purpose of the demo stack, tokens can be issued by the included `oidc` service and be used to authorize calls to the `download` service's API. The `oidc` is a simple Python implementation that mimics the basic OIDC functionality of LS-AAI. It does not require user authentication and serves a valid token through its `/token` endpoint:

```shell
token=$(curl -s -k https://localhost:8080/tokens | jq -r '.[0]')
```

This token is created upon deployment. See `scripts/make_credentials.sh` for more details. Note that the API returns a list of tokens where the first element is the token of interest, and the rest are tokens for [testing  `sda-download`](https://github.com/neicnordic/sda-download/blob/main/dev_utils/README.md#get-a-token).

### List datasets

```shell
curl -s -H "Authorization: Bearer $token" http://localhost:8443/metadata/datasets | jq .
```

### List files in a dataset

```shell
datasetID=$(curl -s -H "Authorization: Bearer $token" http://localhost:8443/metadata/datasets | jq -r .'[0]')
curl -s -H "Authorization: Bearer $token" "http://localhost:8443/metadata/datasets/$datasetID/files" | jq .
```

### Download a specific file

```shell
fileID=$(curl -s -H "Authorization: Bearer $token" "http://localhost:8443/metadata/datasets/$datasetID/files" | jq -r '.[0].fileId')
filename=$(curl -s -H "Authorization: Bearer $token" "http://localhost:8443/metadata/datasets/$datasetID/files" | jq -r '.[0].displayFileName' | cut -d '.' -f 1,2 )
curl -s -H "Authorization: Bearer $token" http://localhost:8443/files/$fileID -o "$filename"
```



# Luxembourg deployment notes

```

mkdir ssl
openssl rsa -in /etc/nginx/ssl/wildcard.dev.gdi.lu.key -text > ssl/pkey.pem
openssl x509 -in /etc/nginx/ssl/wildcard.dev.gdi.lu.crt -out ssl/fullchain.pem
cp /etc/nginx/ssl/wildcard.dev.gdi.lu.key ssl/wildcard.dev.gdi.lu.key
cp /etc/nginx/ssl/wildcard.dev.gdi.lu.crt ssl/wildcard.dev.gdi.lu.crt

docker volume create starter-kit-storage-and-interfaces_shared
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.crt /shared/cert/server.crt
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.crt /shared/cert/ca.crt
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.key /shared/cert/auth.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.key /shared/cert/mq.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.key /shared/cert/db.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.key /shared/cert/download.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.lu.key /shared/cert/server.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/fullchain.pem /shared/cert/fullchain.pem
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/pkey.pem /shared/cert/privkey.pem
```