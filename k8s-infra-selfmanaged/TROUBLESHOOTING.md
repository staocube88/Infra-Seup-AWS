# Kubernetes Infrastructure SSH Connectivity Troubleshooting Guide

## 🚨 **Problem Summary**
- **Error**: `timeout - last error: dial tcp 10.10.67.93:22: i/o timeout`
- **Root Cause**: Terraform trying to SSH to private IP from internet
- **Impact**: Control plane provisioner fails, blocking cluster setup

## 🔍 **Root Cause Analysis**

### **Why This Happens:**
1. **Private Subnet**: Control plane instances are in private subnet (10.10.x.x)
2. **Private IP Access**: Terraform uses `self.private_ip` for SSH connection
3. **No Internet Route**: Private IPs are not accessible from your local machine
4. **Security Groups**: May not allow SSH from your IP range

### **Network Architecture Issue:**
```
Internet → Your Machine → ❌ Private IP (10.10.67.93) → Control Plane
```

## 🛠️ **Solutions Implemented**

### **Solution 1: Quick Fix - Use Public IP (IMPLEMENTED)**
✅ **Changes Made:**
- Modified `connection` block to use `self.public_ip`
- Added timeout configuration (`timeout = "10m"`)
- Improved provisioner with better error handling

**Files Modified:**
- `modules/control-plane/main.tf` - Line 39: `host = self.public_ip`
- `modules/security-group/security-group.tf` - SSH access allowed

### **Solution 2: Bastion Host (CREATED)**
✅ **New Module Created:** `modules/bastion/`
- Secure SSH access through public bastion host
- Elastic IP for consistent access
- Helper scripts for tunneling

**Usage:**
```bash
# Connect to bastion
ssh user@bastion-public-ip

# From bastion, connect to private instances
ssh user@private-instance-ip
```

### **Solution 3: SSM Session Manager (CREATED)**
✅ **New Module Created:** `modules/control-plane/main-ssm.tf`
- No SSH required
- Uses AWS Systems Manager
- More secure and reliable

## 🚀 **Immediate Action Required**

### **Option A: Use Current Fix (Recommended for Quick Resolution)**
Your current configuration should now work because:
1. ✅ Using `self.public_ip` instead of `self.private_ip`
2. ✅ Security group allows SSH from anywhere
3. ✅ Improved timeout and error handling

**Test the fix:**
```bash
cd k8s-infra-selfmanaged
terraform plan
terraform apply
```

### **Option B: Use SSM Session Manager (Most Secure)**
Replace your current `main.tf` with `main-ssm.tf`:

```bash
cd modules/control-plane
mv main.tf main.tf.backup
mv main-ssm.tf main.tf
```

**Benefits:**
- ✅ No SSH required
- ✅ More secure
- ✅ Better logging
- ✅ Works with private subnets

## 🔧 **Troubleshooting Steps**

### **Step 1: Verify Instance Status**
```bash
# Check if instance is running
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Check security groups
aws ec2 describe-security-groups --group-ids sg-1234567890abcdef0
```

### **Step 2: Test SSH Connectivity**
```bash
# Test SSH to public IP
ssh -o ConnectTimeout=10 user@public-ip

# Check if port 22 is open
telnet public-ip 22
```

### **Step 3: Check Security Groups**
Ensure security group allows:
- **Port 22** from **0.0.0.0/0** (temporarily)
- **All outbound traffic**

### **Step 4: Verify User Data Script**
```bash
# Connect to instance and check logs
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/cloud-init.log
```

## 📋 **Prevention Measures**

### **1. Use Public Subnets for Initial Setup**
- Deploy control plane in public subnet initially
- Move to private subnet after cluster is ready

### **2. Implement Proper Security**
- Use bastion host for production
- Restrict SSH access to specific IP ranges
- Use SSH keys instead of passwords

### **3. Use SSM Session Manager**
- Most secure approach
- No SSH required
- Better audit trail

## 🎯 **Recommended Next Steps**

1. **Immediate**: Test the current fix with `terraform apply`
2. **Short-term**: Implement bastion host for production
3. **Long-term**: Migrate to SSM Session Manager

## 📞 **If Issues Persist**

### **Common Issues:**
1. **Instance not ready**: Wait for user data script to complete
2. **Security group**: Ensure SSH port 22 is open
3. **AMI issues**: Verify AMI supports your user data script
4. **Network ACLs**: Check VPC network ACLs

### **Debug Commands:**
```bash
# Check instance status
aws ec2 describe-instances --filters "Name=tag:Name,Values=*control-plane*"

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*kube-control-plane*"

# Check user data execution
aws ssm get-command-invocation --command-id COMMAND_ID --instance-id INSTANCE_ID
```

## 🔒 **Security Recommendations**

### **After Successful Deployment:**
1. **Restrict SSH Access**: Change security group to allow SSH only from your IP
2. **Use SSH Keys**: Replace password authentication with SSH keys
3. **Implement Bastion**: Use bastion host for secure access
4. **Enable Logging**: Enable CloudTrail and VPC Flow Logs

### **Production Security Checklist:**
- [ ] SSH access restricted to specific IPs
- [ ] Bastion host implemented
- [ ] Security groups follow least privilege
- [ ] Regular security updates
- [ ] Monitoring and alerting enabled
