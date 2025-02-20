resource "kubernetes_manifest" "ca_issuer" {
  depends_on = [kubernetes_namespace_v1.namespace]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "selfsigned-issuer"
      namespace = var.namespace
    }
    spec = {
      selfSigned = {}
    }
  }
}
resource "kubernetes_manifest" "internal_CAcert" {
  depends_on = [kubernetes_manifest.ca_issuer]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "selfsigned-ca"
      namespace = var.namespace
    }
    spec = {
      isCA        = true
      commonName  = "selfsigned-ca"
      secretName  = "root-ca-secret"
      duration    = "33333h0m0s"
      renewBefore = "30000h0m0s"
      privateKey = {
        algorithm = "ECDSA"
        size      = 256
      }
      issuerRef = {
        name  = kubernetes_manifest.ca_issuer.manifest.metadata.name
        kind  = kubernetes_manifest.ca_issuer.manifest.kind
        group = "cert-manager.io"
      }
    }
  }
}
resource "kubernetes_manifest" "internal_issuer" {
  depends_on = [kubernetes_manifest.internal_CAcert]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "internal-issuer"
      namespace = var.namespace
    }
    spec = {
      ca = {
        secretName = kubernetes_manifest.internal_CAcert.manifest.spec.secretName
      }
    }
  }
}
resource "kubernetes_manifest" "letsEncryptProd_issuer" {
  depends_on = [kubernetes_namespace_v1.namespace]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-production"
      namespace = var.namespace
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt-notification-email
        privateKeySecretRef = {
          name = "letsencrypt-prod-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
resource "kubernetes_manifest" "letsEncryptStaging_issuer" {
  depends_on = [kubernetes_namespace_v1.namespace]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-staging"
      namespace = var.namespace
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt-notification-email
        privateKeySecretRef = {
          name = "letsencrypt-staging-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
