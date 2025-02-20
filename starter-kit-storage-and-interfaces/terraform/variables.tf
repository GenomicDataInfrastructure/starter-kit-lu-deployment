variable "db-backup-c4gh-public-key-path" {
  type = string
}
variable "ingress-base" {
  type = string
}
variable "ingress-deploy" {
  type = bool
}
variable "ingress-class" {
  type = string
}
variable "kubeconfig-path" {
  type = string
}
variable "letsencrypt-issuer" {
  type = string
}
variable "letsencrypt-notification-email" {
  type = string
}
variable "log-level" {
  type    = string
  default = "info"
}
variable "namespace" {
  type = string
}
variable "oidc-provider" {
  type = string
}
variable "oidc-client-id" {
  type = string
}
variable "oidc-client-secret" {
  type = string
}
variable "rabbitmq-admin-user" {
  type = string
}
variable "repository-c4gh-key-path" {
  type = string
}
variable "repository-c4gh-passphrase" {
  type = string
}
variable "repository-c4gh-public-key-path" {
  type = string
}
variable "sda-db-version" {
  type = string
}
variable "sda-mq-version" {
  type = string
}
variable "sda-services-backup-version" {
  type = string
}
variable "sda-svc-version" {
  type = string
}
variable "s3AccessKey" {
  type = string
}
variable "s3SecretKey" {
  type = string
}
variable "s3URL" {
  type = string
}
variable "s3BackupAccessKey" {
  type = string
}
variable "s3BackupSecretKey" {
  type = string
}
variable "s3BackupURL" {
  type = string
}
