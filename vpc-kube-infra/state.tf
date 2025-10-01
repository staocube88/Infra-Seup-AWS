terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "vpc-k8s/dev/terraform.tfstate"
    region = "us-east-1"
  }
}