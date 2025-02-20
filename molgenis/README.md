# Molgenis

# DEPLOYMENT --------------------------------

echo "Deploying new version on VM"
mkdir -p /srv/deployments/molgenis
cd /srv/deployments/molgenis
git clone https://github.com/molgenis/molgenis-emx2.git molgenis-emx2 || echo "Repo already exists"

cp ./configuration/docker-compose.yml \
   "/srv/deployments/molgenis/molgenis-emx2/docker-compose.yml"
cp /srv/secrets/molgenis/initdb.sql \
   "/srv/deployments/molgenis/molgenis-emx2/.docker/initdb.sql"
cp /srv/secrets/molgenis/.env \
   "/srv/deployments/molgenis/molgenis-emx2/.env"

echo "Upgrading molgenis via git"
cd /srv/deployments/molgenis/molgenis-emx2
git reset --hard
git pull

cp ./configuration/docker-compose.yml \
   "/srv/deployments/molgenis/molgenis-emx2/docker-compose.yml"
cp /srv/secrets/molgenis/initdb.sql \
   "/srv/deployments/molgenis/molgenis-emx2/.docker/initdb.sql"
cp /srv/secrets/molgenis/.env \
   "/srv/deployments/molgenis/molgenis-emx2/.env"

# MAINTENANCE --------------------------------

echo "Rebuilding and running molgenis"
cd /srv/deployments/molgenis/molgenis-emx2
docker compose up -d --build

echo "Running molgenis"
cd /srv/deployments/molgenis/molgenis-emx2
docker compose up -d

echo "Stopping molgenis"
cd /srv/deployments/molgenis/molgenis-emx2
docker compose stop

echo "Destroying molgenis"
cd /srv/deployments/molgenis/molgenis-emx2
docker compose down

echo "Checking status of services on VM"
cd /srv/deployments/molgenis/molgenis-emx2
docker compose ps
echo "Running containers:"
docker ps -a

