# Terraform deployment

## Prerequisites

* A [kubernetes](https://kubernetes.io) cluster running version `~> 1.26.0` with [Cert-manager](https://cert-manager.io/) installed. If cert-manager is not available ask your kubernets administrator to install it for you.
* [Terraform](https://www.terraform.io) client `~> 1.6.0` installed on you local computer
* [Crypt4gh](https://github.com/neicnordic/crypt4gh/releases/latest) tool installed on you local computer
* A `crypth4gh` keypair to use when backing up the database
* A `crypth4gh` keypair to be used by the repository
* A kubernetes config file (your kubernetes administrator will supply you with this)

## Deployment

If the `crypt4gh` keypairs doesn't exists they can be created with the following commands:

```cmd
crypt4gh generate -n <NAME> -p <PASSPHRASE>
```

The backup private-key and passphrase needs to be stored in a safe location, they will only be used for disaster recovery.

Edit the `terraform.tfvars` file, all empty values needs to be filled in. The names are rather self explanatory.

After that the deployment can be triggered with the following command:

```cmd
terraform apply
```

If no errors are reported, answer `yes` sit back and watch the show.

Once everything is installed, extract the PostgreSQL and RabbitMQ root credentials and store them in a safe location.

```sh
terraform show -json | jq -r '.values.root_module.resources[] | select(.name == "postgres_root_password").values.result'
terraform show -json | jq -r '.values.root_module.resources[] | select(.name == "rabbitmq_admin_pass").values.result'
```

The state file contains sensitive information and should be encrypted unless stored in a safe location.

### DNS entries

Once everything is up and running the following endpoints will be made available:

* `https://download.DOMAIN`
* `https://inbox.DOMAIN`
* `https://login.DOMAIN`
* `https://rabbitmq.DOMAIN`

## Uninstallation

To remove everything including the namespace, just run the following command:

```cmd
terraform destryoy --auto-approve
```
