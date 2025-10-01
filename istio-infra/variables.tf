variable "cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "cluster_ca_cert" {
  description = "Base64 encoded CA cert for the cluster"
  type        = string
}

variable "cluster_token" {
  description = "Service account token for accessing cluster"
  type        = string
}

variable "istio_version" {
  description = "Version of Istio Helm charts to install"
  type        = string
  default     = "1.22.1" # latest LTS at time of writing
}
