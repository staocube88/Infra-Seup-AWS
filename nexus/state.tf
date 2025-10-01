terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "nexus/dev/terraform.tfstate"
    region = "us-east-1"
  }
}