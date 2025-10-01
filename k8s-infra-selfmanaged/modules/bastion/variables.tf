# Bastion Host Variables

variable "env" {
  description = "Environment name"
  type        = string
}

variable "aws_ami_id" {
  description = "AMI ID for bastion host"
  type        = string
}

variable "aws_user" {
  description = "SSH username for bastion host"
  type        = string
}

variable "aws_password" {
  description = "SSH password for bastion host"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where bastion will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for bastion host"
  type        = string
}

variable "private_security_group_id" {
  description = "Security group ID of private instances that bastion will access"
  type        = string
}
