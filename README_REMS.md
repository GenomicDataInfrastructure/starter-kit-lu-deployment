# Steps to reproduce this REMS setup
1. Clone [the Starter Kit REMS repository](https://github.com/GenomicDataInfrastructure/starter-kit-rems/tree/main) (`https://github.com/GenomicDataInfrastructure/starter-kit-rems/tree/main`) into `rems` directory.
2. In `docker-compose.yml`, rename services `app` to `rems_app` and `db` to `rems_db`. In `depends_on` section, rename `db` to `rems_db`.
3. In `config.edn` change `db` into `rems_db` in the database connection string: ` :database-url "postgresql://rems_db:5432/ (...redacted...)"`
4. Follow the _Create a JWK pair for GA4GH visas_ section of rems/README.md:
```
cd rems
pip install "Authlib>=1.2.0"
python generate_jwks.py
```
5. Run:
```
docker compose -f docker-compose-rems.yml up -d rems_db
docker compose -f docker-compose-rems.yml run --rm -e CMD="migrate" rems_app
docker compose -f docker-compose-rems.yml up -d rems_app
```
6. Consecutive runs can be started with `docker compose up -d`