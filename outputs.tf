# ── VPC Outputs ───────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of the private app-tier subnets"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of the private DB-tier subnets"
  value       = module.vpc.private_db_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_ips" {
  description = "Elastic IPs of the NAT Gateways"
  value       = module.vpc.elastic_ip_addresses
}

output "alb_security_group_id" {
  description = "ID of the ALB Security Group"
  value       = module.vpc.alb_security_group_id
}

output "web_server_security_group_id" {
  description = "ID of the Web Server Security Group"
  value       = module.vpc.web_server_security_group_id
}

output "database_security_group_id" {
  description = "ID of the Database Security Group"
  value       = module.vpc.database_security_group_id
}

output "efs_security_group_id" {
  description = "ID of the EFS Security Group"
  value       = module.vpc.efs_security_group_id
}

output "ssh_security_group_id" {
  description = "ID of the SSH Security Group"
  value       = module.vpc.ssh_security_group_id
}

# ── RDS Outputs ───────────────────────────────────────────────────────────────

output "db_subnet_group_id" {
  description = "ID of the DB Subnet Group"
  value       = module.rds.db_subnet_group_id
}

output "db_instance_id" {
  description = "ID of the RDS MySQL instance"
  value       = module.rds.db_instance_id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance (use for connections)"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = module.rds.db_instance_address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = module.rds.db_instance_port
}

output "db_name" {
  description = "Name of the database"
  value       = module.rds.db_name
}

output "db_username" {
  description = "Master username for the database"
  value       = module.rds.db_username
  sensitive   = true
}

# ── EFS Outputs ───────────────────────────────────────────────────────────────

output "efs_id" {
  description = "ID of the Elastic File System"
  value       = module.efs.efs_id
}

output "efs_dns_name" {
  description = "DNS name of the EFS"
  value       = module.efs.efs_dns_name
}

output "efs_mount_targets" {
  description = "IDs of the EFS mount targets"
  value       = module.efs.efs_mount_target_ids
}

output "efs_access_point_id" {
  description = "ID of the EFS access point for application"
  value       = module.efs.efs_access_point_id
}

# ── Key Pair Outputs ───────────────────────────────────────────────────────────

output "key_pair_name" {
  description = "Name of the EC2 key pair"
  value       = module.key_pair.key_pair_name
}

# ── EC2 Outputs ───────────────────────────────────────────────────────────────

output "setup_instance_id" {
  description = "ID of the setup/bastion EC2 instance"
  value       = module.ec2.setup_instance_id
}

output "setup_instance_public_ip" {
  description = "Public IP address of the setup instance (use for SSH)"
  value       = module.ec2.setup_instance_public_ip
}

output "setup_instance_public_dns" {
  description = "Public DNS hostname of the setup instance"
  value       = module.ec2.setup_instance_public_dns
}

output "app_server_ids" {
  description = "IDs of the application server EC2 instances"
  value       = module.ec2.app_server_ids
}

output "app_server_private_ips" {
  description = "Private IP addresses of the application servers"
  value       = module.ec2.app_server_private_ips
}

# ── ALB Outputs ───────────────────────────────────────────────────────────────

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = module.alb.alb_id
}

output "alb_dns_name" {
  description = "DNS name of the ALB (use to access WordPress)"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = module.alb.alb_zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_group_arn
}
