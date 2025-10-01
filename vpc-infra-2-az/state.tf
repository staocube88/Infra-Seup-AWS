terraform {
  backend "s3" {
    bucket = "devops-state-manupanand-aps2"
    key    = "terraform/dev/terraform.tfstate"
    region = "ap-south-2"
  }
}