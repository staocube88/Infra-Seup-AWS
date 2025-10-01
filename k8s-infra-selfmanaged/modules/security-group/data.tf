data "aws_subnet" "kube_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.private_vpc.id]
  }
  filter{
    name ="tag:Name"
    values = [var.subnet_name]
  }
}

# Data source for public subnet (for bastion host)
data "aws_subnet" "public_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.private_vpc.id]
  }
  filter{
    name ="tag:Name"
    values = ["${var.env}-public-subnet"]
  }
}

data "aws_vpc" "private_vpc" {
    
  filter {
    name = "tag:Name"
    values = [var.vpc_name]
  }
}

