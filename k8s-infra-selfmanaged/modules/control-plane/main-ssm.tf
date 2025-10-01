# Control Plane Module using SSM Session Manager (No SSH Required)
# This is the most secure and reliable approach

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

  # Use SSM Session Manager instead of SSH provisioner
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instance to be ready..."
      aws ssm wait instance-online --instance-ids ${self.id} --region ${data.aws_region.current.name}
      
      echo "Executing setup commands via SSM..."
      aws ssm send-command \
        --instance-ids ${self.id} \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["echo Waiting for user data script to complete..., while [ ! -e /tmp/join.sh ]; do echo Waiting for join.sh...; sleep 30; done, echo join.sh file found, waiting for Kubernetes to be ready..., sleep 60, echo Control plane setup completed"]' \
        --region ${data.aws_region.current.name} \
        --output text --query "Command.CommandId" > /tmp/command-id.txt
      
      COMMAND_ID=$(cat /tmp/command-id.txt)
      echo "Command ID: $COMMAND_ID"
      
      echo "Waiting for command to complete..."
      aws ssm wait command-executed --command-id $COMMAND_ID --instance-id ${self.id} --region ${data.aws_region.current.name}
      
      echo "Getting command output..."
      aws ssm get-command-invocation --command-id $COMMAND_ID --instance-id ${self.id} --region ${data.aws_region.current.name}
    EOT
  }

  tags = {
    Name        = "${var.name}-${var.env}-instance"
    Environment = var.env
    Role        = "control-plane"
    ManagedBy   = "terraform"
  }
}

# Data source for current AWS region
data "aws_region" "current" {}

# IAM instance profile for control plane with SSM permissions
resource "aws_iam_instance_profile" "iam_instance_profile" {
  name = "${var.name}-${var.env}-instance-profile"
  role = aws_iam_role.iam_role.name
}

# IAM role for control plane with SSM permissions
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

# Attach SSM managed instance policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach additional policies for Kubernetes
resource "aws_iam_role_policy_attachment" "ec2_read_only" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Custom policy for Kubernetes-specific permissions
resource "aws_iam_role_policy" "k8s_custom_policy" {
  name = "${var.name}-${var.env}-k8s-policy"
  role = aws_iam_role.iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      }
    ]
  })
}
