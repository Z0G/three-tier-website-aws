# ── DB Subnet Group ───────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name_prefix     = "${var.project_name}-db-subnet-group-"
  subnet_ids      = var.private_db_subnet_ids
  
  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  }
}

# ── RDS MySQL Database ─────────────────────────────────────────────────────────

resource "aws_db_instance" "mysql" {
  identifier     = "${var.project_name}-mysql-db"
  engine         = "mysql"
  engine_version = var.engine_version

  instance_class       = var.db_instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = "gp2"
  storage_encrypted    = true
  
  db_name  = var.db_name
  username = var.db_master_username
  password = var.db_master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]

  publicly_accessible       = false
  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_period
  backup_window             = "03:00-04:00"
  maintenance_window        = "sun:04:00-sun:05:00"
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-mysql-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  deletion_protection = false
  
  tags = {
    Name    = "${var.project_name}-mysql-db"
    Project = var.project_name
  }

  depends_on = [aws_db_subnet_group.main]
}
