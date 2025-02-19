### credentials ###
resource "random_password" "download" {
  length  = 16
  special = false
}
resource "random_password" "finalize" {
  length  = 16
  special = false
}
resource "random_password" "inbox" {
  length  = 16
  special = false
}
resource "random_password" "ingest" {
  length  = 16
  special = false
}
resource "random_password" "mapper" {
  length  = 16
  special = false
}
resource "random_password" "verify" {
  length  = 16
  special = false
}

### namespace ###
resource "kubernetes_namespace_v1" "namespace" {
  metadata {
    annotations = {
      name = var.namespace
    }
    name = var.namespace
  }
}

### network policies
resource "kubernetes_network_policy_v1" "namespace_isolation" {
  depends_on = [kubernetes_namespace_v1.namespace]
  metadata {
    name      = "namespace-isolation"
    namespace = var.namespace
  }

  spec {
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    egress {
      to {
        pod_selector {}
      }
    }

    ingress {
      from {
        pod_selector {}
      }
    }

    pod_selector {}

    policy_types = ["Egress", "Ingress"]
  }
}

output "root_passwords" {
  value = tomap({"rabbitmq" = random_password.rabbitmq_admin_pass.result, "PostgreSQL" = random_password.postgres_root_password.result })
  sensitive = true
}

### provider configuration ###
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig-path
  }
}


provider "kubernetes" {
  config_path = var.kubeconfig-path
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}
