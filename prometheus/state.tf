terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "promethues/dev/terraform.tfstate"
    region = "us-east-1"
  }
}