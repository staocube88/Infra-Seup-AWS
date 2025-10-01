# ───────────────────────────────
# Kubernetes Infrastructure Outputs
# ───────────────────────────────

# Bastion host information
output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion_host.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host"
  value       = module.bastion_host.bastion_private_ip
}

# Control plane information
output "control_plane_private_ip" {
  description = "Private IP addresses of control plane instances"
  value = {
    for k, v in module.control-plane : k => v.aws_control_plane_private_ip
  }
}

output "control_plane_instance_ids" {
  description = "Instance IDs of control plane instances"
  value = {
    for k, v in module.control-plane : k => v.aws_control_plane_instance_id
  }
}

# Worker node information
output "worker_private_ips" {
  description = "Private IP addresses of worker instances"
  value = {
    for k, v in module.worker : k => v.aws_worker_private_ip
  }
}

output "worker_instance_ids" {
  description = "Instance IDs of worker instances"
  value = {
    for k, v in module.worker : k => v.aws_worker_instance_id
  }
}

# Security group information
output "control_plane_security_group_id" {
  description = "Security group ID for control plane"
  value       = module.security_groups.control_plane_security_group
}

output "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = module.security_groups.worker_security_group
}

output "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  value       = module.bastion_host.bastion_security_group_id
}

# Network information
output "vpc_id" {
  description = "VPC ID"
  value       = module.security_groups.vpc_id
}

output "kube_subnet_id" {
  description = "Kubernetes subnet ID"
  value       = module.security_groups.kube_subnet_id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = module.security_groups.public_subnet_id
}

# Connection summary
output "connection_summary" {
  description = "Summary of connection information"
  value = {
    bastion_public_ip     = module.bastion_host.bastion_public_ip
    bastion_ssh_command   = "ssh ${var.aws_user}@${module.bastion_host.bastion_public_ip}"
    control_plane_ips     = { for k, v in module.control-plane : k => v.aws_control_plane_private_ip }
    worker_ips            = { for k, v in module.worker : k => v.aws_worker_private_ip }
    environment           = var.env
  }
}
