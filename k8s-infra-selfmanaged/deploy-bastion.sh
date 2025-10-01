#!/bin/bash

# ───────────────────────────────
# Kubernetes Infrastructure with Bastion Host Deployment Script
# ───────────────────────────────

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites for bastion host deployment..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "terraform is not installed. Please install terraform first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Please copy terraform.tfvars.example and configure it."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to validate terraform configuration
validate_terraform() {
    print_status "Validating Terraform configuration..."
    
    terraform validate
    
    if [ $? -eq 0 ]; then
        print_success "Terraform configuration is valid!"
    else
        print_error "Terraform configuration validation failed!"
        exit 1
    fi
}

# Function to plan terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment with bastion host..."
    
    terraform plan -out=tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Terraform plan created successfully!"
    else
        print_error "Terraform planning failed!"
        exit 1
    fi
}

# Function to apply terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment with bastion host..."
    
    terraform apply tfplan
    
    if [ $? -eq 0 ]; then
        print_success "Terraform deployment completed successfully!"
    else
        print_error "Terraform deployment failed!"
        exit 1
    fi
}

# Function to get bastion host information
get_bastion_info() {
    print_status "Getting bastion host information..."
    
    BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
    
    if [ -n "$BASTION_IP" ]; then
        print_success "Bastion host deployed successfully!"
        echo ""
        echo "┌─────────────────────────────────────────────────────────────┐"
        echo "│                    BASTION HOST INFO                        │"
        echo "├─────────────────────────────────────────────────────────────┤"
        echo "│ Public IP: $BASTION_IP"
        echo "│ SSH Command: ssh $AWS_USER@$BASTION_IP"
        echo "│ Purpose: Secure access to private Kubernetes instances      │"
        echo "└─────────────────────────────────────────────────────────────┘"
        echo ""
    else
        print_warning "Could not retrieve bastion host IP. Check terraform outputs."
    fi
}

# Function to test bastion connectivity
test_bastion_connectivity() {
    print_status "Testing bastion host connectivity..."
    
    BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
    
    if [ -n "$BASTION_IP" ]; then
        print_status "Testing SSH connection to bastion host..."
        
        # Test SSH connectivity with timeout
        if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $AWS_USER@$BASTION_IP "echo 'Bastion host is accessible'" 2>/dev/null; then
            print_success "Bastion host is accessible!"
        else
            print_warning "Bastion host may not be ready yet. Please wait a few minutes and try again."
        fi
    else
        print_error "Cannot test connectivity - bastion IP not available."
    fi
}

# Function to show connection instructions
show_connection_instructions() {
    print_status "Connection Instructions:"
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│              CONNECTING TO KUBERNETES CLUSTER               │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│                                                             │"
    echo "│ 1. Connect to bastion host:                                 │"
    echo "│    ssh $AWS_USER@$BASTION_IP"
    echo "│                                                             │"
    echo "│ 2. From bastion, connect to control plane:                 │"
    echo "│    ssh $AWS_USER@<control-plane-private-ip>                │"
    echo "│                                                             │"
    echo "│ 3. Or use SSH tunnel for direct access:                   │"
    echo "│    ssh -L 2222:<private-ip>:22 $AWS_USER@$BASTION_IP        │"
    echo "│    Then: ssh -p 2222 $AWS_USER@localhost                    │"
    echo "│                                                             │"
    echo "│ 4. Check Kubernetes cluster status:                          │"
    echo "│    kubectl get nodes                                         │"
    echo "│    kubectl get pods --all-namespaces                        │"
    echo "│                                                             │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
}

# Function to get Kubernetes cluster info
get_k8s_info() {
    print_status "Getting Kubernetes cluster information..."
    
    # Get control plane private IP
    CONTROL_PLANE_IP=$(terraform output -raw control_plane_private_ip 2>/dev/null || echo "")
    
    if [ -n "$CONTROL_PLANE_IP" ]; then
        echo ""
        echo "┌─────────────────────────────────────────────────────────────┐"
        echo "│                KUBERNETES CLUSTER INFO                      │"
        echo "├─────────────────────────────────────────────────────────────┤"
        echo "│ Control Plane Private IP: $CONTROL_PLANE_IP"
        echo "│ Bastion Public IP: $BASTION_IP"
        echo "│                                                             │"
        echo "│ To access the cluster:                                     │"
        echo "│ 1. SSH to bastion: ssh $AWS_USER@$BASTION_IP"
        echo "│ 2. SSH to control plane: ssh $AWS_USER@$CONTROL_PLANE_IP    │"
        echo "│ 3. Run: kubectl get nodes                                 │"
        echo "└─────────────────────────────────────────────────────────────┘"
        echo ""
    else
        print_warning "Could not retrieve control plane IP."
    fi
}

# Main deployment function
deploy() {
    print_status "Starting Kubernetes infrastructure deployment with bastion host..."
    echo ""
    
    check_prerequisites
    validate_terraform
    plan_terraform
    
    echo ""
    print_warning "Review the plan above. This will deploy:"
    echo "  • Bastion host in public subnet"
    echo "  • Control plane instances in private subnet"
    echo "  • Worker nodes in private subnet"
    echo "  • Security groups with bastion access"
    echo ""
    print_warning "Do you want to continue with the deployment? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        apply_terraform
        get_bastion_info
        test_bastion_connectivity
        get_k8s_info
        show_connection_instructions
    else
        print_status "Deployment cancelled by user."
        exit 0
    fi
}

# Function to destroy infrastructure
destroy() {
    print_warning "This will destroy the entire Kubernetes infrastructure including bastion host. Are you sure? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_status "Destroying Kubernetes infrastructure..."
        terraform destroy -auto-approve
        
        if [ $? -eq 0 ]; then
            print_success "Kubernetes infrastructure destroyed successfully!"
        else
            print_error "Failed to destroy infrastructure!"
            exit 1
        fi
    else
        print_status "Destruction cancelled by user."
    fi
}

# Function to show help
show_help() {
    echo "Kubernetes Infrastructure with Bastion Host Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy Kubernetes infrastructure with bastion host (default)"
    echo "  destroy   Destroy entire infrastructure"
    echo "  info      Show connection information"
    echo "  test      Test bastion host connectivity"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 destroy"
    echo "  $0 info"
    echo "  $0 test"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    destroy)
        destroy
        ;;
    info)
        get_bastion_info
        get_k8s_info
        show_connection_instructions
        ;;
    test)
        test_bastion_connectivity
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
