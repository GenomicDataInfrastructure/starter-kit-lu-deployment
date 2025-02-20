# GDI Starter Kit - Luxembourgish deployment

## Getting started
This repository was created to help you get started with GDI Starter Kit (<https://github.com/GenomicDataInfrastructure>), based on experiences of Luxembourgish node.

We would like to provide you with:
 * some notes that we took when deploying components of the GDI Starter Kit
 * an all-in-one Docker compose script to get you started fast
 * some instructions on what to do next (regarding configuration or loading the data)

Generally, each repository for Starter Kit components contains already a readme file with exact steps to be taken to successfully deploy.
In this repository, we cloned all the original source code and modified them to have only one compose script. You can review the individual readme and compose files to check the relevant notes and how-to instructions.

## Status
This project is ongoing and not fully operational yet. 
The instructions should get you a running Beacon, Molgenis, htsget, cBioPortal, and a nginx reverse proxy.
Running Storages and interfaces and loading the data might require some more hacking.

## Components

| Component | Original repository | Short description |
| :---        |    :----:   |          :--- |
| Molgenis Emx2 | [link](https://github.com/molgenis/molgenis-emx2.git) |  Open source solutions for scientific data |
| Beacon | [link](https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api) | A discoverability service - an API to query for variants, individuals etc. |
| LS:AAI mock | [link](https://github.com/GenomicDataInfrastructure/starter-kit-lsaai-mock) | Mock of Life Sciences AAI. Not needed if you created LS:AAI OIDC client. |
| Storages and Interfaces | [link](https://github.com/GenomicDataInfrastructure/starter-kit-storage-and-interfaces) | Set of components related to storage of datasets (e.g. minio)  |
| htsget | [link](https://github.com/GenomicDataInfrastructure/starter-kit-htsget) | Server to stream sensitive genomics data |

While a reverse proxy is not a part of original Starter Kit, we added it for the convenience (nginx).

## Instructions

### Preparatory
```
# Create a docker network - if needed
docker network create my-app-network
```

You can use:
```
docker compose -f docker-compose.yml up -d
```
docker compose -f docker-compose.yml down
```

## Modifications and notes
If you are interested in what modifications were made compared to the original repositories, take a look in the relevant readme files, e.g.:
* [REMS](-/blob/main/README_REMS.md)
* [Beacon](-/blob/main/README_BEACON.md)
