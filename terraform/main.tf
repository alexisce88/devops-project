# Architecture:
# - Monitoring: managed manually (permanent, not in Terraform)
# - Staging:    1 EC2 — Nginx + app containers + Postgres Docker
# - Production: 1 EC2 — Nginx + Blue containers (3000/3001) + Green containers (3002/3003)
# - RDS:        AWS managed PostgreSQL — shared by Blue and Green in production
#
# Free Tier: 2 × t3.small = 4 vCPU (well within the 8 vCPU limit)

module "networking" {
  source = "./modules/networking"

  project_name                = var.project_name
  vpc_cidr                    = var.vpc_cidr
  public_subnet_cidr          = var.public_subnet_cidr
  availability_zone           = var.availability_zone
  db_subnet_cidr              = var.db_subnet_cidr
  secondary_availability_zone = var.secondary_availability_zone
}

module "security_groups" {
  source = "./modules/security_groups"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
  my_ip        = var.my_ip
}

# Staging: Nginx + app containers + Postgres Docker (all on one server)
module "staging" {
  source = "./modules/ec2"

  project_name       = var.project_name
  role               = "staging"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.networking.public_subnet_id
  security_group_ids = [module.security_groups.app_sg_id]
  key_pair_name      = var.key_pair_name
  volume_size        = 20
}

# Production: Nginx + Blue slot (3000/3001) + Green slot (3002/3003) — connects to RDS
module "production" {
  source = "./modules/ec2"

  project_name       = var.project_name
  role               = "production"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  subnet_id          = module.networking.public_subnet_id
  security_group_ids = [module.security_groups.app_sg_id]
  key_pair_name      = var.key_pair_name
  volume_size        = 20
}

# RDS subnet group — AWS requires at least 2 subnets in different AZs
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [module.networking.public_subnet_id, module.networking.db_subnet_id]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# RDS PostgreSQL — production database shared by Blue and Green slots
resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.security_groups.rds_sg_id]

  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name    = "${var.project_name}-postgres"
    Project = var.project_name
  }
}
