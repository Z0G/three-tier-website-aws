# ── Elastic File System ───────────────────────────────────────────────────────

resource "aws_efs_file_system" "main" {
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  encrypted                       = var.enable_encryption

  tags = {
    Name    = "${var.project_name}-efs"
    Project = var.project_name
  }
}

# ── EFS Mount Targets (one per subnet) ─────────────────────────────────────────

resource "aws_efs_mount_target" "main" {
  count = length(var.private_app_subnet_ids)

  file_system_id      = aws_efs_file_system.main.id
  subnet_id           = var.private_app_subnet_ids[count.index]
  security_groups     = [var.efs_security_group_id]

  depends_on = [aws_efs_file_system.main]
}

# ── EFS Access Point ───────────────────────────────────────────────────────────

resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/app"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = {
    Name    = "${var.project_name}-efs-access-point"
    Project = var.project_name
  }

  depends_on = [aws_efs_file_system.main]
}
