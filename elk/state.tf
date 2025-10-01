terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "elk/dev/terraform.tfstate"
    region = "us-east-1"
  }
}