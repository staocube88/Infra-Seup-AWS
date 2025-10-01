# Bastion Host Module for Secure SSH Access
# This module creates a bastion host in a public subnet for secure access to private instances

resource "aws_instance" "bastion_host" {
  ami                    = var.aws_ami_id
  instance_type          = "t3.micro"  # Small instance for bastion
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  
  # Use spot instance for cost savings
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type            = "persistent"
    }
  }
  
  # Small root volume
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
  
  # User data to install required packages
  user_data = base64encode(templatefile("${path.module}/bastion-setup.sh", {
    AWS_USER     = var.aws_user
    AWS_PASSWORD = var.aws_password
  }))
  
  tags = {
    Name        = "${var.env}-bastion-host"
    Environment = var.env
    Purpose     = "SSH Bastion for K8s cluster"
  }
}

# Security group for bastion host
resource "aws_security_group" "bastion_sg" {
  name_prefix = "${var.env}-bastion-"
  vpc_id      = var.vpc_id
  
  description = "Security group for bastion host"
  
  # SSH access from anywhere (you can restrict this to your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access to bastion"
  }
  
  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = {
    Name        = "${var.env}-bastion-sg"
    Environment = var.env
  }
}

# Elastic IP for bastion host (optional but recommended)
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion_host.id
  domain   = "vpc"
  
  tags = {
    Name        = "${var.env}-bastion-eip"
    Environment = var.env
  }
}

# Security group rule to allow bastion to access private instances
resource "aws_security_group_rule" "bastion_to_private" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = var.private_security_group_id
  description              = "SSH access from bastion host"
}
