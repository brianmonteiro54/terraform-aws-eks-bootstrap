# 📖 Documentação Auto-gerada

A seção abaixo é **automaticamente populada** pelo [terraform-docs](https://terraform-docs.io/) via GitHub Actions (`terraform-docs/gh-actions@v1.3.0`) a cada Pull Request. O job injeta automaticamente a documentação de **Requirements**, **Providers**, **Modules**, **Resources**, **Inputs** e **Outputs** entre os marcadores abaixo.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.31 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.31 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_instance.bootstrap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.bootstrap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.amazon_linux_2023](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apply_namespaces"></a> [apply\_namespaces](#input\_apply\_namespaces) | Aplicar namespaces YAML | `bool` | `true` | no |
| <a name="input_argocd_namespace"></a> [argocd\_namespace](#input\_argocd\_namespace) | Namespace para o ArgoCD | `string` | `"argocd"` | no |
| <a name="input_argocd_version"></a> [argocd\_version](#input\_argocd\_version) | Versão do ArgoCD Helm chart | `string` | `"7.8.23"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Nome do cluster EKS | `string` | n/a | yes |
| <a name="input_eks_cluster_security_group_id"></a> [eks\_cluster\_security\_group\_id](#input\_eks\_cluster\_security\_group\_id) | Security Group ID do cluster EKS (para comunicação com o API server) | `string` | n/a | yes |
| <a name="input_external_secrets_values"></a> [external\_secrets\_values](#input\_external\_secrets\_values) | Conteúdo YAML do values.yaml do external-secrets helm chart | `string` | `""` | no |
| <a name="input_external_secrets_version"></a> [external\_secrets\_version](#input\_external\_secrets\_version) | Versão do External Secrets Helm chart | `string` | `"0.17.0"` | no |
| <a name="input_extra_commands"></a> [extra\_commands](#input\_extra\_commands) | Comandos extras para executar após todo o setup | `string` | `""` | no |
| <a name="input_helm_version"></a> [helm\_version](#input\_helm\_version) | Versão do Helm | `string` | `"3.17.3"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | IAM Instance Profile name (ex: LabInstanceProfile no AWS Academy) | `string` | n/a | yes |
| <a name="input_ingress_nginx_acm_yaml"></a> [ingress\_nginx\_acm\_yaml](#input\_ingress\_nginx\_acm\_yaml) | Conteúdo YAML do Service do ingress-nginx com ACM/NLB | `string` | `""` | no |
| <a name="input_ingress_nginx_yaml"></a> [ingress\_nginx\_yaml](#input\_ingress\_nginx\_yaml) | Conteúdo YAML do ingress-nginx controller | `string` | `""` | no |
| <a name="input_install_argocd"></a> [install\_argocd](#input\_install\_argocd) | Instalar ArgoCD via Helm | `bool` | `true` | no |
| <a name="input_install_external_secrets"></a> [install\_external\_secrets](#input\_install\_external\_secrets) | Instalar External Secrets Operator via Helm | `bool` | `true` | no |
| <a name="input_install_ingress_nginx"></a> [install\_ingress\_nginx](#input\_install\_ingress\_nginx) | Aplicar manifesto do ingress-nginx | `bool` | `true` | no |
| <a name="input_install_metrics_server"></a> [install\_metrics\_server](#input\_install\_metrics\_server) | Instalar Metrics Server | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Tipo da instância EC2 bootstrap | `string` | `"t3.micro"` | no |
| <a name="input_kubectl_version"></a> [kubectl\_version](#input\_kubectl\_version) | Versão do kubectl | `string` | `"1.32.0"` | no |
| <a name="input_namespaces_yaml"></a> [namespaces\_yaml](#input\_namespaces\_yaml) | Conteúdo YAML dos namespaces a serem criados | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID privada (com NAT Gateway) para a instância bootstrap | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags adicionais | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID onde o EKS está | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | ID da instância bootstrap (será terminada automaticamente) |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | IP privado da instância bootstrap |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID do security group criado para o bootstrap |
<!-- END_TF_DOCS -->
