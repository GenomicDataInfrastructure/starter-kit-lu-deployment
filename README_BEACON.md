# Steps to reproduce Beacon
1. Clone `https://github.com/GenomicDataInfrastructure/starter-kit-beacon2-ri-api` into _beacon_ directory
2. We prepended names of the services in `deploy/docker-compose.yml` with "beacon-" wherever it's relevant
3. Run `docker network create my-app-network`
4. Run `docker compose -f docker-compose-beacon.yml up -d`