terraform {
  backend "s3" {
     bucket = "bimodaldemobucket"
     key    = "vpc-infra/dev/terraform.tfstate"
     region = "us-east-1"
  }
}