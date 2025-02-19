resource "random_password" "postgres_root_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "helm_release" "sda_db" {
  depends_on  = [kubernetes_namespace_v1.namespace]
  name        = "postgres"
  repository  = "https://neicnordic.github.io/sensitive-data-archive"
  chart       = "sda-db"
  version     = var.sda-db-version
  namespace   = var.namespace
  max_history = 3
  wait        = true

  values = [
    yamlencode(
      {
        "global" : {
          "postgresAdminPassword" : random_password.postgres_root_password.result,
          "tls" : {
            "issuer" : kubernetes_manifest.internal_issuer.manifest.metadata.name,
            "verifyPeer" : "verify-ca"
          }
        }
      }
    )
  ]
}
resource "kubernetes_secret_v1" "db_post_start_script" {
  depends_on = [kubernetes_namespace_v1.namespace]
  metadata {
    name      = "db-post-start-script"
    namespace = var.namespace
  }
  data = {
    "post-start.sh" = <<-EOF
      #!/bin/sh
      while [ ! "$(pg_isready -U postgres -h postgres-sda-db -d sda)" ]; do 
        echo "sleeping" && sleep 5
      done
      psql -h postgres-sda-db -U postgres -d sda -c "ALTER ROLE download LOGIN PASSWORD '${random_password.download.result}';"
      psql -h postgres-sda-db -U postgres -d sda -c "ALTER ROLE finalize LOGIN PASSWORD '${random_password.finalize.result}';"
      psql -h postgres-sda-db -U postgres -d sda -c "ALTER ROLE inbox LOGIN PASSWORD '${random_password.inbox.result}';"
      psql -h postgres-sda-db -U postgres -d sda -c "ALTER ROLE ingest LOGIN PASSWORD '${random_password.ingest.result}';"
      psql -h postgres-sda-db -U postgres -d sda -c "ALTER ROLE mapper LOGIN PASSWORD '${random_password.mapper.result}';"
      psql -h postgres-sda-db -U postgres -d sda -c "ALTER ROLE verify LOGIN PASSWORD '${random_password.verify.result}';"
    EOF
  }
}
resource "kubernetes_manifest" "job_certificate" {
  depends_on = [kubernetes_namespace_v1.namespace]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "job-cert"
      namespace = var.namespace
    }
    spec = {
      secretName = "job-cert"
      duration   = "2160h0m0s"
      privateKey = {
        algorithm = "Ed25519"
      }
      usages = [
        "client auth"
      ]
      dnsNames = [
        "localhost",
        "db-post-start-config"
      ]
      issuerRef = {
        name = kubernetes_manifest.internal_issuer.manifest.metadata.name
        kind = "Issuer"
      }
    }
  }
}
resource "kubernetes_job_v1" "sda_db_post_start_config" {
  depends_on = [helm_release.sda_db]
  metadata {
    name      = "db-post-start-config"
    namespace = var.namespace
  }
  spec {
    backoff_limit              = 1
    active_deadline_seconds    = 240
    ttl_seconds_after_finished = 300
    template {
      metadata {
        labels = {
          jobs = "post-start-config"
        }
      }
      spec {
        container {
          name              = "db-post-start-config"
          image             = "jombyl/postgresql-client"
          image_pull_policy = "Always"
          command           = ["/bin/sh", "/post-start.sh"]
          env {
            name  = "PGPASSWORD"
            value = random_password.postgres_root_password.result
          }
          env {
            name  = "PGSSLCERT"
            value = "/certs/tls.crt"
          }
          env {
            name  = "PGSSLKEY"
            value = "/certs/tls.key"
          }
          env {
            name  = "PGSSLROOTCERT"
            value = "/certs/ca.crt"
          }
          env {
            name  = "PGSSLMODE"
            value = "verify-ca"
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            run_as_non_root = true
          }
          volume_mount {
            name       = "db-post-start-script"
            mount_path = "/post-start.sh"
            sub_path   = "post-start.sh"
          }
          volume_mount {
            name       = "certs"
            mount_path = "/certs"
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/temp"
          }
        }
        restart_policy = "Never"
        security_context {
          fs_group        = 1000
          run_as_non_root = true
          run_as_user     = 1000
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        volume {
          name = "db-post-start-script"
          projected {
            sources {
              secret {
                name = kubernetes_secret_v1.db_post_start_script.metadata[0].name
              }
            }
          }
        }
        volume {
          name = "certs"
          projected {
            default_mode = "0400"
            sources {
              secret {
                name = kubernetes_manifest.job_certificate.manifest.metadata.name
              }
            }
          }
        }
        volume {
          name = "tmp"
          empty_dir {
            size_limit = "1Gi"
          }
        }
      }
    }
  }
}
resource "kubernetes_secret_v1" "backup-cronJob-secret" {
  metadata {
    name      = "backup-cronjob-secret"
    namespace = var.namespace
  }
  data = {
    "backup.c4gh.pub" = file(var.db-backup-c4gh-public-key-path)
    "config.yaml" = yamlencode({
      "crypt4ghPublicKey" : "./secrets/keys/backup.c4gh.pub",
      "db" : {
        "host" : "${helm_release.sda_db.name}-sda-db",
        "user" : "postgres",
        "password" : random_password.postgres_root_password.result,
        "database" : "sda",
        "cacert" : "./secrets/tls/ca.pem",
        "sslmode" : "verify-ca",
      },
      "s3" : {
        "url" : var.s3BackupURL,
        "accesskey" : var.s3BackupAccessKey,
        "secretkey" : var.s3BackupSecretKey,
        "bucket" : "${var.namespace}-db-backup",
      },
    })
  }
}
resource "kubernetes_cron_job_v1" "postgres_backup" {
  depends_on = [helm_release.sda_db]
  metadata {
    name      = "postgres-backup"
    namespace = var.namespace
  }
  spec {
    failed_jobs_history_limit     = 1
    schedule                      = "0 2 * * *"
    successful_jobs_history_limit = 1
    job_template {
      metadata {}
      spec {
        template {
          metadata {
            labels = {
              jobs = "backup"
            }
          }
          spec {
            container {
              name    = "postgres-backup"
              image   = "ghcr.io/nbisweden/sda-services-backup:${var.sda-services-backup-version}"
              command = ["/usr/local/bin/backup-svc", "--action", "pg_dump"]
              env {
                name  = "CONFIGPATH"
                value = "/.secrets/config.yaml"
              }
              resources {
                limits = {
                  cpu    = "100m"
                  memory = "128M"
                }
                requests = {
                  cpu    = "100m"
                  memory = "128M"
                }
              }
              security_context {
                allow_privilege_escalation = "false"
                capabilities {
                  drop = ["ALL"]
                }
              }
              volume_mount {
                name       = "tmp"
                mount_path = "/tmp"
              }
              volume_mount {
                name       = "tls-certs"
                mount_path = "/.secrets/tls"
              }
              volume_mount {
                name       = "cronjob"
                mount_path = "/.secrets/config.yaml"
                sub_path   = "config.yaml"
              }
              volume_mount {
                name       = "cronjob"
                mount_path = "/.secrets/keys/backup.c4gh.pub"
                sub_path   = "backup.c4gh.pub"
              }
            }
            security_context {
              fs_group    = 65534
              run_as_user = 65534
              seccomp_profile {
                type = "RuntimeDefault"
              }
            }
            volume {
              name = "tmp"
              empty_dir {
                size_limit = "1Gi"
              }
            }
            volume {
              name = "cronjob"
              projected {
                default_mode = "0400"
                sources {
                  secret {
                    name = kubernetes_secret_v1.backup-cronJob-secret.metadata[0].name
                  }
                }
              }
            }
            volume {
              name = "tls-certs"
              projected {
                default_mode = "0400"
                sources {
                  secret {
                    name = kubernetes_manifest.job_certificate.manifest.metadata.name
                  }
                }
              }
            }
          }
        }
        ttl_seconds_after_finished = 120
      }
    }
  }
}
