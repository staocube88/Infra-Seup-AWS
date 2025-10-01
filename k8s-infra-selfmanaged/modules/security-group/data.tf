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

data "aws_vpc" "private_vpc" {
    
  filter {
    name = "tag:Name"
    values = [var.vpc_name]
  }
}

