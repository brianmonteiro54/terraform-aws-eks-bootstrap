# =============================================================================
# Variables — EKS Bootstrap Module
# =============================================================================

# -----------------------------------------------------------------------------
# Required
# -----------------------------------------------------------------------------
variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID onde o EKS está"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID privada (com NAT Gateway) para a instância bootstrap"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "Security Group ID do cluster EKS (para comunicação com o API server)"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile name (ex: LabInstanceProfile no AWS Academy). Deixe vazio (\"\") para usar credenciais do scripts/aws_credentials.txt"
  type        = string
  default     = ""
}

variable "aws_credentials" {
  description = <<-EOT
    Conteúdo do arquivo ~/.aws/credentials a ser escrito na EC2 bootstrap.
    Use quando a instância não tiver IAM Instance Profile.
    Formato esperado:
      [default]
      aws_access_key_id=ASIA...
      aws_secret_access_key=...
      aws_session_token=...     # opcional, necessário para credenciais temporárias (STS/Academy)
    Deixe vazio ("") para não configurar credenciais via arquivo (use iam_instance_profile).
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Manifests (YAML strings)
# -----------------------------------------------------------------------------
variable "namespaces_yaml" {
  description = "Conteúdo YAML dos namespaces a serem criados"
  type        = string
  default     = ""
}

variable "ingress_nginx_yaml" {
  description = "Conteúdo YAML do ingress-nginx controller"
  type        = string
  default     = ""
}

variable "ingress_nginx_acm_yaml" {
  description = "Conteúdo YAML do Service do ingress-nginx com ACM/NLB"
  type        = string
  default     = ""
}

variable "external_secrets_values" {
  description = "Conteúdo YAML do values.yaml do external-secrets helm chart"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Feature Flags
# -----------------------------------------------------------------------------
variable "install_argocd" {
  description = "Instalar ArgoCD via Helm"
  type        = bool
  default     = true
}

variable "install_ingress_nginx" {
  description = "Aplicar manifesto do ingress-nginx"
  type        = bool
  default     = true
}

variable "install_external_secrets" {
  description = "Instalar External Secrets Operator via Helm"
  type        = bool
  default     = true
}

variable "install_metrics_server" {
  description = "Instalar Metrics Server"
  type        = bool
  default     = true
}

variable "apply_namespaces" {
  description = "Aplicar namespaces YAML"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Versions
# -----------------------------------------------------------------------------
variable "kubectl_version" {
  description = "Versão do kubectl"
  type        = string
  default     = "1.32.0"
}

variable "helm_version" {
  description = "Versão do Helm"
  type        = string
  default     = "3.17.3"
}

variable "argocd_version" {
  description = "Versão do ArgoCD Helm chart (>= 7.7.0 tem bug de rootpath duplicado no login, usar 7.6.12)"
  type        = string
  default     = "7.6.12"
}

variable "argocd_namespace" {
  description = "Namespace para o ArgoCD"
  type        = string
  default     = "argocd"
}

variable "external_secrets_version" {
  description = "Versão do External Secrets Helm chart"
  type        = string
  default     = "0.17.0"
}

variable "metrics_server_version" {
  description = "Versão do Metrics Server (v0.8.0+ tem bug com appProtocol, usar v0.7.2)"
  type        = string
  default     = "v0.7.2"
}

# -----------------------------------------------------------------------------
# ArgoCD Ingress
# -----------------------------------------------------------------------------
variable "argocd_ingress_enabled" {
  description = "Criar Ingress NGINX para o ArgoCD (requer install_ingress_nginx = true)"
  type        = bool
  default     = false
}

variable "argocd_ingress_host" {
  description = "Host do Ingress do ArgoCD (ex: toggle.pt, meudominio.com)"
  type        = string
  default     = ""
}

variable "argocd_ingress_path" {
  description = "Path prefix do Ingress do ArgoCD (ex: /argocd)"
  type        = string
  default     = "/argocd"
}

# -----------------------------------------------------------------------------
# Instance Configuration
# -----------------------------------------------------------------------------
variable "instance_type" {
  description = "Tipo da instância EC2 bootstrap"
  type        = string
  default     = "t3.micro"
}

# -----------------------------------------------------------------------------
# Extra
# -----------------------------------------------------------------------------
variable "extra_commands" {
  description = "Comandos extras para executar após todo o setup"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags adicionais"
  type        = map(string)
  default     = {}
}
