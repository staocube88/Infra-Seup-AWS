# Istio Infrastructure Terraform Module

This Terraform module provides a comprehensive, production-ready deployment of Istio service mesh on Kubernetes clusters with best practices for security, monitoring, and observability.

## Features

- ✅ **Production-Ready**: Implements security best practices and proper RBAC
- ✅ **Configurable**: Extensive variable configuration for different environments
- ✅ **Monitoring**: Built-in Prometheus metrics and distributed tracing
- ✅ **Security**: Proper service accounts, RBAC, and network policies
- ✅ **Observability**: Comprehensive logging and metrics collection
- ✅ **Multi-Cluster**: Support for multi-cluster deployments
- ✅ **Resource Management**: Configurable resource limits and requests
- ✅ **Tagging**: Consistent labeling and metadata across all resources

## Architecture

The module deploys the following Istio components:

1. **Istio Base** - Core Istio CRDs and components
2. **Istiod** - Control plane (pilot, citadel, galley)
3. **Ingress Gateway** - Entry point for external traffic (optional)
4. **Egress Gateway** - Exit point for external traffic (optional)

## Prerequisites

- Kubernetes cluster (1.21+)
- Helm 3.x
- Terraform 1.3+
- kubectl configured with cluster access

## Usage

### Basic Usage

```hcl
module "istio" {
  source = "./istio-infra"
  
  # Required variables
  cluster_endpoint = "https://your-cluster-endpoint"
  cluster_ca_cert  = "base64-encoded-ca-cert"
  cluster_token    = "your-service-account-token"
  
  # Optional variables
  environment = "dev"
  istio_version = "1.22.1"
}
```

### Advanced Usage

```hcl
module "istio" {
  source = "./istio-infra"
  
  # Cluster configuration
  cluster_endpoint = "https://your-cluster-endpoint"
  cluster_ca_cert  = "base64-encoded-ca-cert"
  cluster_token    = "your-service-account-token"
  
  # Environment configuration
  environment     = "prod"
  istio_version  = "1.22.1"
  namespace_name = "istio-system"
  
  # Mesh configuration
  mesh_id        = "production-mesh"
  cluster_name   = "prod-cluster"
  network_name   = "prod-network"
  
  # Feature flags
  enable_ingress_gateway = true
  enable_egress_gateway  = true
  enable_multi_cluster   = false
  enable_telemetry       = true
  enable_security        = true
  
  # Gateway configuration
  ingress_gateway_type = "LoadBalancer"
  
  # Resource configuration
  resource_limits = {
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
  
  resource_requests = {
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
  
  # Tags
  tags = {
    Project     = "Istio Infrastructure"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Owner       = "Platform Team"
  }
}
```

## Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `cluster_endpoint` | Kubernetes API server endpoint URL | `string` |
| `cluster_ca_cert` | Base64 encoded CA certificate | `string` |
| `cluster_token` | Service account token | `string` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `environment` | Environment name (dev, staging, prod) | `string` | `"dev"` |
| `istio_version` | Istio version to install | `string` | `"1.22.1"` |
| `namespace_name` | Istio system namespace name | `string` | `"istio-system"` |
| `enable_ingress_gateway` | Deploy ingress gateway | `bool` | `true` |
| `enable_egress_gateway` | Deploy egress gateway | `bool` | `false` |
| `ingress_gateway_type` | Service type for ingress gateway | `string` | `"LoadBalancer"` |
| `mesh_id` | Unique mesh identifier | `string` | `"mesh1"` |
| `cluster_name` | Kubernetes cluster name | `string` | `"cluster-1"` |
| `network_name` | Network name for multi-cluster | `string` | `"network1"` |
| `enable_multi_cluster` | Enable multi-cluster configuration | `bool` | `false` |
| `enable_telemetry` | Enable telemetry components | `bool` | `true` |
| `enable_security` | Enable security components | `bool` | `true` |

## Outputs

The module provides comprehensive outputs for integration with other modules:

| Name | Description |
|------|-------------|
| `istio_namespace` | Istio system namespace name |
| `istio_version` | Installed Istio version |
| `installation_summary` | Complete installation summary |
| `istio_ingress_gateway_service` | Ingress gateway service information |

## Security Features

- **RBAC**: Proper service accounts and cluster roles
- **Network Policies**: Secure network communication
- **Resource Limits**: Prevents resource exhaustion
- **Security Context**: Non-root containers
- **Secrets Management**: Secure credential handling

## Monitoring and Observability

- **Prometheus Metrics**: Comprehensive metrics collection
- **Distributed Tracing**: Jaeger integration
- **Access Logging**: Structured JSON logs
- **Health Checks**: Built-in health monitoring

## File Structure

```
istio-infra/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions with validation
├── outputs.tf                 # Output definitions
├── values/                    # Helm values files
│   ├── istiod-values.yaml     # Istiod configuration
│   ├── istio-ingress-values.yaml # Ingress gateway configuration
│   └── monitoring-values.yaml # Monitoring configuration
└── README.md                  # This file
```

## Deployment Process

1. **Namespace Creation**: Creates the Istio system namespace
2. **RBAC Setup**: Configures service accounts and permissions
3. **Base Installation**: Deploys Istio base components
4. **Control Plane**: Installs Istiod (pilot, citadel, galley)
5. **Gateways**: Deploys ingress/egress gateways (if enabled)

## Best Practices Implemented

- ✅ **Immutable Infrastructure**: All resources are managed by Terraform
- ✅ **Resource Tagging**: Consistent labeling across all resources
- ✅ **Security First**: Proper RBAC and security contexts
- ✅ **Monitoring**: Built-in observability and metrics
- ✅ **Configuration Management**: Externalized configuration via values files
- ✅ **Dependency Management**: Proper resource dependencies
- ✅ **Lifecycle Management**: Prevents accidental destruction of critical resources

## Troubleshooting

### Common Issues

1. **Helm Chart Not Found**: Ensure Helm repositories are properly configured
2. **RBAC Errors**: Check service account permissions
3. **Resource Limits**: Adjust resource requests/limits based on cluster capacity
4. **Network Issues**: Verify cluster networking configuration

### Useful Commands

```bash
# Check Istio installation
kubectl get pods -n istio-system

# Check Helm releases
helm list -n istio-system

# View Istio configuration
kubectl get istio-operator -n istio-system

# Check service endpoints
kubectl get svc -n istio-system
```

## Contributing

1. Follow Terraform best practices
2. Update documentation for any changes
3. Test in development environment first
4. Ensure all variables have proper validation

## License

This module is part of the AWS Infrastructure Setup project.
