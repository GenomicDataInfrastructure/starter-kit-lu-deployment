# About htsget
The htsget protocol was selected for the `Data Reception` part of the GDI starter kit. Htsget enables for retrieval of files from the storage-and-interfaces archive. The specification of the protocol can be found [here](http://samtools.github.io/hts-specs/htsget.html).

The repository contains the implementation for the GDI starter kit, as well as a demo that can be used for understanding the product. Both solutions are packaged in the `docker-compose-htsget.yml` file. The major difference between the two implementations, is that the demo one can run on it's own, while the starter kit version requires some of the other GDI products in order to be functional.

More details regarding that and the way to run the services can be found in the sections below. After deciding whether you would like to run the demo or starter kit version, follow the instructions on the respective section.

## Disclaimer
**Important Note:** The current implementation of the htsget server **does not** allow for partial retrieval of a file. Therefore, only full files should be requested. This feature will be developed in future versions of the product.


## HTSGET Configuration
The configuration for the htsget server should exist in the folder called `config-htsget`. Detailed description of the configuration options can be found in the [reference implementation repository](https://github.com/ga4gh/htsget-refserver#setup---native).

## Running the services - Demo
The demo profile of the docker compose, apart for the htsget server, contains a minio S3 that can be used as a storage backend and a data downloader that extracts a file in the `output` directory. Specifically, the S3 storage is being populated with the `NA12878.bam` file included in the `demo-data` folder of this repository. The data downloader is then setting the required environment variables and using `samtools` to make a request to the `htsget server`, which gives access to the requested file.

In order to run the demo version of htsget, first follow the instructions about removing tls at the bottom of this file and then run
```sh
docker compose -f docker-compose-htsget.yml --profile demo up
```
Once all the services have completed, you should be able to find the `output` folder in the root of the repository, containing the `NA12878.bam` file.

If you are interested in the commands used for extracting the data, you can check the `data_downloader` section of the `docker-compose-htsget.yml` file.

## Running the services - Starter kit version
The htsget product of the starter kit depends on the storage-and-interfaces product. Specifically, the data served has to be ingested and stored in the archive included in the [storage-and-interfaces repository](https://github.com/GenomicDataInfrastructure/starter-kit-storage-and-interfaces). Therefore, in order to test the implementation, the two docker compose files (the storage-and-interfaces and the htsget) need to be started together, so that they share the same network and the different containers have access between them.

To start the services, start the individual docker compose environments from their respective root directories:
```sh
starter-kit-storage-and-interfaces$ docker compose up -d
starter-kit-htsget$ docker compose -f docker-compose-htsget.yml up -d
```

The logs for the two docker compose files can be accessed using the following commands for storage-and-interfaces and htsget respectively
```sh
starter-kit-storage-and-interfaces$ docker compose -f docker-compose.yml logs -f
starter-kit-htsget$ docker compose -f docker-compose-htsget.yml logs -f
```

## Accessing data with htsget
In order to test the htsget implementation, there needs to be some data ingested in the archive. In case you do not have any data to ingest, follow the procedure in the [add data section](#(optional)-add-data) before continuing in this section.

## Get file information
**NOTE:** The sections below assume that data has been ingested in the archive.

In order to make sure files exist in the database and in order to get the ids needed in order to request one of them using htsget "execute" into the database container using:
```sh
docker exec -it postgres bash
```
Connect to the postgres database using
```sh
psql -h localhost -U postgres lega
```
with password `rootpass` and run the following query
```sh
select datasets.stable_id, files.stable_id, submission_file_path from sda.file_dataset join sda.files on file_id = files.id full join sda.datasets on file_dataset.id = sda.datasets.id;
```
You should be able to see some files and the dataset they have been added to. This information will be used in the next step in order to request one of the files.

## Request a file with samtools

Now that all the information regarding the ingested files is available, it should be possible to access a file using the htsget protocol. One way to do that, is using samtools, included in the `docker-compose-htsget.yml` file.

Start by executing in the samtools container with
```sh
docker exec -it samtools-client bash
```
1. The samtools client requires two variables to be exported, and a token containing the visas for the specified user to be provided. Set the two environment variables required using
```sh
export HTS_ALLOW_UNENCRYPTED_AUTHORIZATION_HEADER="I understand the risks"
export HTS_AUTH_LOCATION=token.txt
```
If you are running the htsget server with TLS, you also need to point the `CURL_CA_BUNDLE` to the `ca.crt`. This can be done using
```sh
export CURL_CA_BUNDLE=/shared/cert/ca.crt
```

2. Get the token from the OIDC endpoint by running
```sh
curl -k -s -S https://dockerhost:8080/tokens | jq -r '.[0]' > token.txt
```
3. Finally get the file using
```sh
samtools view https://server:3033/reads/s3/<dataset_id>/<file_path_without.c4gh>
```
where `dataset_id` and `file_path` are the results from the query to the database. For example, if you are using the data from the starter-kit-storage-and-interfaces repository, the command should be
```sh
samtools view https://server:3033/reads/s3/EGAD74900000101/dummy_gdi.eu/NA12878.bam
```

### (Optional) Add data
In case you do not have any data to ingest, there exists a [script](https://github.com/GenomicDataInfrastructure/starter-kit-storage-and-interfaces/blob/main/scripts/load_data.sh) that can load a very small sample dataset in the storage-and-interface repository, which can be executed using the same docker compose file.

To run the container executing this script run
```sh
starter-kit-storage-and-interfaces$ docker compose up data_loader
```
Once the script has completed, the data should be loaded.


### TLS configuration
In order to run the htsget with TLS enabled, the easiest way is to use the storage-and-interfaces docker compose, which creates the certificates, and point to the shared volume where they rely.

If you want to start the docker compose without tls, 
1. remove the line `- starter-kit-storage-and-interfaces_shared:/shared` from the docker-compose-htsget.yml.
1. remove the `starter-kit-storage-and-interfaces_shared:` and `external: true` from the docker-compose-htsget.yml volumes.
1. remove the `"serverCert": "/shared/cert/server.crt",` and `"serverKey": "/shared/cert/server.key"` configuration from the config-htsget/config.json file.
1. remove the line `volumes:` and `- starter-kit-storage-and-interfaces_shared:/shared` lines from the samtools client service of the docker-compose-htsget.yml.

