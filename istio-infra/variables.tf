# ───────────────────────────────
# Istio Infrastructure Variables
# ───────────────────────────────

variable "cluster_endpoint" {
  description = "Kubernetes API server endpoint URL"
  type        = string
  validation {
    condition     = can(regex("^https://", var.cluster_endpoint))
    error_message = "The cluster_endpoint must be a valid HTTPS URL starting with 'https://'."
  }
}

variable "cluster_ca_cert" {
  description = "Base64 encoded CA certificate for the Kubernetes cluster"
  type        = string
  sensitive   = true
  validation {
    condition     = can(base64decode(var.cluster_ca_cert))
    error_message = "The cluster_ca_cert must be a valid base64 encoded certificate."
  }
}

variable "cluster_token" {
  description = "Service account token for accessing the Kubernetes cluster"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.cluster_token) > 0
    error_message = "The cluster_token cannot be empty."
  }
}

variable "istio_version" {
  description = "Version of Istio Helm charts to install"
  type        = string
  default     = "1.22.1"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.istio_version))
    error_message = "The istio_version must be in the format 'X.Y.Z' (e.g., '1.22.1')."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "namespace_name" {
  description = "Name of the Istio system namespace"
  type        = string
  default     = "istio-system"
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace_name))
    error_message = "The namespace_name must be a valid Kubernetes namespace name (lowercase alphanumeric and hyphens only)."
  }
}

variable "enable_ingress_gateway" {
  description = "Whether to deploy the Istio ingress gateway"
  type        = bool
  default     = true
}

variable "enable_egress_gateway" {
  description = "Whether to deploy the Istio egress gateway"
  type        = bool
  default     = false
}

variable "ingress_gateway_type" {
  description = "Service type for the ingress gateway (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "LoadBalancer"
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.ingress_gateway_type)
    error_message = "The ingress_gateway_type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
}

variable "mesh_id" {
  description = "Unique identifier for the Istio mesh"
  type        = string
  default     = "mesh1"
  validation {
    condition     = length(var.mesh_id) > 0
    error_message = "The mesh_id cannot be empty."
  }
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "cluster-1"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster_name cannot be empty."
  }
}

variable "network_name" {
  description = "Name of the network for multi-cluster setup"
  type        = string
  default     = "network1"
  validation {
    condition     = length(var.network_name) > 0
    error_message = "The network_name cannot be empty."
  }
}

variable "enable_multi_cluster" {
  description = "Enable multi-cluster configuration"
  type        = bool
  default     = false
}

variable "enable_telemetry" {
  description = "Enable Istio telemetry components"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable Istio security components"
  type        = bool
  default     = true
}

variable "resource_limits" {
  description = "Resource limits for Istio components"
  type = object({
    istiod = object({
      cpu    = string
      memory = string
    })
    ingress_gateway = object({
      cpu    = string
      memory = string
    })
    egress_gateway = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    istiod = {
      cpu    = "2000m"
      memory = "4096Mi"
    }
    ingress_gateway = {
      cpu    = "2000m"
      memory = "1024Mi"
    }
    egress_gateway = {
      cpu    = "2000m"
      memory = "1024Mi"
    }
  }
}

variable "resource_requests" {
  description = "Resource requests for Istio components"
  type = object({
    istiod = object({
      cpu    = string
      memory = string
    })
    ingress_gateway = object({
      cpu    = string
      memory = string
    })
    egress_gateway = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    istiod = {
      cpu    = "500m"
      memory = "2048Mi"
    }
    ingress_gateway = {
      cpu    = "100m"
      memory = "128Mi"
    }
    egress_gateway = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Istio Infrastructure"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
