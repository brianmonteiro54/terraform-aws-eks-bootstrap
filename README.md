# terraform-aws-eks-bootstrap

Módulo Terraform que cria uma EC2 temporária dentro da VPC do EKS para executar o setup inicial do cluster (ArgoCD, Ingress NGINX, External Secrets, Metrics Server, Namespaces) e se auto-destrói após a conclusão.

## Por que este módulo existe?

Quando o EKS tem **endpoint privado**, não é possível executar `kubectl` ou `helm` de fora da VPC (ex: GitHub Actions, máquina local). Este módulo resolve isso criando uma instância EC2 temporária que:

1. Nasce dentro da VPC (subnet privada com NAT Gateway)
2. Configura `kubeconfig` automaticamente via `aws eks update-kubeconfig`
3. Executa todos os comandos de setup na ordem correta
4. Faz `shutdown -h now` ao terminar → a instância é **terminada automaticamente**

## Comportamento de auto-destruição

A instância usa `instance_initiated_shutdown_behavior = "terminate"`. Quando o script termina (sucesso ou falha), o trap `EXIT` executa `shutdown -h now`, e a AWS **termina a instância automaticamente**. Não é necessário nenhuma permissão IAM adicional para isso.

## O que é instalado (na ordem)

| Passo | Componente | Método |
|-------|-----------|--------|
| 1 | kubectl, helm, aws-cli | Binários |
| 2 | kubeconfig | `aws eks update-kubeconfig` |
| 3 | Namespaces | `kubectl apply -f` |
| 4 | Metrics Server | `kubectl apply -f` (upstream) |
| 5 | Ingress NGINX | `kubectl apply -f` + Service ACM |
| 6 | External Secrets | CRDs + Helm chart |
| 7 | ArgoCD | Helm chart |
| 8 | Comandos extras | Customizável |

Cada passo é controlado por uma feature flag (`install_argocd`, `install_metrics_server`, etc.) e pode ser desabilitado individualmente.

## Uso

```hcl
module "eks_bootstrap" {
  source = "git::https://github.com/brianmonteiro54/terraform-aws-eks-bootstrap.git//modules/eks-bootstrap?ref=<commit-sha>"

  cluster_name                  = module.eks.cluster_name
  vpc_id                        = module.vpc.vpc_id
  subnet_id                     = module.vpc.private_subnet_ids[0]
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  iam_instance_profile          = "LabInstanceProfile"

  namespaces_yaml        = file("kubernetes/namespace.yaml")
  ingress_nginx_yaml     = file("kubernetes/ingress-nginx-controller.yaml")
  ingress_nginx_acm_yaml = file("kubernetes/ingress-nginx-acm-lb.yaml")
  external_secrets_values = file("kubernetes/external-secrets.yaml")

  depends_on = [module.eks, module.vpc]
}
```

## Requisitos

- Subnet privada com **NAT Gateway** (para baixar pacotes da internet)
- **IAM Instance Profile** com acesso ao EKS (`LabInstanceProfile` no Academy, ou profile com `eks:DescribeCluster`)
- **Security Group do EKS** passado via `eks_cluster_security_group_id` (para a EC2 conseguir comunicar com o API server)

## Logs

Todo o output do bootstrap é gravado em `/var/log/eks-bootstrap.log` na instância. Como a instância se auto-destrói, consulte o **System Log** no console da AWS (EC2 → Instance → Actions → Monitor → Get System Log) se precisar debugar.

## Nota sobre re-execução

O Terraform sempre recria a instância ao re-aplicar (porque o `user_data` muda). Se você precisar re-executar o bootstrap, basta `terraform apply` novamente. A instância anterior já terá sido terminada.
