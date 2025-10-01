# ───────────────────────────────
# Istio Infrastructure Outputs
# ───────────────────────────────

# Namespace information
output "istio_namespace" {
  description = "The Istio system namespace"
  value       = kubernetes_namespace.istio_system.metadata[0].name
}

output "istio_namespace_uid" {
  description = "The UID of the Istio system namespace"
  value       = kubernetes_namespace.istio_system.metadata[0].uid
}

# Istio Base component information
output "istio_base_release_name" {
  description = "The name of the Istio base Helm release"
  value       = helm_release.istio_base.name
}

output "istio_base_release_version" {
  description = "The version of the Istio base Helm release"
  value       = helm_release.istio_base.version
}

output "istio_base_release_status" {
  description = "The status of the Istio base Helm release"
  value       = helm_release.istio_base.status
}

# Istiod (Control Plane) information
output "istiod_release_name" {
  description = "The name of the Istiod Helm release"
  value       = helm_release.istiod.name
}

output "istiod_release_version" {
  description = "The version of the Istiod Helm release"
  value       = helm_release.istiod.version
}

output "istiod_release_status" {
  description = "The status of the Istiod Helm release"
  value       = helm_release.istiod.status
}

# Istio Ingress Gateway information
output "istio_ingress_release_name" {
  description = "The name of the Istio ingress gateway Helm release"
  value       = helm_release.istio_ingress.name
}

output "istio_ingress_release_version" {
  description = "The version of the Istio ingress gateway Helm release"
  value       = helm_release.istio_ingress.version
}

output "istio_ingress_release_status" {
  description = "The status of the Istio ingress gateway Helm release"
  value       = helm_release.istio_ingress.status
}

# Cluster information
output "cluster_endpoint" {
  description = "The Kubernetes cluster endpoint"
  value       = var.cluster_endpoint
  sensitive   = true
}

output "istio_version" {
  description = "The installed Istio version"
  value       = var.istio_version
}

# Service endpoints (if available)
output "istio_ingress_gateway_service" {
  description = "The Istio ingress gateway service information"
  value = {
    name      = "istio-ingressgateway"
    namespace = kubernetes_namespace.istio_system.metadata[0].name
    type      = "LoadBalancer"
  }
}

# Installation summary
output "installation_summary" {
  description = "Summary of the Istio installation"
  value = {
    namespace           = kubernetes_namespace.istio_system.metadata[0].name
    istio_version       = var.istio_version
    components_installed = [
      helm_release.istio_base.name,
      helm_release.istiod.name,
      helm_release.istio_ingress.name
    ]
    installation_status = "completed"
  }
}
