# Nginx as reverse proxy

The containerized nginx instance act as reverse proxy in front of multiple GDI endpoints.
For information, here is a table summarizing the mapping between GDI services (aka container names) and ports bindings.

| Mapped port | Container name                   |
| ----------- | -------------------------------- |
| 3000        | rems_app                         |
| 8080        | auth (storage and interfaces)    |
| 5050        | beacon                           |
| 3033        | htsget-server                    |
| 8443        | download (storage and interface) |
| 8003        | s3inbox (storage and interface)  |

Nginx container itself is listening on ports `8800/http` and `4433/https` and performs redirection to the above services.
This repository contains out-of-the-box self signed certificates for demonstration purposes only.


## Endpoints

`https://beacon.temp.gdi.lu:4433` 
`https://htsget.temp.gdi.lu:4433` 
`https://rems.temp.gdi.lu:4433` 
`https://sk.temp.gdi.lu:4433` 
`https://login.temp.gdi.lu:4433` 
`https://download.temp.gdi.lu:4433` 
`https://inbox.temp.gdi.lu:4433`


## Re-generating self signed certificates (optional)

Assuming the current working directory is `~/starter-kit-lu-deployment`:

1. Generate Diffie-Hellman parameters:
   
`$ openssl dhparam -out ./nginx/nginx/dhparam.pem 2048`

2. Generate certificates:
   
`$ openssl req -x509 -newkey rsa:4096 -keyout ssl/wildcard.temp.gdi.lu.key -out ./nginx/nginx/ssl/wildcard.temp.gdi.lu.crt -sha256 -days 365`

`$ openssl req -x509 -newkey rsa:4096 -keyout ssl/sk.temp.gdi.lu.key -out ./nginx/nginx/ssl/sk.temp.gdi.lu.crt -sha256 -days 365`

