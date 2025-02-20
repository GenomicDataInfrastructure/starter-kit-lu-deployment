resource "kubernetes_secret_v1" "c4gh" {
  depends_on = [kubernetes_namespace_v1.namespace]
  metadata {
    name      = "c4gh"
    namespace = var.namespace
  }
  data = {
    "c4gh.sec.pem" = file(var.repository-c4gh-key-path)
    "c4gh.pub.pem" = file(var.repository-c4gh-public-key-path)
    "passphrase"   = var.repository-c4gh-passphrase
  }
}
resource "helm_release" "sda_pipeline" {
  depends_on = [
    kubernetes_secret_v1.c4gh,
    kubernetes_job_v1.sda_db_post_start_config,
    kubernetes_job_v1.sda_mq_post_start_config
  ]
  name        = "pipeline"
  chart       = "sda-svc"
  repository  = "https://neicnordic.github.io/sensitive-data-archive"
  version     = var.sda-svc-version
  namespace   = var.namespace
  max_history = 3
  wait        = true

  values = [
    yamlencode(
      {
        "credentials" : {
          "download" : {
            "dbUser" : "download",
            "dbPassword" : random_password.download.result,
            "mqUser" : "download",
            "mqPassword" : random_password.download.result,
          },
          "finalize" : {
            "dbUser" : "finalize",
            "dbPassword" : random_password.finalize.result,
            "mqUser" : "finalize",
            "mqPassword" : random_password.finalize.result,
          },
          "inbox" : {
            "dbUser" : "inbox",
            "dbPassword" : random_password.inbox.result,
            "mqUser" : "inbox",
            "mqPassword" : random_password.inbox.result,
          },
          "ingest" : {
            "dbUser" : "ingest",
            "dbPassword" : random_password.ingest.result,
            "mqUser" : "ingest",
            "mqPassword" : random_password.ingest.result,
          },
          "mapper" : {
            "dbUser" : "mapper",
            "dbPassword" : random_password.mapper.result,
            "mqUser" : "mapper",
            "mqPassword" : random_password.mapper.result,
          },
          "verify" : {
            "dbUser" : "verify",
            "dbPassword" : random_password.verify.result,
            "mqUser" : "verify",
            "mqPassword" : random_password.verify.result,
          },
        },
        "global" : {
          "archive" : {
            "storageType" : "s3",
            "s3Url" : var.s3URL,
            "s3Bucket" : "${var.namespace}-archive",
            "s3AccessKey" : var.s3AccessKey,
            "s3SecretKey" : var.s3SecretKey,
          },
          "auth" : {
            "resignJwt" : false,
          },
          "backupArchive" : {
            "storageType" : "s3",
            "s3Url" : var.s3BackupURL,
            "s3Bucket" : "${var.namespace}-backup",
            "s3AccessKey" : var.s3BackupAccessKey,
            "s3SecretKey" : var.s3BackupSecretKey,
          },
          "broker" : {
            "host" : "${helm_release.sda_mq.name}-sda-mq",
            "exchange" : "sda",
            "vhost" : "sda",
            "prefetchCount" : "0",
          },
          "c4gh" : {
            "secretName" : kubernetes_secret_v1.c4gh.metadata[0].name,
            "keyFile" : "c4gh.sec.pem",
            "passphrase" : var.repository-c4gh-passphrase,
            "publicFile" : "c4gh.pub.pem",
          },
          "db" : {
            "host" : "${helm_release.sda_db.name}-sda-db",
            "sslMode" : "verify-ca",
          },
          "doa" : {
            "enabled" : false,
          },
          "download" : {
            "enabled" : "true",
            "trusted" : {
              "iss" : jsonencode([{ "iss" : var.oidc-provider, "jku" : "${var.oidc-provider}/jwk" }]),
            }
          },
          "inbox" : {
            "deploy" : "true",
            "storageType" : "s3",
            "s3Url" : var.s3URL,
            "s3Bucket" : "${var.namespace}-inbox",
            "s3AccessKey" : var.s3AccessKey,
            "s3SecretKey" : var.s3SecretKey,
          },
          "ingress" : {
            "deploy" : var.ingress-deploy,
            "hostName" : {
              "auth" : "login.${var.ingress-base}",
              "download" : "download.${var.ingress-base}",
              "inbox" : "inbox.${var.ingress-base}",
            },
            "ingressClassName" : var.ingress-class,
            "issuer" : var.letsencrypt-issuer,
          },
          "oidc" : {
            "provider" : var.oidc-provider,
            "id" : var.oidc-client-id,
            "secret" : var.oidc-client-secret,
          },
          "log.level" : var.log-level,
          "schemaType" : "standalone",
          "tls" : {
            "issuer" : kubernetes_manifest.internal_issuer.manifest.metadata.name,
          },
        }
        "intercept.deploy" : "false",
      }
    )
  ]
}
### allowed external IPs for networkpolicies ###
data "dns_a_record_set" "s3HostIP" {
  host = regex("^?://(?P<hostname>[^/?#:]*)?", var.s3URL)["hostname"]
}
data "dns_a_record_set" "s3BackupHostIP" {
  host = regex("^?://(?P<hostname>[^/?#:]*)?", var.s3BackupURL)["hostname"]
}
data "dns_a_record_set" "lifescienceAAI" {
  host = regex("^?://(?P<hostname>[^/?#:]*)?", var.oidc-provider)["hostname"]
}
locals {
  https_enpoints = concat(data.dns_a_record_set.s3HostIP.addrs, data.dns_a_record_set.s3BackupHostIP.addrs, data.dns_a_record_set.lifescienceAAI.addrs)
}
data "kubernetes_endpoints_v1" "api_endpoints" {
  metadata {
    name      = "kubernetes"
    namespace = "default"
  }
}
resource "kubernetes_network_policy_v1" "pipeline" {
  depends_on = [kubernetes_namespace_v1.namespace]
  metadata {
    name      = "pipeline-policy"
    namespace = var.namespace
  }

  spec {
    egress {
      dynamic "to" {
        for_each = local.https_enpoints
        content {
          ip_block {
            cidr = "${to.value}/32"
          }
        }
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    ingress {
      dynamic "from" {
        for_each = flatten(toset(data.kubernetes_endpoints_v1.api_endpoints.subset[*].address))
        content {
          ip_block {
            cidr = "${from.value.ip}/32"
          }
        }
      }
      ports {
        port     = 80
        protocol = "TCP"
      }
      ports {
        port     = 443
        protocol = "TCP"
      }
    }
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name" = "ingress-nginx"
          }
        }
      }
    }

    pod_selector {
      match_labels = {
        release = "pipeline"
      }
    }

    policy_types = ["Egress", "Ingress"]
  }
}
