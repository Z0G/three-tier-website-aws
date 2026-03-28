output "efs_id" {
  description = "ID of the Elastic File System"
  value       = aws_efs_file_system.main.id
}

output "efs_arn" {
  description = "ARN of the Elastic File System"
  value       = aws_efs_file_system.main.arn
}

output "efs_dns_name" {
  description = "DNS name of the EFS"
  value       = aws_efs_file_system.main.dns_name
}

output "efs_mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = aws_efs_mount_target.main[*].id
}

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = aws_efs_access_point.app.id
}

output "efs_access_point_arn" {
  description = "ARN of the EFS access point"
  value       = aws_efs_access_point.app.arn
}
