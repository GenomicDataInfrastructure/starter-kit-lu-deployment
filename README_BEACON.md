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