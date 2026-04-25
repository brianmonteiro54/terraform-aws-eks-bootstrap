# =============================================================================
# EKS Bootstrap Module
# =============================================================================
# Cria uma EC2 temporária na VPC do EKS, executa todos os comandos de setup
# (ArgoCD, Ingress NGINX, External Secrets, Metrics Server, Namespaces)
# e se auto-destrói via shutdown -> terminate.
#
# Requisitos:
#   - Subnet privada com NAT Gateway (para baixar pacotes)
#   - Security Group com saída HTTPS para a internet e para o EKS API
#   - IAM Instance Profile com acesso ao EKS (LabRole no Academy)
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "bootstrap" {
  name_prefix = "${var.cluster_name}-bootstrap-"
  description = "Security group for EKS bootstrap instance"
  vpc_id      = var.vpc_id

  # Saída para internet (NAT) — baixar pacotes, helm charts, imagens
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr -- Bootstrap instance needs internet access via NAT to download packages
    description = "HTTPS outbound"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr -- Bootstrap instance needs internet access via NAT to download packages
    description = "HTTP outbound"
  }

  # DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr -- DNS resolution required
    description = "DNS UDP"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr -- DNS resolution required
    description = "DNS TCP"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-bootstrap-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Bootstrap EC2 Instance
# -----------------------------------------------------------------------------
resource "aws_instance" "bootstrap" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  monitoring    = true
  ebs_optimized = true

  vpc_security_group_ids = [
    aws_security_group.bootstrap.id,
    var.eks_cluster_security_group_id
  ]

  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # CRITICAL: quando a instância faz shutdown, ela é terminada automaticamente
  instance_initiated_shutdown_behavior = "terminate"

  # IMDSv2 (segurança)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data_base64 = base64gzip(templatefile("${path.module}/scripts/bootstrap.sh", {
    cluster_name             = var.cluster_name
    region                   = data.aws_region.current.id
    kubectl_version          = var.kubectl_version
    helm_version             = var.helm_version
    argocd_namespace         = var.argocd_namespace
    argocd_version           = var.argocd_version
    external_secrets_version = var.external_secrets_version
    namespaces_yaml          = var.namespaces_yaml
    ingress_nginx_yaml       = var.ingress_nginx_yaml
    ingress_nginx_acm_yaml   = var.ingress_nginx_acm_yaml
    external_secrets_values  = var.external_secrets_values
    install_argocd           = var.install_argocd
    install_ingress_nginx    = var.install_ingress_nginx
    install_external_secrets = var.install_external_secrets
    install_metrics_server   = var.install_metrics_server
    metrics_server_version   = var.metrics_server_version
    apply_namespaces         = var.apply_namespaces
    extra_commands           = var.extra_commands
    argocd_ingress_enabled   = var.argocd_ingress_enabled
    argocd_ingress_host      = var.argocd_ingress_host
    argocd_ingress_path      = var.argocd_ingress_path
    # Credenciais AWS: passadas via variável ao chamar o módulo
    aws_credentials = var.aws_credentials
  }))

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-bootstrap"
    Purpose   = "EKS Cluster Bootstrap"
    Temporary = "true"
  })
}

