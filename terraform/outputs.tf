output "staging_public_ip" {
  description = "Public IP of Staging server"
  value       = module.staging.public_ip
}

output "production_public_ip" {
  description = "Public IP of Production server (hosts Blue + Green slots)"
  value       = module.production.public_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint — use this as DATABASE_HOST in production app config"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "ssh_commands" {
  description = "SSH commands for Terraform-managed servers"
  value = {
    staging    = "ssh -i ~/.ssh/devops-capstone.pem ubuntu@${module.staging.public_ip}"
    production = "ssh -i ~/.ssh/devops-capstone.pem ubuntu@${module.production.public_ip}"
  }
}

output "access_urls" {
  description = "Service URLs after provisioning"
  value = {
    staging    = "http://${module.staging.public_ip}"
    production = "http://${module.production.public_ip}"
  }
}
