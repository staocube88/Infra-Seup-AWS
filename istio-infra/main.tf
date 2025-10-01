# ───────────────────────────────
# Provider Configuration
# ───────────────────────────────

# Kubernetes provider configuration
provider "kubernetes" {
  alias                  = "main"
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  token                  = var.cluster_token
  
  # Enable server-side apply for better resource management
  experiments {
    manifest_resource = true
  }
}

# Helm provider configuration
provider "helm" {
  alias = "main"

  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_cert)
    token                  = var.cluster_token
  }
  
  # Helm repository configuration
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/repository"
}

# ───────────────────────────────
# Namespace Configuration
# ───────────────────────────────

# Create Istio system namespace with proper labels and annotations
resource "kubernetes_namespace" "istio_system" {
  provider = kubernetes.main
  
  metadata {
    name = var.namespace_name
    
    labels = merge(var.tags, {
      "name"                                    = var.namespace_name
      "istio-injection"                         = "disabled"
      "app.kubernetes.io/name"                 = "istio-system"
      "app.kubernetes.io/part-of"              = "istio"
      "app.kubernetes.io/component"            = "system"
      "app.kubernetes.io/version"              = var.istio_version
      "app.kubernetes.io/managed-by"           = "terraform"
    })
    
    annotations = {
      "terraform.io/module"                    = "istio-infrastructure"
      "terraform.io/environment"               = var.environment
      "terraform.io/version"                   = var.istio_version
      "description"                            = "Istio service mesh system namespace"
    }
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# ───────────────────────────────
# RBAC Configuration
# ───────────────────────────────

# Service account for Istio components
resource "kubernetes_service_account" "istio_system" {
  provider = kubernetes.main
  
  metadata {
    name      = "istio-system"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
    
    labels = merge(var.tags, {
      "app.kubernetes.io/name"     = "istio-system"
      "app.kubernetes.io/part-of"  = "istio"
      "app.kubernetes.io/component" = "service-account"
    })
  }
  
  automount_service_account_token = true
}

# Cluster role for Istio system
resource "kubernetes_cluster_role" "istio_system" {
  provider = kubernetes.main
  
  metadata {
    name = "istio-system-${var.environment}"
    
    labels = merge(var.tags, {
      "app.kubernetes.io/name"     = "istio-system"
      "app.kubernetes.io/part-of"  = "istio"
      "app.kubernetes.io/component" = "cluster-role"
    })
  }
  
  rule {
    api_groups = [""]
    resources  = ["nodes", "pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "pods"]
    verbs      = ["get", "list", "watch"]
  }
  
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets"]
    verbs      = ["update", "patch"]
  }
  
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["update", "patch"]
  }
  
  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
  
  rule {
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
    verbs      = ["create"]
  }
}

# Cluster role binding for Istio system
resource "kubernetes_cluster_role_binding" "istio_system" {
  provider = kubernetes.main
  
  metadata {
    name = "istio-system-${var.environment}"
    
    labels = merge(var.tags, {
      "app.kubernetes.io/name"     = "istio-system"
      "app.kubernetes.io/part-of"  = "istio"
      "app.kubernetes.io/component" = "cluster-role-binding"
    })
  }
  
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.istio_system.metadata[0].name
  }
  
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.istio_system.metadata[0].name
    namespace = kubernetes_namespace.istio_system.metadata[0].name
  }
}

# ───────────────────────────────
# Istio Base Components
# ───────────────────────────────

# Deploy Istio Base Components
resource "helm_release" "istio_base" {
  provider = helm.main
  
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version
  
  # Wait for the release to be deployed
  wait = true
  timeout = 300
  
  # Create namespace if it doesn't exist
  create_namespace = false
  
  # Values for base configuration
  values = [
    yamlencode({
      global = {
        istioNamespace = var.namespace_name
        meshID         = var.mesh_id
        network        = var.network_name
        clusterName    = var.cluster_name
      }
    })
  ]
  
  # Labels for the release
  labels = merge(var.tags, {
    "app.kubernetes.io/name"     = "istio-base"
    "app.kubernetes.io/part-of"  = "istio"
    "app.kubernetes.io/component" = "base"
    "app.kubernetes.io/version"  = var.istio_version
  })
  
  lifecycle {
    prevent_destroy = true
  }
}

# ───────────────────────────────
# Istio Control Plane (istiod)
# ───────────────────────────────

