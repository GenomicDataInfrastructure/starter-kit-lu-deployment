# GDI Starter Kit - Luxembourgish deployment

## Getting started
This repository was created to help you get started with GDI Starter Kit, based on experiences of Luxembourgish node.

We would like to provide you with an all-in-one Docker Compose script and set of instructions/notes to deploy the components of the Starter Kit (<https://github.com/GenomicDataInfrastructure>). 
Generally, each Starter Kit repository already contains a readme file with exact steps to be taken to successfully deploy.
In this repository, we cloned all the original source code and modified it to have only one compose script. 

## Status
This project is not complete yet. The instructions should get you Beacon, REMS and htsget running. Storages and interfaces part is not yet complete at the moment of writing this readme.

## Components

| Component | Original repository | Short description |
| :---        |    :----:   |          :--- |
| REMS | [link](https://github.com/GenomicDataInfrastructure/starter-kit-rems/tree/main) | Resource Entitlement Management System to manage access rights to datasets |
| Beacon | [link](https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api) | A discoverability service - an API to query for variants, individuals etc. |
| Storages and Interfaces | [link](https://github.com/GenomicDataInfrastructure/starter-kit-storage-and-interfaces) | Set of components related to storage of datasets (e.g. minio)  |
| htsget | [link](https://github.com/GenomicDataInfrastructure/starter-kit-htsget) | Server to stream sensitive genomics data |

## Instructions

### Preparatory
```
# Create a docker network
docker network create my-app-network

# Create and prepare REMS database
docker compose -f docker-compose-rems.yml up -d rems_db
docker compose -f docker-compose-rems.yml run --rm -e CMD="migrate" rems_app
```

### Starting the services for the first time
(Assuming that the REMS database is up)
```
docker compose -f docker-compose-rems.yml up -d rems_app
docker compose -f docker-compose-beacon.yml up -d
```

### Starting the services another time
(Assuming that the REMS database is down)
```
docker compose -f docker-compose-rems.yml up -d
docker compose -f docker-compose-beacon.yml up -d
```

### Stopping the services
```
docker compose -f docker-compose-rems.yml down
docker compose -f docker-compose-beacon.yml down
```

## Modifications
If you are interested in what modifications were made compared to the original repositories, take a look in the relevant readme files:
* [Beacon](-/blob/main/README_BEACON.md)
* [REMS](-/blob/main/README_REMS.md)