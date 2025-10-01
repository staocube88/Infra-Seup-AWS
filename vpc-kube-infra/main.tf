module "vpc" {
  source            = "./modules/vpc"
  env               =  var.env
  cidr_block        =  var.vpc["cidr_block"] 
  public_subnets    =  var.vpc["public_subnets"]
  kube_subnets      =  var.vpc["kube_subnets"]
  db_subnets        =  var.vpc["db_subnets"]
  default_vpc_id    =  var.vpc["default_vpc_id"]
  default_vpc_rt    =  var.vpc["default_vpc_rt"]
  default_vpc_cidr  =  var.vpc["default_vpc_cidr"]
}

