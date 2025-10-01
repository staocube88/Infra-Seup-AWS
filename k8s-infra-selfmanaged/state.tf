terraform {
  backend "s3" {
    bucket = "bimodaldemobucket"
    key    = "k8s/dev/terraform.tfstate"
    region = "us-east-1"
  }
}