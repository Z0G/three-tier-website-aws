output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.mysql.id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance (host:port)"
  value       = aws_db_instance.mysql.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.mysql.address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.mysql.port
}

output "db_name" {
  description = "Name of the database"
  value       = aws_db_instance.mysql.db_name
}

output "db_username" {
  description = "Master username for the database"
  value       = aws_db_instance.mysql.username
  sensitive   = true
}
