# Beacon

## Links
* [General information about the deploment](https://lnds.atlassian.net/wiki/spaces/TEAMS/pages/352682030/Milestone+8+MS08+MS8). 
* [Beacon Production Implementation on Github](https://github.com/EGA-archive/beacon2-pi-api/tree/main)
* [Beacon RI Tools on Github](https://github.com/EGA-archive/beacon2-ri-tools-v2/tree/main)

echo "Dummy test for merge request"

# DEPLOYMENT --------------------------------

echo "Deploying new version on VM"
mkdir -p /srv/deployments/beacon
cd /srv/deployments/beacon
git clone https://github.com/EGA-archive/beacon2-pi-api.git beacon2-pi-api || echo "Repo already exists"
cp ./configuration_files/conf.py "/srv/deployments/beacon/beacon2-pi-api/beacon/conf/conf.py"
cp ./configuration_files/docker-compose.yml "/srv/deployments/beacon/beacon2-pi-api/docker-compose.yml"
cp ./configuration_files/public_datasets.yml "/srv/deployments/beacon/beacon2-pi-api/beacon/permissions/datasets/public_datasets.yml"
cp ./configuration_files/registered_datasets.yml "/srv/deployments/beacon/beacon2-pi-api/beacon/permissions/datasets/registered_datasets.yml"
cp ./patches/auth_main.py "/srv/deployments/beacon/beacon2-pi-api/beacon/auth/__main__.py"
cp ./patches/beacon_main.py "/srv/deployments/beacon/beacon2-pi-api/beacon/__main__.py"
cp /srv/secrets/auth.env "/srv/deployments/beacon/beacon2-pi-api/beacon/auth/idp_providers/lsaai.env"

echo "Upgrading beacon"
cd /srv/deployments/beacon/beacon2-pi-api
git reset --hard
git pull
cp ./configuration_files/conf.py "/srv/deployments/beacon/beacon2-pi-api/beacon/conf/conf.py"
cp ./configuration_files/docker-compose.yml "/srv/deployments/beacon/beacon2-pi-api/docker-compose.yml"
cp ./configuration_files/public_datasets.yml "/srv/deployments/beacon/beacon2-pi-api/beacon/permissions/datasets/public_datasets.yml"
cp ./configuration_files/registered_datasets.yml "/srv/deployments/beacon/beacon2-pi-api/beacon/permissions/datasets/registered_datasets.yml"
cp ./patches/auth_main.py "/srv/deployments/beacon/beacon2-pi-api/beacon/auth/__main__.py"
cp ./patches/beacon_main.py "/srv/deployments/beacon/beacon2-pi-api/beacon/__main__.py"
cp /srv/secrets/auth.env "/srv/deployments/beacon/beacon2-pi-api/beacon/auth/idp_providers/lsaai.env"

# MAINTENANCE --------------------------------

echo "Rebuilding and running beacon"
cd /srv/deployments/beacon/beacon2-pi-api
docker compose up -d --build

echo "Running beacon"
cd /srv/deployments/beacon/beacon2-pi-api
docker compose up -d

echo "Stopping beacon"
cd /srv/deployments/beacon/beacon2-pi-api
docker compose stop

echo "Destroying beacon"
cd /srv/deployments/beacon/beacon2-pi-api
docker compose down

echo "Checking status of services on VM"
cd /srv/deployments/beacon/beacon2-pi-api
docker compose ps
echo "Running containers:"
docker ps -a
