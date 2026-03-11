variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "devops-capstone"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (region-specific)"
  type        = string
  default     = "ami-04680790a315cd58d" # Ubuntu 22.04 LTS us-east-1 (2026-02-18)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the existing EC2 key pair for SSH access"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address for SSH access (CIDR format, e.g. 1.2.3.4/32)"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for the secondary subnet (used by RDS subnet group)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "secondary_availability_zone" {
  description = "Secondary AZ for the RDS subnet group (must differ from availability_zone)"
  type        = string
  default     = "us-east-1b"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "PostgreSQL master password (keep this secret, never commit to Git)"
  type        = string
  sensitive   = true
}
