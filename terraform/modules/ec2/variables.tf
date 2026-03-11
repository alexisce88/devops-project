variable "project_name" {
  type = string
}

variable "role" {
  description = "Server role: jenkins, staging, blue, green, monitoring"
  type        = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
}

variable "key_pair_name" {
  type = string
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}
