# Steps to reproduce this SaI setup
1. Clone [the Starter Kit SaI repository](https://github.com/GenomicDataInfrastructure/starter-kit-storage-and-interfaces) (`https://github.com/GenomicDataInfrastructure/starter-kit-storage-and-interfaces`) into `storage-and-interfaces` directory.
2. Follow the project's readme file to create `config.yaml` and `iss.json` files in the `config` directory. Take a look on the example files in this repository. 

# Some notes from our deployment

## Prepare certificates

```
docker volume create starter-kit-storage-and-interfaces_shared
cp -r /etc/nginx/ssl ssl
openssl rsa -in ssl/wildcard.dev.gdi.temp.key -text > ssl/privkey.pem
openssl x509 -in ssl/wildcard.dev.gdi.temp.crt -out ssl/fullchain.pem

docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.crt /shared/cert/server.crt
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.crt /shared/cert/ca.crt
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.key /shared/cert/auth.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.key /shared/cert/mq.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.key /shared/cert/db.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.key /shared/cert/download.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/wildcard.dev.gdi.temp.key /shared/cert/server.key
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/fullchain.pem /shared/cert/fullchain.pem
docker run --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source alpine cp ssl/privkey.pem /shared/cert/privkey.pem
```

## Preparing encryption
```
docker run -it --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source ubuntu bash
apt update && apt install -y curl jq openssl
export C4GH_VERSION="1.7.3"
curl -s -L https://github.com/neicnordic/crypt4gh/releases/download/v"${C4GH_VERSION}"/crypt4gh_linux_x86_64.tar.gz | tar -xz -C /shared/ && chmod +x /shared/crypt4gh
/shared/crypt4gh generate -n /shared/c4gh -p c4ghpass
```

## Create endpoint for crypt4gh key
Create the s3config (remember to replace "HERE GOES..." parts).

**TODO: what are the uuid for?**
```
docker run -it --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source ubuntu bash
apt update && apt install -y curl jq openssl
openssl ecparam -genkey -name prime256v1 -noout -out /shared/keys/oidc.key
openssl ec -in /shared/keys/oidc.key -outform PEM -pubout >/shared/keys/pub/oidc.pub
chmod 644 /shared/keys/pub/oidc.pub /shared/keys/oidc.key

iat=$(date --date='yesterday' +%s)
exp=$(date --date="${3:-tomorrow}" +%s)
PAYLOAD=$(jq -c -n --arg at_hash "J_fA458SPsXFV6lJQL1l-w" --arg aud "HERE GOES OIDC_CLIENT_ID FROM LS:AAI" --argjson exp "$exp" --argjson iat "$iat" --arg iss "https://oidc" --arg kid "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", --arg name "Dummy Tester" --arg sid "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --arg sub "gdi-public" '$ARGS.named')
token=$(bash ./scripts/sign_jwt.sh ES256 /shared/keys/oidc.key tomorrow "$PAYLOAD")

cat >/source/s3cfg <<EOD
access_key=access
secret_key=secretkey
access_token=$token
check_ssl_certificate = False
check_ssl_hostname = False
encoding = UTF-8
encrypt = False
guess_mime_type = True
host_base = localhost:8003
host_bucket = localhost:8003
human_readable_sizes = true
multipart_chunk_size_mb = 50
use_https = True
socket_timeout = 30
EOD
```

Usage:
```
s3cmd -c s3cfg  mb s3://gdi-public
s3cmd -c s3cfg put c4gh.pub.pem s3://gdi-public/key/
s3cmd -c s3cfg setacl s3://gdi-public/key/c4gh.pub.pem --acl-public ### PERMISSION DENIED HERE
```

**TODO**: previous step is not resolved yet (permission denied)

## Uploading data to the archive
Getting the tool:

```
wget https://github.com/NBISweden/sda-cli/releases/download/v0.0.6/sda-cli_.0.0.6_Linux_x86_64.tar.gz
tar -xvzf sda-cli_.0.0.6_Linux_x86_64.tar.gz
```

## Generate s3access
Generate the key:

```
docker run -it --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source ubuntu bash
apt update && apt install -y curl jq openssl
openssl ecparam -genkey -name prime256v1 -noout -out /shared/keys/s3access.key
openssl ec -in /shared/keys/s3access.key -outform PEM -pubout >/shared/keys/pub/s3access.pub
chmod 644 /shared/keys/pub/s3access.pub /shared/keys/s3access.key
```

In another terminal: `docker compose restart s3inbox`

## Generate the config:

```
# docker run -it --rm -v $PWD:/source -v  starter-kit-storage-and-interfaces_shared:/shared -w /source ubuntu bash
# apt update && apt install -y curl jq openssl
iat=$(date --date='yesterday' +%s)
exp=$(date --date="${3:-tomorrow}" +%s)
PAYLOAD=$(jq -c -n --arg at_hash "XXXXXXXXXXXXXXXXXXXXXX" --arg aud "HERE GOES OIDC CLIENT ID FROM LS:AAI" --argjson exp "$exp" --argjson iat "$iat" --arg iss "https://s3access" --arg kid "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", --arg name "Dummy Tester" --arg sid "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --arg sub "access" '$ARGS.named')
token=$(bash ./scripts/sign_jwt.sh ES256 /shared/keys/s3access.key tomorrow "$PAYLOAD")

cat >/source/s3access <<EOD
access_key=access
secret_key=secretkey
access_token=$token
check_ssl_certificate = False
check_ssl_hostname = False
encoding = UTF-8
encrypt = False
guess_mime_type = True
host_base = inbox.dev.gdi.temp
host_bucket = inbox.dev.gdi.temp
human_readable_sizes = true
multipart_chunk_size_mb = 50
use_https = True
socket_timeout = 30
EOD
```

## Upload the data (here we upload 1F4)

```
fname=1F4
fullpath=/mnt/synth-data/$fname  # Change to your path with data
./sda-cli encrypt -key c4gh.pub.pem "$fullpath"
./sda-cli upload -config s3access "$fullpath".c4gh -targetDir datasets

./scripts/sda-admin --sda-config s3access ingest datasets/$fname.c4gh
./scripts/sda-admin --sda-config s3access accession GDIF00$fname datasets/$fname.c4gh
./scripts/sda-admin --sda-config s3access dataset GDID00$fname  datasets/$fname.c4gh
```

## Other notes
 
This need the latest version of curl installed

```
# latest version of curl
dnf install openssl-devel
git clone https://github.com/curl/curl.git
cd curl

autoreconf -fi
./configure --with-openssl
make
make install
```

## Interacting with the download API
Get the token from https://login.dev.gdi.temp. The token is the last from the list.

Then export it: `export JWT=............................`

### Get the list of dataset you have access
```
curl -L -H "Authorization: Bearer $JWT" https://download.dev.gdi.temp/metadata/datasets
```

If the list is empty then make an application to rems.dev.gdi.temp.

### Get files in the dataset
```
# with gdi-temp-dataset the ID of the dataset in the below request
curl -L -H "Authorization: Bearer $JWT" https://download.dev.gdi.temp/metadata/datasets/gdi-temp-dataset/files
```

Get the fileId from the previous command and use it to get the file (eg: here we download File with ID GDI001F2).

```
curl -L -H "Authorization: Bearer $JWT" https://download.dev.gdi.temp/files/GDIF001F2 > test.gz
```
