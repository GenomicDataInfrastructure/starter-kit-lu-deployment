### configurations
db-backup-c4gh-public-key-path = ""
kubeconfig-path                = ""

### container tags
sda-services-backup-version = "v0.1.34"

### helm chart versions
sda-db-version  = "0.8.8"
sda-mq-version  = "0.7.9"
sda-svc-version = "0.23.4"

### ingress
### ingress-base is the root domain, all exposed services will be reachable as sub domains.
ingress-base                   = ""
ingress-class                  = "nginx"
ingress-deploy                 = true
letsencrypt-issuer             = "letsencrypt-production"
letsencrypt-notification-email = ""

### Kubernetes namespace where everything should be deployed
namespace = ""

### RabbitMQ admin user
rabbitmq-admin-user = "admin"

### Storage backend configuration
oidc-provider      = "https://login.elixir-czech.org/oidc"
oidc-client-id     = ""
oidc-client-secret = ""

repository-c4gh-key-path        = ""
repository-c4gh-passphrase      = ""
repository-c4gh-public-key-path = ""

s3URL       = ""
s3AccessKey = ""
s3SecretKey = ""
### the S3 backup loation stores both archived files and the database backups
s3BackupURL       = ""
s3BackupAccessKey = ""
s3BackupSecretKey = ""
