terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── VPC Module ─────────────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  aws_region              = var.aws_region
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs = var.private_db_subnet_cidrs
  availability_zones      = var.availability_zones
  ssh_access_ip           = var.ssh_access_ip
}

# ── RDS Module ────────────────────────────────────────────────────────────────

module "rds" {
  source = "./modules/rds"

  project_name                  = var.project_name
  vpc_id                        = module.vpc.vpc_id
  private_db_subnet_ids         = module.vpc.private_db_subnet_ids
  database_security_group_id    = module.vpc.database_security_group_id
  db_master_username            = var.db_master_username
  db_master_password            = var.db_master_password
  db_name                       = "mydatabase"
  db_instance_class             = "db.t3.micro"
  allocated_storage             = 20
  multi_az                      = true
}

# ── EFS Module ────────────────────────────────────────────────────────────────

module "efs" {
  source = "./modules/efs"

  project_name             = var.project_name
  vpc_id                   = module.vpc.vpc_id
  private_app_subnet_ids   = module.vpc.private_app_subnet_ids
  efs_security_group_id    = module.vpc.efs_security_group_id
  performance_mode         = "generalPurpose"
  throughput_mode          = "bursting"
  enable_encryption        = true
}

# ── Key Pair Module ───────────────────────────────────────────────────────────

module "key_pair" {
  source = "./modules/key-pair"

  project_name = var.project_name
  key_name     = var.ec2_key_pair_name
}

# ── EC2 Module ────────────────────────────────────────────────────────────────

module "ec2" {
  source = "./modules/ec2"

  project_name                = var.project_name
  vpc_id                      = module.vpc.vpc_id
  public_subnet_id            = module.vpc.public_subnet_ids[0]
  private_app_subnet_ids      = module.vpc.private_app_subnet_ids
  key_pair_name               = module.key_pair.key_pair_name
  web_server_security_group_id = module.vpc.web_server_security_group_id
  ssh_security_group_id       = module.vpc.ssh_security_group_id
  alb_security_group_id       = module.vpc.alb_security_group_id
  efs_id                      = module.efs.efs_id
  efs_dns_name                = module.efs.efs_dns_name
  efs_access_point_id         = module.efs.efs_access_point_id
  instance_type               = "t2.micro"
}

# ── ALB Module ────────────────────────────────────────────────────────────────

module "alb" {
  source = "./modules/alb"

  project_name              = var.project_name
  vpc_id                    = module.vpc.vpc_id
  public_subnet_ids         = module.vpc.public_subnet_ids
  alb_security_group_id     = module.vpc.alb_security_group_id
  app_server_ids            = module.ec2.app_server_ids
  instance_port             = 80
  alb_port                  = 80
  enable_cross_zone_load_balancing = true
}