# Deploy Istio Discovery (istiod)
resource "helm_release" "istiod" {
  provider = helm.main
  
  depends_on = [helm_release.istio_base]

  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version

  # Wait for the release to be deployed
  wait = true
  timeout = 600
  
  # Create namespace if it doesn't exist
  create_namespace = false
  
  # Service account
  set {
    name  = "pilot.serviceAccount"
    value = kubernetes_service_account.istio_system.metadata[0].name
  }
  
  # Values from file
  values = [
    file("${path.module}/values/istiod-values.yaml"),
    yamlencode({
      global = {
        istioNamespace = var.namespace_name
        meshID         = var.mesh_id
        network        = var.network_name
        clusterName    = var.cluster_name
        multiCluster = {
          enabled = var.enable_multi_cluster
        }
      }
      pilot = {
        resources = {
          requests = {
            cpu    = var.resource_requests.istiod.cpu
            memory = var.resource_requests.istiod.memory
          }
          limits = {
            cpu    = var.resource_limits.istiod.cpu
            memory = var.resource_limits.istiod.memory
          }
        }
        env = {
          PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION = true
          PILOT_ENABLE_CROSS_CLUSTER_WORKLOAD_ENTRY     = var.enable_multi_cluster
        }
      }
      telemetry = {
        enabled = var.enable_telemetry
        v2 = {
          enabled = var.enable_telemetry
        }
      }
      security = {
        enabled = var.enable_security
      }
    })
  ]
  
  # Labels for the release
  labels = merge(var.tags, {
    "app.kubernetes.io/name"     = "istiod"
    "app.kubernetes.io/part-of"  = "istio"
    "app.kubernetes.io/component" = "control-plane"
    "app.kubernetes.io/version"  = var.istio_version
  })
  
  lifecycle {
    prevent_destroy = true
  }
}

# ───────────────────────────────
# Istio Ingress Gateway
# ───────────────────────────────

# Deploy Istio Ingress Gateway (conditional)
resource "helm_release" "istio_ingress" {
  provider = helm.main
  
  count = var.enable_ingress_gateway ? 1 : 0
  
  depends_on = [helm_release.istiod]

  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version

  # Wait for the release to be deployed
  wait = true
  timeout = 300
  
  # Create namespace if it doesn't exist
  create_namespace = false
  
  # Values from file
  values = [
    file("${path.module}/values/istio-ingress-values.yaml"),
    yamlencode({
      service = {
        type = var.ingress_gateway_type
      }
      resources = {
        requests = {
          cpu    = var.resource_requests.ingress_gateway.cpu
          memory = var.resource_requests.ingress_gateway.memory
        }
        limits = {
          cpu    = var.resource_limits.ingress_gateway.cpu
          memory = var.resource_limits.ingress_gateway.memory
        }
      }
      labels = merge(var.tags, {
        "app.kubernetes.io/name"     = "istio-ingressgateway"
        "app.kubernetes.io/part-of"  = "istio"
        "app.kubernetes.io/component" = "ingress-gateway"
        "app.kubernetes.io/version"  = var.istio_version
      })
    })
  ]
  
  # Labels for the release
  labels = merge(var.tags, {
    "app.kubernetes.io/name"     = "istio-ingress"
    "app.kubernetes.io/part-of"  = "istio"
    "app.kubernetes.io/component" = "ingress-gateway"
    "app.kubernetes.io/version"  = var.istio_version
  })
}

# ───────────────────────────────
# Istio Egress Gateway (Optional)
# ───────────────────────────────

# Deploy Istio Egress Gateway (conditional)
resource "helm_release" "istio_egress" {
  provider = helm.main
  
  count = var.enable_egress_gateway ? 1 : 0
  
  depends_on = [helm_release.istiod]

  name       = "istio-egress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = kubernetes_namespace.istio_system.metadata[0].name
  version    = var.istio_version

  # Wait for the release to be deployed
  wait = true
  timeout = 300
  
  # Create namespace if it doesn't exist
  create_namespace = false
  
  # Values for egress gateway
  values = [
    yamlencode({
      service = {
        type = "ClusterIP"
        ports = [
          {
            port       = 80
            targetPort = 8080
            name       = "http2"
            protocol   = "TCP"
          },
          {
            port       = 443
            targetPort = 8443
            name       = "https"
            protocol   = "TCP"
          }
        ]
      }
      resources = {
        requests = {
          cpu    = var.resource_requests.egress_gateway.cpu
          memory = var.resource_requests.egress_gateway.memory
        }
        limits = {
          cpu    = var.resource_limits.egress_gateway.cpu
          memory = var.resource_limits.egress_gateway.memory
        }
      }
      labels = merge(var.tags, {
        "app.kubernetes.io/name"     = "istio-egressgateway"
        "app.kubernetes.io/part-of"  = "istio"
        "app.kubernetes.io/component" = "egress-gateway"
        "app.kubernetes.io/version"  = var.istio_version
      })
    })
  ]
  
  # Labels for the release
  labels = merge(var.tags, {
    "app.kubernetes.io/name"     = "istio-egress"
    "app.kubernetes.io/part-of"  = "istio"
    "app.kubernetes.io/component" = "egress-gateway"
    "app.kubernetes.io/version"  = var.istio_version
  })
}
