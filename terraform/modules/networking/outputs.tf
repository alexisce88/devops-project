output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "db_subnet_id" {
  description = "ID of the secondary (private) subnet used for RDS subnet group"
  value       = aws_subnet.db.id
}
