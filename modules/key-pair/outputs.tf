output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = aws_key_pair.main.key_name
}

output "key_pair_id" {
  description = "ID of the EC2 key pair"
  value       = aws_key_pair.main.id
}

output "private_key_path" {
  description = "Path to the saved private key file"
  value       = local_file.private_key.filename
  sensitive   = true
}
