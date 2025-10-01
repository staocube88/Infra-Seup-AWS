terraform {
  required_version = ">= 1.3.0"
  required_providers {
    kubernetes ={
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm  = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "istio/dev/terraform.tfstate"
    region = "us-east-1"
  }
}


# Kubernetes provider for your cluster (example for dev)
provider "kubernetes" {
  alias                  = "dev"
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  token                  = var.cluster_token
}

# Helm provider bound to Kubernetes
provider "helm" {
  alias = "dev"

  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    token                  = var.cluster_token
  }
}

# ───────────────────────────────
# Create Istio namespace
# ───────────────────────────────
resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}

# ───────────────────────────────
# Deploy Istio Base Components
# ───────────────────────────────
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version
}

# ───────────────────────────────
# Deploy Istio Discovery (istiod)
# ───────────────────────────────
resource "helm_release" "istiod" {
  depends_on = [helm_release.istio_base]

  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version

  values = [
    file("${path.module}/values/istiod-values.yaml")
  ]
}

# ───────────────────────────────
# Deploy Istio Ingress Gateway
# ───────────────────────────────
resource "helm_release" "istio_ingress" {
  depends_on = [helm_release.istiod]

  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version

  values = [
    file("${path.module}/values/istio-ingress-values.yaml")
  ]
}
