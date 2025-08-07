module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "igw" {
  source       = "../../modules/igw"
  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
}

module "subnet" {
  source       = "../../modules/subnet"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  subnet_cidr  = var.subnet_cidr
  az           = var.az
  igw_id       = module.igw.igw_id
}

module "security_group" {
  source       = "../../modules/security_group"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

module "public_ip" {
  source       = "../../modules/public_ip"
  project_name = var.project_name
}

module "iam_role" {
  source       = "../../modules/iam_roles"
  project_name = var.project_name
}

module "ec2" {
  source               = "../../modules/ec2"
  project_name         = var.project_name
  ami                  = var.ami
  instance_type        = var.instance_type
  subnet_id            = module.subnet.subnet_id
  sg_id                = module.security_group.sg_id
  key_name             = var.key_name
  iam_instance_profile = module.iam_role.instance_profile_name
  depends_on           = [module.iam_role]
}