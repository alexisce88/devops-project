output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "monitoring_public_ip" {
  description = "Public IP of Monitoring server (Prometheus + Grafana + Alertmanager)"
  value       = module.monitoring.public_ip
}

output "monitoring_private_ip" {
  description = "Private IP of Monitoring server"
  value       = module.monitoring.private_ip
}

output "staging_public_ip" {
  description = "Public IP of Staging server"
  value       = module.staging.public_ip
}

output "staging_private_ip" {
  description = "Private IP of Staging server"
  value       = module.staging.private_ip
}

output "production_public_ip" {
  description = "Public IP of Production server (hosts Blue + Green slots)"
  value       = module.production.public_ip
}

output "production_private_ip" {
  description = "Private IP of Production server"
  value       = module.production.private_ip
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
  description = "SSH commands for all servers"
  value = {
    monitoring = "ssh -i ~/.ssh/devops-capstone.pem ubuntu@${module.monitoring.public_ip}"
    staging    = "ssh -i ~/.ssh/devops-capstone.pem ubuntu@${module.staging.public_ip}"
    production = "ssh -i ~/.ssh/devops-capstone.pem ubuntu@${module.production.public_ip}"
  }
}

output "access_urls" {
  description = "Service URLs after provisioning"
  value = {
    staging      = "http://${module.staging.public_ip}"
    production   = "http://${module.production.public_ip}"
    grafana      = "http://${module.monitoring.public_ip}:3000"
    prometheus   = "http://${module.monitoring.public_ip}:9090"
    alertmanager = "http://${module.monitoring.public_ip}:9093"
  }
}
