output "setup_instance_id" {
  description = "ID of the setup/bastion EC2 instance"
  value       = aws_instance.setup.id
}

output "setup_instance_public_ip" {
  description = "Public IP of the setup/bastion instance"
  value       = aws_instance.setup.public_ip
}

output "setup_instance_public_dns" {
  description = "Public DNS of the setup/bastion instance"
  value       = aws_instance.setup.public_dns
}

output "app_server_ids" {
  description = "IDs of the application server EC2 instances"
  value       = aws_instance.app_server[*].id
}

output "app_server_private_ips" {
  description = "Private IPs of the application servers"
  value       = aws_instance.app_server[*].private_ip
}

output "app_server_primary_network_interface_ids" {
  description = "Primary network interface IDs of the application servers"
  value       = aws_instance.app_server[*].primary_network_interface_id
}
