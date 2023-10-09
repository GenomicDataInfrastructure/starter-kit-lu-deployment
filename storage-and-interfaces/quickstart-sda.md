# Quickstart guide to the SDA

This document contains information on how to work with the Sensitive Data Archive (SDA) from the GDI user perspective.

## Brief description of the storage and interfaces stack

The storage and interfaces software stack for the GDI-starter-kit consists of the following services:

| Component     | Description |
|---------------|------|
| broker        | RabbitMQ based message broker, [SDA-MQ](https://github.com/neicnordic/sda-mq). |
| database      | PostgreSQL database, [SDA-DB](https://github.com/neicnordic/sda-db). |
| storage       | S3 object store, demo uses Minio S3. |
| auth     | OpenID Connect relaying party and authentication service, [SDA-auth](https://github.com/neicnordic/sda-auth). |
| s3inbox       | Proxy inbox to the S3 backend store, [SDA-S3Proxy](https://github.com/neicnordic/sda-s3proxy). |
| download      | Data out solution for downloading files from the SDA, [SDA-download](https://github.com/neicnordic/sda-download). |
| SDA-pipeline     | The ingestion pipeline of the SDA, [SDA-pipeline](https://github.com/neicnordic/sda-pipeline). This comprises of the following core components: `ingest`, `verify`, `finalize` and `mapper`.|

Detailed documentation on the `sda-pipeline` can be found at: https://neicnordic.github.io/sda-pipeline/pkg/sda-pipeline/.

NeIC Sensitive Data Archive documentation can be found at: https://neic-sda.readthedocs.io/en/latest/ .

## Deployment

Before deploying the stack, please make sure that all configuration files are in place. The following files need to be created from their respective examples:

```shell
cp ./config/config.yaml.example ./config/config.yaml
cp ./config/iss.json.example ./config/iss.json
cp ./.env.example ./.env
```
no further editing to the above files is required for running the stack locally.

The storage and interfaces stack can be deployed with the use of the provided `docker-compose.yml` file by running

```shell
docker compose -f docker-compose.yml up -d
```

from the root of this repo. Please note that in the current form of the compose file, services are configured to work out-of-the-box with the [LS-AAI-mock](https://github.com/GenomicDataInfrastructure/starter-kit-lsaai-mock) service and some configuration of the latter is needed beforehand, see [here](./README.md##Starting-the-full-stack-with-LS-AAI-mock) for step-by-step instructions. The rationale behind this setup is to allow for a seamless transition to an environment with a *live* LS-AAI service as discussed briefly below.

Configuration can be further customized by changing the files listed at the top of the `./.env` file along with the `.env` file itself. Please bear in mind that environment variables take precedence over the `config.yaml` file.

Lastly, this repo includes a `docker-compose-demo.yml` file which deploys a standalone stack along with a demo of the sda services' functionality with test data. Details can be found [here](./README.md##Starting-the-stack-in-standalone-demo-mode).

### Adding TLS to internet facing services

Internet facing services such as `s3inbox`, `download` and `auth`, need to be secured via TLS certification. This can be most conveniently achieved by using [Let's Encrypt](https://letsencrypt.org/getting-started/) as Certificate Authority. Assuming shell access to your web host, a convenient way to set this up is through installing Certbot (or any other ACME client supported by Let's Encrypt). Detailed instructions on setting up Certbot for different systems can be found [here](https://certbot.eff.org/).

## Authentication for users with LS-AAI (mock or alive)

To interact with SDA services, users need to provide [JSON Web Token](https://jwt.io/) (JWT) authorization. Ultimately, tokens can be fetched by [LS-AAI](https://lifescience-ri.eu/ls-login/) upon user login to an OpenID Connect (OIDC) relaying party (RP) service that is [registered with LS-AAI](https://spreg-legacy.aai.elixir-czech.org/). An example of such an RP service is the [sda-auth](https://github.com/neicnordic/sda-auth), which is included in the present stack.

### sda-auth

Assuming users with a valid LS-AAI ID, they can obtain a JWT by logging in to the `sda-auth` service. This can be done by navigating to the `sda-auth` service URL (e.g. https://localhost:8085 for a local deployment or https://login.gdi.nbis.se for a live one) and clicking on the `Login` button. This will redirect the user to the LS-AAI login page where they can enter their credentials. Once authenticated, the user will be redirected back to the `sda-auth` service and a JWT will be issued. This is an access token which can be copied from the `sda-auth`'s page and used to interact with the SDA services like e.g. for authorizing calls to `sda-download`'s API as described in the [Downloading data](#downloading-data) section below.

From `sda-auth`'s page users can also download a configuration file for accessing the `s3inbox` service. This `s3cmd.conf` file containes the aforementioned access token along with other necessary information and it is described in detail in the [Uploading data](#uploading-data) section below.

## How to perform common user tasks

### Data encryption

The `sda-pipeline` only ingests files encrypted with the archive's `c4gh` public key. For instance, using the Go implementation of the [`crypt4gh` utility](https://github.com/neicnordic/crypt4gh) a file can be encrypted simply by running:

```shell
crypt4gh encrypt -f <file-to-encrypt> -p <sda-c4gh-public-key>
```

where `<sda-c4gh-public-key>` is the archive's public key. Note that `docker-compose.yml` stores the archive's c4gh public key in a volume named `shared`, see [below](#how-to-perform-common-admin-tasks) for how to extract it.

### Uploading data

Users can upload data to the SDA by transferring them directly to the archive's `s3inbox` with an S3 client tool such as [`s3cmd`](https://s3tools.org/s3cmd):

```shell
s3cmd -c s3cmd.conf put <path-to-file.c4gh> s3://<USER_LS-AAI_ID>/<target-path-to-file.c4gh>
```

where `USER_LS-AAI_ID` is the user's LS-AAI ID with the `@` replaced by a `_` and `s3cmd.conf` is a configuration file with the following content:

```ini
[default]
access_key = <USER_LS-AAI_ID>
secret_key = <USER_LS-AAI_ID>
access_token=<JW_TOKEN>
check_ssl_certificate = False
check_ssl_hostname = False
encoding = UTF-8
encrypt = False
guess_mime_type = True
host_base = <S3_INBOX_DOMAIN_NAME>
host_bucket = <S3_INBOX_DOMAIN_NAME>
human_readable_sizes = true
multipart_chunk_size_mb = 50
use_https = True
socket_timeout = 30
```

It is possible to download the `s3cmd.conf` file from the `sda-auth` service as described in the [Authentication for users with LS-AAI (mock or alive)](#authentication-for-users-with-ls-aai-mock-or-alive) section above. However, do note that `s3cmd.conf` downloaded from this service lacks the section header `[default]` which needs to be added manually if one wishes to use the file directly with `s3cmd`.

For example, a `s3cmd.conf` file downloaded from `auth` after deploying the stack locally (with LS-AAI-mock as OIDC) would look like this:

```ini
access_key = jd123_lifescience-ri.eu
secret_key = jd123_lifescience-ri.eu
access_token=eyJraWQiOiJyc2ExIiwidH...
check_ssl_certificate = False
check_ssl_hostname = False
encoding = UTF-8
encrypt = False
guess_mime_type = True
host_base = localhost:8000
host_bucket = localhost:8000
human_readable_sizes = true
multipart_chunk_size_mb = 50
use_https = True
socket_timeout = 30
```

where the acces token has been truncated for brevity. Please note that the option `use_https = True` is missing from the above file (therefore set implicitly to `False`) since the local deployment of the stack does not use TLS.

### The sda-cli tool

Instead of the tools above, users are **encouraged** to use [`sda-cli`](https://github.com/NBISweden/sda-cli), which is a tool specifically developed to perform all common SDA user-related tasks in a convenient and unified manner. It is recommended to use precompiled executables for `sda-cli` which can be found at https://github.com/NBISweden/sda-cli/releases

To start using the tool run:

```shell
./sda-cli help
```

#### Examples of common usage

- Encrypt and upload a file to the SDA in one go:

```shell
./sda-cli upload -config s3cmd.conf --encrypt-with-key <sda-c4gh-public-key> <unencrypted_file_to_upload>
```

- Encrypt and upload a whole folder recursively to a specified path, which can be different from the source, in one go:

```shell
./sda-cli upload -config s3cmd.conf --encrypt-with-key <sda-c4gh-public-key> -r <folder_1_to_upload> -targetDir <upload_folder>
```

- List all uploaded files in the user's bucket recursively:

```shell
./sda-cli list -config s3cmd.conf
```
For detailed documentation on the tool's capabilities and usage please refer [here](https://github.com/NBISweden/sda-cli#usage).

### Downloading data

Users can directly download data from the SDA via `sda-download`, for more details see the service's [api reference](https://github.com/neicnordic/sda-download/blob/main/docs/API.md). In short, given a [valid JW token](#sda-auth), `$token`,  a user can download the file with file ID, `$fileID` by issuing the following command:

```shell
curl --cacert <path-to-certificate-file> -H "Authorization: Bearer $token" https://<sda-download_DOMAIN_NAME>/files/$fileID -o <output-filename>
```

where for example `sda-download_DOMAIN_NAME` can be `login.gdi.nbis.se` or `localhost:8443` depending on the deployment. In the case of a local deployment, the certificate file can be obtained by running:

```shell
docker cp download:/shared/cert/ca.crt .
```

The `fileID` is a unique file identifier that can be obtained by calls to `sda-download`'s `/datasets` endpoint. For details and a concrete example on how to use `sda-download` with demo data please see [here](./README.md#get-token-or-downloading-data).

### Data access permissions

In order for a user to access a file, permission to access the dataset that the file belongs to is needed. This is granted through [REMS](https://github.com/CSCfi/rems) in the form of `GA4GH` visas. For details see [starter-kit documentation on REMS](https://github.com/GenomicDataInfrastructure/starter-kit-rems) and the links therein.

## How to perform common admin tasks

### The sda-admin tool

Within the scope of the starter-kit, it is up to the system administrator to curate incoming uploads to the Sensitive Data Archive. To ease this task, we have created the `sda-admin` tool which is a shell script that can perform all the necessary steps in order for an unencrypted file to end up properly ingested and archived by the SDA stack. The script  can be found under `scripts/` and can be used to upload and ingest files as well as assigning accession ID to archived files and linking them to a dataset.

In the background it utilizes the `sda-cli` for encrypting and uploading files and automates generating and sending broker messages between the SDA services. Detailed documentation on its usage along with examples can be retrieved upon running the command:

```shell
./sda-admin help
```

Below we provide a step-by-step example of `sda-admin` usage.

Create a test file:

```shell
dd if=/dev/random of=test_file count=1 bs=$(( 1024 * 1024 *  1 )) iflag=fullblock
```

Fetch the archive's `c4gh` public key (assuming shell access to the host machine):

```shell
docker cp ingest:/shared/c4gh.pub.pem .
```

**Encrypt and upload**

To encrypt and upload `test_file` to the s3inbox, first get a token and prepare a `s3cmd` configuration file as described in the section [Uploading data](#uploading-data) above. Then run the following:

```shell
./sda-admin --sda-config s3cmd.conf --sda-key c4gh.pub.pem upload test_file
```

One can verify that the encrypted file is uploaded in the archive's inbox by the following command:

```shell
sda-cli list --config s3cmd.conf
```

**Ingesting**

To list the filenames currently in the "inbox" queue waiting to be ingested run:

```shell
./sda-admin ingest
```

If `test_file.c4gh` is in the returned list, run:

```shell
./sda-admin ingest test_file
```
to trigger ingestion of the file.

**Adding accession IDs**

In brief, accesion IDs are unique identifiers that are assigned to files in order to be able to reference them in the future. Check that the file has been ingested by listing the filenames currently in the "verified" queue waiting to have accession IDs assigned to them:

```shell
./sda-admin accession
```

If `test_file.c4gh` is in the returned list, we can proceed with accession:

```shell
./sda-admin accession MYID001 test_file
```

where `MYID001` is the `accession ID` we wish to assign to the file.

**Mapping to datasets**

Check that the file got an accession ID by listing the filenames currently in the "completed" queue waiting to be associated with a dataset ID:

```shell
./sda-admin dataset
```

Lastly, associate the file with a dataset ID:

```shell
./sda-admin dataset MYSET001 test_file
```

Note that all the above steps can be done for multiple files at a time except from assigning accession IDs which needs to be done for one file at a time.

### Monitoring the status of services

Assuming access to a terminal session in the host machine of the deployed docker compose stack, the status of all running containers can be checked as per usual with the command: `docker ps` whereas all logs from the deployed  services can be monitored in real time as per usual by the command:

```shell
docker compose -f docker-compose.yml logs -f
```

or per service as:

```shell
docker compose -f docker-compose.yml logs <container-name> -f
```

Note that when applicable periodic `healthchecks` are in place to ensure that services are running normally. All containers are configured to always restart upon failure.

### Working with RabbitMQ

As stated, we use [RabbitMQ](https://www.rabbitmq.com/) as our message broker between different services in this stack. Monitoring the status of the broker service can most conveniently be done via the web interface, which is accessible at http://localhost:15672/ (use `https` if TLS is enabled). By default, `user:password` credentials with values `test:test` are created upon deployment and can be changed by editing the `docker-compose.yml` file. There are two ways to create a password hash for RabbitMQ as described [here](https://www.rabbitmq.com/passwords.html#computing-password-hash)

Broker messages are most conveniently generated by `scripts/sda-admin` as described above. If for some reason one wants to send MQ messages manually instead, there exist step-by-step examples [here](https://github.com/neicnordic/sda-pipeline/tree/master/dev_utils#json-formatted-messages).
