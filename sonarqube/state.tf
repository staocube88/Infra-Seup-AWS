terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "sonarqube/dev/terraform.tfstate"
    region = "us-east-1"
  }
}