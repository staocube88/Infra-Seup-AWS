# Kubernetes Infrastructure with Bastion Host

This infrastructure setup deploys a secure Kubernetes cluster using a bastion host for SSH access to private instances.

## 🏗️ **Architecture Overview**

```
Internet → Bastion Host (Public Subnet) → Control Plane & Workers (Private Subnet)
```

### **Components:**
- **Bastion Host**: Secure SSH gateway in public subnet
- **Control Plane**: Kubernetes master nodes in private subnet
- **Worker Nodes**: Kubernetes worker nodes in private subnet
- **Security Groups**: Restrictive access rules with bastion-only SSH

## 🚀 **Quick Start**

### **1. Prerequisites**
- AWS CLI configured with appropriate credentials
- Terraform 1.0+ installed
- Access to AWS account with EC2, VPC, and IAM permissions

### **2. Configuration**
```bash
# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### **3. Deploy Infrastructure**
```bash
# Deploy with bastion host
./deploy-bastion.sh deploy

# Or manually
terraform init
terraform plan
terraform apply
```

## 🔧 **Configuration**

### **Required Variables**
```hcl
# Environment
env = "dev"

# VPC Configuration
vpc_name = "your-vpc-name"
subnet_name = "your-kube-subnet-name"

# Instance Configuration
aws_ami_id = "ami-12345678"
aws_user = "ec2-user"
aws_password = "your-secure-password"

# Control Plane Configuration
control_plane = {
  master_node_1 = {
    instance_type = "t3.medium"
    policy_name   = "control-plane-policy"
    volume_size   = 20
  }
}

# Worker Configuration
worker_instance = {
  worker_node_1 = {
    instance_type = "t3.medium"
    policy_name   = "worker-policy"
    volume_size   = 20
  }
}
```

## 🔐 **Security Features**

### **Bastion Host Security**
- ✅ Deployed in public subnet with Elastic IP
- ✅ Minimal security group (SSH only)
- ✅ Spot instance for cost optimization
- ✅ Automated setup scripts

### **Private Instance Security**
- ✅ Deployed in private subnet
- ✅ SSH access only through bastion host
- ✅ Kubernetes-specific security groups
- ✅ IAM roles with minimal permissions

### **Network Security**
- ✅ Private subnets for workloads
- ✅ Public subnet only for bastion
- ✅ Security group rules for bastion access
- ✅ No direct internet access to private instances

## 📡 **Access Methods**

### **Method 1: Direct SSH to Bastion**
```bash
# Connect to bastion host
ssh ec2-user@<bastion-public-ip>

# From bastion, connect to control plane
ssh ec2-user@<control-plane-private-ip>
```

### **Method 2: SSH Tunnel**
```bash
# Create SSH tunnel through bastion
ssh -L 2222:<control-plane-private-ip>:22 ec2-user@<bastion-public-ip>

# Connect to local tunnel
ssh -p 2222 ec2-user@localhost
```

### **Method 3: SSH ProxyCommand**
```bash
# Add to ~/.ssh/config
Host k8s-control-plane
    HostName <control-plane-private-ip>
    User ec2-user
    ProxyCommand ssh ec2-user@<bastion-public-ip> -W %h:%p

# Connect directly
ssh k8s-control-plane
```

## 🎯 **Usage Examples**

### **Deploy Infrastructure**
```bash
# Full deployment
./deploy-bastion.sh deploy

# Check status
./deploy-bastion.sh info

# Test connectivity
./deploy-bastion.sh test
```

### **Access Kubernetes Cluster**
```bash
# Get connection info
terraform output connection_summary

# Connect to bastion
ssh ec2-user@$(terraform output -raw bastion_public_ip)

# From bastion, connect to control plane
ssh ec2-user@$(terraform output -raw control_plane_private_ip)

# Check Kubernetes status
kubectl get nodes
kubectl get pods --all-namespaces
```

### **Copy Files to Private Instances**
```bash
# Copy through bastion
scp -o ProxyCommand="ssh ec2-user@<bastion-ip> -W %h:%p" \
    local-file ec2-user@<private-ip>:remote-path
```

## 🔍 **Troubleshooting**

### **Common Issues**

#### **1. Bastion Host Not Accessible**
```bash
# Check bastion status
aws ec2 describe-instances --filters "Name=tag:Name,Values=*bastion*"

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*bastion*"
```

#### **2. SSH Connection Failed**
```bash
# Test bastion connectivity
ssh -o ConnectTimeout=10 ec2-user@<bastion-ip>

# Check SSH service
ssh ec2-user@<bastion-ip> "sudo systemctl status sshd"
```

#### **3. Private Instance Not Accessible**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids <control-plane-sg-id>

# Verify bastion can reach private instances
ssh ec2-user@<bastion-ip> "telnet <private-ip> 22"
```

### **Debug Commands**
```bash
# Check all instances
terraform output connection_summary

# Get detailed instance info
aws ec2 describe-instances --instance-ids $(terraform output -json control_plane_instance_ids | jq -r '.[]')

# Check security groups
aws ec2 describe-security-groups --group-ids $(terraform output -raw control_plane_security_group_id)
```

## 📊 **Monitoring and Logging**

### **CloudWatch Logs**
- Bastion host system logs
- Kubernetes cluster logs
- Security group flow logs

### **Instance Monitoring**
```bash
# Check instance health
aws ec2 describe-instance-status --instance-ids $(terraform output -json control_plane_instance_ids | jq -r '.[]')

# Monitor resource usage
ssh ec2-user@<bastion-ip> "htop"
```

## 🛡️ **Security Best Practices**

### **Immediate Actions**
1. **Change Default Passwords**: Update SSH passwords
2. **Use SSH Keys**: Replace password authentication
3. **Restrict Bastion Access**: Limit SSH to your IP range
4. **Enable Logging**: Turn on CloudTrail and VPC Flow Logs

### **Production Recommendations**
1. **VPN Access**: Use VPN instead of bastion for production
2. **Multi-Factor Authentication**: Implement MFA for SSH
3. **Regular Updates**: Keep instances updated
4. **Backup Strategy**: Implement automated backups
5. **Monitoring**: Set up comprehensive monitoring

## 🔄 **Maintenance**

### **Regular Tasks**
```bash
# Update instances
ssh ec2-user@<bastion-ip> "sudo yum update -y"

# Check Kubernetes cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Review security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

### **Scaling**
```bash
# Add more worker nodes
# Edit terraform.tfvars
worker_instance = {
  worker_node_1 = { ... }
  worker_node_2 = { ... }  # Add new worker
}

# Apply changes
terraform plan
terraform apply
```

## 📋 **Cleanup**

### **Destroy Infrastructure**
```bash
# Destroy everything
./deploy-bastion.sh destroy

# Or manually
terraform destroy
```

### **Partial Cleanup**
```bash
# Destroy specific components
terraform destroy -target=module.bastion_host
terraform destroy -target=module.control-plane
```

## 📚 **Additional Resources**

- [AWS Bastion Host Best Practices](https://docs.aws.amazon.com/quickstart/latest/linux-bastion/)
- [Kubernetes Security Guide](https://kubernetes.io/docs/concepts/security/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🆘 **Support**

For issues and questions:
1. Check the troubleshooting section above
2. Review Terraform logs: `terraform logs`
3. Check AWS CloudTrail for API errors
4. Verify security group configurations
