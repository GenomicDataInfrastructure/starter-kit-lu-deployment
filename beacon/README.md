# Beacon v2.x

<!-- [![Testsuite](https://github.com/EGA-archive/beacon-2.x/workflows/Testsuite/badge.svg)](https://github.com/EGA-archive/beacon-2.x/actions) -->

This repository is an implementation of the [Beacon v2.0 Model](https://github.com/ga4gh-beacon/beacon-v2-Models) and contains:

* The (Python 3.9+) [source code for beacon](beacon),
* A MongoDB database with sample data to demo the capabilities of the Beacon API.
* AAI and LS-AAI integrated. For LS-AAI, gdi ls aai mock repository is required to be up and running in another docker compose service, and then you will need to create this external network:
```bash
docker network create my-app-network
```

> [Local deployment instructions](deploy/README.md)

# LifeScience Authentication and Authorisation

### Managing permissions with Beacon

There are three levels of datasets security: PUBLIC, REGISTERED AND CONTROLLED.
If you wish to make a dataset PUBLIC, just add it in the list of the [public_datasets.yml](beacon/request/public_datasets.yml) file.
If you wish to make a dataset REGISTERED, add it to all the users' permissions list in the [permissions.yml](permissions/permissions.yml) file. 
If you wish to make a dataset CONTROLLED, add it only to the users that have rights to access the dataset in their list of dataset permissions in the [permissions.yml](permissions/permissions.yml) file.
Please, bear in mind that the name of the user has to be the same that you used when creating the user in LS.

### Managing permissions with GA4GH Visas

If you want to allow a user to query a dataset with GA4GH Visas, you also can. Just add the GA4GH Visa in your headers with the title GA4GH Passport, like this: ```-H 'GA4GH_Passport: (token)``` and it will authorize your user for the dataset. 

### Authentication flow with LS AAI

First, log in with LS in the LS page. After having logged in, you will need to get the authorization code following LS-AAI authorization flow method with a browser pasting the next link (modifying the link with your client id) https://login.elixir-czech.org/oidc/auth/authorize?response_type=code&client_id=pasteyourclientidhere. Then, you will need to keep this code and also get your registry service client id and client secret key and then pass the three variables via the next POST request to get the authorization token:
```bash
curl --location --request POST 'https://login.elixir-czech.org/oidc/token' \--header 'Content-Type: application/x-www-form-urlencoded' \--data-urlencode 'grant_type=authorization_code' \--data-urlencode 'code=paste_your_authorization_code_here' \--data-urlencode 'client_id=paste_your_client_id_here' \--data-urlencode 'client_secret=paste_your_client_secret_here' \--data-urlencode 'scope=openid' \
--data-urlencode 'requested_token_type=urn:ietf:params:oauth:token-type:refresh_token'
```
When you have your authorization token, pass it in a header in your POST request to get your authenticated response.

### Beacon ready for Beacon Network

In order to add your beacon to the Beacon Network, please modify the file conf.py inside beacon folder and edit these variables with your beacon's info:
```bash
beacon_id = 'org.ega-archive.ga4gh-approval-beacon-test'  # ID of the Beacon
beacon_name = 'GA4GH Approval Beacon Test'  # Name of the Beacon service
api_version = 'v2.0.0'  # Version of the Beacon implementation
uri = 'https://ega-archive.org/test-beacon-apis/cineca/'
```

### Version notes

* Fusions (`mateName`) are not supported.

### Acknowlegments

We thank the [CSC Finland](https://www.csc.fi/) team for their
contribution with a [python implementing of version
1](https://github.com/CSCfi/beacon-python). They, in turn, got help
from members of [NBIS](https://nbis.se/) and
[DDBJ](https://www.ddbj.nig.ac.jp).
