# =============================================================================
# Outputs — EKS Bootstrap Module
# =============================================================================

output "instance_id" {
  description = "ID da instância bootstrap (será terminada automaticamente)"
  value       = aws_instance.bootstrap.id
}

output "private_ip" {
  description = "IP privado da instância bootstrap"
  value       = aws_instance.bootstrap.private_ip
}

output "security_group_id" {
  description = "ID do security group criado para o bootstrap"
  value       = aws_security_group.bootstrap.id
}
