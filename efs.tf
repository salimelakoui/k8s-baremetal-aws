resource "aws_efs_file_system" "efs_prod" {
  creation_token = "SEL Prod EFS"
  encrypted = false

  tags = {
        Name = "SEL - Preprod"
  }
}

resource "aws_efs_mount_target" "mount_prod" {
  file_system_id = aws_efs_file_system.efs_prod.id
  subnet_id      = aws_subnet.sel_public.id
  security_groups = [aws_security_group.sel_ssh.id]
}
