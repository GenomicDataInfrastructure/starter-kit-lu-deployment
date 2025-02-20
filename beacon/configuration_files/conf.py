import logging
import yaml
from beacon.exceptions.exceptions import raise_exception

try:
    with open("beacon/conf/api_version.yml") as api_version_file:
        api_version_yaml = yaml.safe_load(api_version_file)
except Exception as e:# pragma: no cover
    err = str(e)
    errcode=500
    raise_exception(err, errcode)

level=logging.NOTSET
log_file='beacon/logs/logs.log'

# Beacon general info
beacon_id = 'lu.gdi.starter-kit'
beacon_name = 'European Genomic Data Infrastructure Luxembourgish Beacon'
description = (r"This Beacon is based on the GA4GH Beacon v2.0")
api_version = 'v2.0.0'
uri = 'https://beacon.dev.gdi.lu/api/'
welcome_url = 'https://beacon.dev.gdi.lu/'
alternative_url = 'https://beacon.dev.gdi.lu/api/'
environment = 'test'
# version = 'v2.0'
version = api_version_yaml['api_version']
create_datetime = '2024-10-28T12:00:00.000000'
update_datetime = ''

# Service configuration
default_beacon_granularity = "record" # boolean, count or record
security_levels = ['PUBLIC', 'REGISTERED', 'CONTROLLED']
documentation_url = 'https://b2ri-documentation-demo.ega-archive.org/'
alphanumeric_terms = ['libraryStrategy', 'molecularAttributes.geneIds', 'diseases.ageOfOnset.iso8601duration', 'molecularAttributes.aminoacidChanges']
cors_urls = ["http://localhost:3000", "https://beacon-network-demo2.ega-archive.org", "https://beacon.dev.gdi.lu"]


# Service Info
ga4gh_service_type_group = 'org.ga4gh'
ga4gh_service_type_artifact = 'beacon'
ga4gh_service_type_version = '1.0'

# Organization info
org_id = 'LNDS'
org_name = 'Luxembourg National Data Service'
org_description = ('Luxembourg National Data Service - a brand of PNED G.I.E.')
org_adress = ('Luxembourg National Data Service'
    '6, avenue des Hauts-Fourneaux, L-4362  Esch-sur-Alzette'
    'Luxembourg'
)
org_welcome_url = 'https://lnds.lu'
org_contact_url = 'mailto:sysadmins@lnds.lu'
org_logo_url = 'https://assets.dev.gdi.lu/logo.png'
org_info = ''

# TLS
beacon_server_crt = ''
beacon_server_key = ''