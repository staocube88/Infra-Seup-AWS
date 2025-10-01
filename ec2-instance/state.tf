terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "ec2/dev/terraform.tfstate"
    region = "us-east-1"
  }
}