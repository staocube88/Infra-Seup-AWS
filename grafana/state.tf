terraform {
  backend "s3" {
     bucket = "bimodaldemobucket"
     key    = "grafana/dev/terraform.tfstate"
     region = "us-east-1"
  }
}