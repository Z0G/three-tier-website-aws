# ── Data source to get latest Amazon Linux AMI ────────────────────────────────

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── Setup/Bastion EC2 Instance (in public subnet) ────────────────────────────

resource "aws_instance" "setup" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.web_server_security_group_id, var.ssh_security_group_id, var.alb_security_group_id]

  user_data = base64encode(templatefile("${path.module}/scripts/setup-instance.sh", {
    efs_dns_name = var.efs_dns_name
  }))

  tags = {
    Name    = "${var.project_name}-setup-instance"
    Project = var.project_name
  }

  depends_on = []
}

# ── Application Server EC2 Instances (in private subnets) ──────────────────────

resource "aws_instance" "app_server" {
  count         = length(var.private_app_subnet_ids)
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  subnet_id              = var.private_app_subnet_ids[count.index]
  vpc_security_group_ids = [var.web_server_security_group_id, var.ssh_security_group_id]

  user_data = base64encode(templatefile("${path.module}/scripts/app-server.sh", {
    efs_dns_name = var.efs_dns_name
  }))

  tags = {
    Name    = "${var.project_name}-app-server-${count.index + 1}"
    Project = var.project_name
  }

  depends_on = []
}
