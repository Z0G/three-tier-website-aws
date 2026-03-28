variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instances will be launched"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the setup/bastion instance"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs for application servers"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of the EC2 key pair"
  type        = string
}

variable "web_server_security_group_id" {
  description = "ID of the web server security group"
  type        = string
}

variable "ssh_security_group_id" {
  description = "ID of the SSH security group"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "efs_id" {
  description = "ID of the EFS file system"
  type        = string
}

variable "efs_dns_name" {
  description = "DNS name of the EFS"
  type        = string
}

variable "efs_access_point_id" {
  description = "ID of the EFS access point"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Amazon Linux)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Instance type for EC2"
  type        = string
  default     = "t2.micro"
}
