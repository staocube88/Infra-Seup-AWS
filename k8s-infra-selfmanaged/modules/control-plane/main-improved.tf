# Improved Control Plane Module with Bastion Support
# This module supports both direct SSH and bastion host access

resource "aws_instance" "instance_control_plane" {
  depends_on = [aws_iam_instance_profile.iam_instance_profile]
  
  instance_type            = var.instance_type
  ami                      = var.aws_ami_id
  subnet_id                = var.kube_subnet_id  
  iam_instance_profile     = aws_iam_instance_profile.iam_instance_profile.name
  vpc_security_group_ids   = [var.private_security_group_id] 

  # Instance options
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent" 
    } 
  } 
  
  # Volume configuration
  root_block_device {
    volume_size = var.volume_size 
    volume_type = "gp3"
    encrypted   = true
  }  
  
  # User data commands
  user_data = base64encode(templatefile("${path.module}/control-plane.sh", {
    AWS_USER     = var.aws_user
    AWS_PASSWORD = var.aws_password
    role_name    = "control-plane"
  }))

  # Wait for user data script to complete and create join.sh file
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for user data script to complete...'",
      "while [ ! -e /tmp/join.sh ]; do echo 'Waiting for join.sh...'; sleep 30; done",
      "echo 'join.sh file found, waiting for Kubernetes to be ready...'",
      "sleep 60",
      "echo 'Control plane setup completed'"
    ]
    
    connection {
      type        = "ssh" 
      user        = var.aws_user
      password    = var.aws_password
      host        = var.use_bastion ? var.bastion_public_ip : self.public_ip
      timeout     = "10m"
      agent       = false
      private_key = var.use_bastion ? null : file(var.ssh_private_key_path)
    }
  }

  tags = {
    Name        = "${var.name}-${var.env}-instance"
    Environment = var.env
    Role        = "control-plane"
    ManagedBy   = "terraform"
  }
}

# IAM instance profile for control plane
resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "${var.name}-${var.env}-instance-profile"
  role = aws_iam_role.iam_role.name
}

# IAM role for control plane
resource "aws_iam_role" "iam_role" {
  name = "${var.name}-${var.env}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.name}-${var.env}-role"
    Environment = var.env
  }
}

# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
