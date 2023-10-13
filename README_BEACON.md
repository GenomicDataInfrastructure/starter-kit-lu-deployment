# Steps to reproduce Beacon
1. Clone `https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api` into _beacon_ directory
2. We prepended names of the services in `deploy/docker-compose.yml` with "beacon-" wherever it's relevant
3. Run `docker network create my-app-network`
4. Run `docker compose -f docker-compose-beacon.yml up -d`

In our deployment, we modified the `/deploy/docker-compose.yml` file so that it contains:

```
  ###########################################
  # MongoDB Database
  ###########################################

  db:
    ...
    volumes:
      - ./mongo-init/:/docker-entrypoint-initdb.d/:ro
      - /mnt/directory_with_almost_1tb_free_space:/data/db
```

This ensures that the container uses a mounted directory to store its data.

# Additional steps
## Configuration in `deploy/conf.py`
We changed:
* `beacon_id`, `beacon_name`, `uri` in _Beacon general info_
* Whole _Organization info_ section
* Whole _Project info_ section
* `service_url` to `https://$BEACON_HOST/api/services` (substitute the envvar with your URI)
* `beacon_handovers` to 
```
beacon_handovers = [
    {
        'handoverType': {
            'id': 'CUSTOM',
            'label': 'Request data through REMS'
        },
        'note': 'Request data through REMS',
        'url': 'https://rems.temp.gdi.lu/catalogue'
    }
]
```
* _IdP endpoints_ section: `idp_client_id` and `idp_client_secret` to match the OIDC Client ID and secret (see README_REMS for more information)

Additionally:
```
idp_user_info  = 'https://proxy.aai.lifescience-ri.eu/OIDC/userinfo'
idp_introspection = 'https://proxy.aai.lifescience-ri.eu/OIDC/introspect'
```

# Loading data into Beacon
We recommend taking a look on https://b2ri-documentation.readthedocs.io/en/latest/tutorial-data-beaconization/ first.

## Introduction
A couple of facts and links:

* BFF == Beacon-Friendly Format, detailed description below.
* Beacon’s source code & basic instructions: <https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api/tree/master>
* Beacon’s deployment and data loading instructions <https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api/tree/master/deploy>
* Beacon’s ingestion tool (to transform data into the BFF) <https://github.com/EGA-archive/beacon2-ri-tools/tree/main>
* Beacon’s tool to convert an Excel file with metadata (Individuals, Cohorts, Runs, Biosamples, Datasets) into BFF <https://github.com/EGA-archive/beacon2-ri-tools/tree/main/utils/bff_validator>
* The Starter-kit implementation of Beacon uses MongoDB under the hood.

## Beacon-friendly format, the BFF
It is essentially a collection of files (sometimes gzip-compressed) that are conformant to Beacon2 Models (see https://github.com/ga4gh-beacon/beacon-v2/tree/main/models/src and https://docs.genomebeacons.org/models/)

* analyses.json
* biosamples.json
* cohorts.json
* datasets.json
* individuals.json
* runs.json
* genomicVariationsVcf.json

First six files are created from Excel template using beacon2-ri-tools' bff_validator.

The information about variants (genomicVariationsVcf.json) are created using the ingestion tool.

## Example files
* Example BFF set that can be loaded as dummy data - https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api/tree/master/deploy/data

* Filled XLSX template with information about CINECA dataset: https://github.com/EGA-archive/beacon2-ri-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1

## Operational manual
The steps assume that there is a VM:
* running a container with beacon-ri-tools.
* with a lot (I'd say minimum 1TB if you are going to transform a vcf file into BFF) of storage (e.g. NFS mounted in `/mnt`) and accessible from the container
* the beacon starter kit is deployed in e.g. `/opt/gdi/starter-kit-beacon2-ri-api`
 
## Transforming VCF files into BFF
Installation - following the steps of https://github.com/EGA-archive/beacon2-ri-tools/tree/main

### Preparing beacon2-ri-tools container
1. As we are working with pretty big files, we assume that we are working on NFS drive, and that the containers (MongoDB and Ingestion Tools) have also their volumes mounted on NFS.
2. Go to e.g. `/opt/gdi/starter-kit-data`, ensure that it contains a Dockerfile (you can get it by wget `https://raw.githubusercontent.com/EGA-archive/beacon2-ri-tools/main/Dockerfile`). Ensure that the container is built (`docker build -t crg/beacon2_ri:latest . # build the container` (~1.1G))
3. Run `docker run -tid --name beacon2-ri-tools crg/beacon2_ri:latest # run the image detached`.
4. Then exec:
`docker exec -ti beacon2-ri-tools bash # connect to the container interactively`
`nohup beacon2-ri-tools/BEACON/bin/deploy_external_tools.sh &` to get the working directory ready.

### Transforming the XLSX file into BFF
**Warning - the steps below are more of notes, than step-by-step instructions.**

1. Use scp to upload the xlsx file into the VM.
2. Move the file into the directory that is mounted to the container.
```
# As a devops user (e.g. username)
sudo su
cp /home/username/beacon.xlsx /mnt/beacon-ri/beacon2-ri-tools/utils/bff_validator/beacon.xlsx
```
3. Get into the container, and call the transformation script.
```
# As gdi user
docker exec -ti beacon2-ri-tools bash

root@4dd586f156bd:/usr/share/beacon-ri/input_vcfs# cd /usr/share/beacon-ri/beacon2-ri-tools/utils/bff_validator/bff_outdir
mkdir -p bff_outdir
./bff-validator -i ./beacon.xlsx -o bff_outdir
```
4. Then, just for the sake of having clean paths, copy the files into the directory (you can also just symlink).
```
# As a devops user
sudo su
cp /mnt/beacon-ri/beacon2-ri-tools/utils/bff_validator/bff_outdir /opt/gdi/starter-kit-beacon2-ri-api/deploy/data/

su gdi
cd ~/starter-kit-beacon2-ri-api/deploy
```
5. Then follow the steps from https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api/tree/master/deploy to copy the files into the container and load them. Note that we are skipping the one with variations:
```
# As gdi user
cd bff_outdir
docker cp ./analyses.json deploy-db-1:tmp/analyses.json
docker cp ./biosamples.json deploy-db-1:tmp/biosamples.json
docker cp ./cohorts.json deploy-db-1:tmp/cohorts.json
docker cp ./datasets.json deploy-db-1:tmp/datasets.json
docker cp ./individuals.json deploy-db-1:tmp/individuals.json
docker cp ./runs.json deploy-db-1:tmp/runs.json  

docker exec deploy-db-1 mongoimport --jsonArray --uri "mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin" --file /tmp/datasets.json --collection datasets
docker exec deploy-db-1 mongoimport --jsonArray --uri "mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin" --file /tmp/analyses.json --collection analyses
docker exec deploy-db-1 mongoimport --jsonArray --uri "mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin" --file /tmp/biosamples.json --collection biosamples
docker exec deploy-db-1 mongoimport --jsonArray --uri "mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin" --file /tmp/cohorts.json --collection cohorts
docker exec deploy-db-1 mongoimport --jsonArray --uri "mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin" --file /tmp/individuals.json --collection individuals
docker exec deploy-db-1 mongoimport --jsonArray --uri "mongodb://root:example@127.0.0.1:27017/beacon?authSource=admin" --file /tmp/runs.json --collection runs

# You can remove the files from /tmp now
```
6. Finally, re-index the data
```
# As gdi user
docker exec beacon python beacon/reindex.py

# optionally (the two lines below should not matter, I run them just in case)
docker exec beacon python beacon/db/extract_filtering_terms.py
docker exec beacon python beacon/db/get_descendants.py
```

