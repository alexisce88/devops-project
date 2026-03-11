variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for the secondary subnet (RDS subnet group)"
  type        = string
}

variable "secondary_availability_zone" {
  description = "Secondary AZ for the RDS subnet group"
  type        = string
}
