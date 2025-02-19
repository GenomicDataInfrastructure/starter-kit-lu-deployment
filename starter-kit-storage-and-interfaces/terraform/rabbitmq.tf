resource "random_password" "rabbitmq_admin_pass" {
  length  = 16
  special = false
}
resource "helm_release" "sda_mq" {
  lifecycle {
    precondition {
      condition     = var.ingress-base != ""
      error_message = "Variable ingress-base needs to be set"
    }
  }
  depends_on  = [kubernetes_namespace_v1.namespace]
  name        = "rabbitmq"
  chart       = "sda-mq"
  repository  = "https://neicnordic.github.io/sensitive-data-archive"
  version     = var.sda-mq-version
  namespace   = var.namespace
  max_history = 3
  wait        = true

  values = [
    yamlencode(
      {
        "global" : {
          "adminPassword" : random_password.rabbitmq_admin_pass.result,
          "adminUser" : var.rabbitmq-admin-user,
          "ingress" : {
            "hostName" : "rabbitmq.${var.ingress-base}",
            "issuer" : var.letsencrypt-issuer,
          },
          "tls" : {
            "issuer" : kubernetes_manifest.internal_issuer.manifest.metadata.name,
            "verifyPeer" : "false",
          },
          "persistence" : {
            "enabled" : "true",
          },
        }
      }
    )
  ]
}

resource "kubernetes_secret_v1" "mq_post_start_script" {
  depends_on = [kubernetes_namespace_v1.namespace]
  metadata {
    name      = "mq-post-start-script"
    namespace = var.namespace
  }
  data = {
    "post-start.sh" = <<EOF
#!/bin/sh
while [[ "$(curl --cacert /certs/ca.crt -u "$MQ_USER:$MQ_PASS" -o /dev/null -w '%%{http_code}' https://${helm_release.sda_mq.name}-sda-mq:15671/api/users)" != "200" ]]; do
    echo "sleeping" && sleep 5
done
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/users/finalize \
    -H "content-type:application/json" -d '{"password": "'"${random_password.finalize.result}"'", "tags":"none"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/users/inbox \
    -H "content-type:application/json" -d '{"password": "'"${random_password.inbox.result}"'", "tags":"none"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/users/ingest \
    -H "content-type:application/json" -d '{"password":"'"${random_password.ingest.result}"'", "tags":"none"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/users/mapper \
    -H "content-type:application/json" -d '{"password":"'"${random_password.mapper.result}"'", "tags":"none"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/users/verify \
    -H "content-type:application/json" -d '{"password":"'"${random_password.verify.result}"'", "tags":"none"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/permissions/sda/finalize \
    -H "content-type:application/json" -d '{"configure":"","write":"sda","read":"accession"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/permissions/sda/inbox \
    -H "content-type:application/json" -d '{"configure":"","write":"sda","read":""}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/permissions/sda/ingest \
    -H "content-type:application/json" -d '{"configure":"","write":"sda","read":"ingest"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/permissions/sda/mapper \
    -H "content-type:application/json" -d '{"configure":"","write":"","read":"mappings"}'
curl --cacert /certs/ca.crt -s -u "$MQ_USER:$MQ_PASS" -X PUT https://${helm_release.sda_mq.name}-sda-mq:15671/api/permissions/sda/verify \
    -H "content-type:application/json" -d '{"configure":"","write":"sda","read":"archived"}'
EOF
  }
}
resource "kubernetes_manifest" "rabbitmq_startup_job_certificate" {
  depends_on = [kubernetes_namespace_v1.namespace]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "rabbitmq-startup-job-certificate"
      namespace = var.namespace
    }
    spec = {
      secretName = "rabbitmq-startup-job-certificate"
      duration   = "17532h0m0s"
      commonName = "post-start-config"
      privateKey = {
        algorithm = "ECDSA"
      }
      usages = [
        "server auth",
        "client auth"
      ]
      dnsNames = [
        "localhost",
        "post-start-config",
      ]
      issuerRef = {
        name = kubernetes_manifest.internal_issuer.manifest.metadata.name
        kind = "Issuer"
      }
    }
  }
}
resource "kubernetes_job_v1" "sda_mq_post_start_config" {
  depends_on = [helm_release.sda_mq]
  metadata {
    name      = "mq-post-start-config"
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
          name              = "mq-post-start-config"
          image             = "curlimages/curl"
          image_pull_policy = "Always"
          command           = ["/bin/sh", "/post-start.sh"]
          env {
            name  = "MQ_USER"
            value = var.rabbitmq-admin-user
          }
          env {
            name = "MQ_PASS"
            value_from {
              secret_key_ref {
                key  = "password"
                name = "${helm_release.sda_mq.name}-sda-mq"
              }
            }
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            run_as_non_root = true
          }
          volume_mount {
            name       = "mq-post-start-script"
            mount_path = "/post-start.sh"
            sub_path   = "post-start.sh"
          }
          volume_mount {
            name       = "certs"
            mount_path = "/certs"
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
          name = "mq-post-start-script"
          projected {
            sources {
              secret {
                name = kubernetes_secret_v1.mq_post_start_script.metadata[0].name
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
                name = kubernetes_manifest.rabbitmq_startup_job_certificate.manifest.metadata.name
              }
            }
          }
        }
      }
    }
  }
}
resource "kubernetes_network_policy_v1" "rabbitmq" {
  depends_on = [kubernetes_namespace_v1.namespace]
  metadata {
    name      = "rabbitmq-policy"
    namespace = var.namespace
  }

  spec {
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
        release = "rabbitmq"
      }
    }

    policy_types = ["Ingress"]
  }
}
