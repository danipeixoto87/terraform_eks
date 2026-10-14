# DevOps API Platform

Laboratório DevOps que integra uma API REST em Go, Docker, Kubernetes, Terraform, Prometheus e Grafana. O projeto demonstra práticas de desenvolvimento, containerização, implantação, observabilidade, infraestrutura como código e automação.

> **Estado do ambiente:** a aplicação e o monitoramento foram configurados localmente com Docker e Minikube. As notificações por e-mail ainda não estão configuradas. Não é necessário manter recursos AWS ativos para executar o laboratório local.

## Arquitetura

```text
Cliente HTTP
    |
    v
Go API (8080)
    +---- /health
    +---- /ready
    +---- /metrics
              |
              v
         Prometheus
              |
              v
           Grafana

Kubernetes / Minikube
    +---- Deployment (2 réplicas)
    +---- Service
    +---- Readiness e liveness probes

Infraestrutura como código:
Terraform + módulos AWS

Automação:
GitHub Actions (integração a revisar)
```

## Tecnologias

- Go 1.26
- Docker com build multi-stage
- Kubernetes e Minikube
- Terraform
- Prometheus
- Grafana
- Git e GitHub
- GitHub Actions e Amazon ECR no escopo de CI/CD

## API

A aplicação está implementada em `cmd/api/main.go`.

| Endpoint | Finalidade |
|---|---|
| `/health` | Verificação de saúde da aplicação |
| `/ready` | Verificação de prontidão para receber tráfego |
| `/metrics` | Métricas no formato Prometheus |

A instrumentação inclui contagem de requisições HTTP, duração das requisições e métricas do runtime Go.

### Testes

Requisitos: Go compatível com a versão indicada em `go.mod`.

```bash
go mod download
go test ./...
go vet ./...
```

### Executar localmente

```bash
go run ./cmd/api
```

Em outro terminal:

```bash
curl -i http://localhost:8080/health
curl -i http://localhost:8080/ready
curl -s http://localhost:8080/metrics
```

A porta padrão da aplicação é `8080`.

## Docker

Construa a imagem:

```bash
docker build -t devops-api:metrics .
```

Execute o container:

```bash
docker run --rm -p 8080:8080 devops-api:metrics
```

Valide os endpoints:

```bash
curl -i http://localhost:8080/health
curl -s http://localhost:8080/metrics
```

Se a porta 8080 já estiver ocupada, libere-a ou escolha outra porta no host, mantendo a porta interna do container em 8080.

## Kubernetes com Minikube

### Pré-requisitos

- Docker
- kubectl
- Minikube

Confira os perfis e o contexto atual antes de executar comandos:

```bash
minikube profile list
kubectl config current-context
```

Selecione o contexto de laboratório, caso o perfil `devops-lab` exista:

```bash
kubectl config use-context devops-lab
```

Construa e carregue a imagem local:

```bash
docker build -t devops-api:metrics .
minikube image load devops-api:metrics -p devops-lab
```

Aplique os manifests:

```bash
kubectl apply -f k8s/
kubectl rollout status deployment/devops-api
kubectl get pods
kubectl get service devops-api
```

Arquivos Kubernetes:

- `k8s/deployments.yml`: Deployment com duas réplicas, probes e limites de recursos.
- `k8s/service.yml`: Service que expõe a aplicação na porta 8080.

O Deployment usa `imagePullPolicy: Never`. Portanto, a imagem precisa existir no ambiente Docker utilizado pelo Minikube antes da implantação.

Para acessar a API localmente:

```bash
kubectl port-forward service/devops-api 8080:8080
```

Com o encaminhamento ativo, acesse `http://localhost:8080/health` e `http://localhost:8080/metrics`.

## Prometheus e Grafana

O Prometheus coleta métricas da API pelo endpoint `/metrics`. O Grafana utiliza o Prometheus como fonte de dados para os dashboards.

### Consultas PromQL

Requisições por segundo:

```promql
sum(rate(devops_api_http_requests_total[5m]))
```

Latência no percentil 95:

```promql
histogram_quantile(
  0.95,
  sum by (le) (
    rate(devops_api_http_request_duration_seconds_bucket[5m])
  )
)
```

Taxa percentual de respostas HTTP 5xx:

```promql
100 *
sum(rate(devops_api_http_requests_total{status=~"5.."}[5m]))
/
clamp_min(sum(rate(devops_api_http_requests_total[5m])), 1e-9)
```

Essas consultas dependem das métricas efetivamente expostas pela aplicação.

### Alertas configurados

| Alerta | Condição | Severidade |
|---|---|---|
| `DevopsApiDown` | `up{job="devops-api"} == 0` durante 1 minuto | `critical` |
| `DevopsApiHigh5xxErrorRate` | Taxa de erros HTTP 5xx superior a 5% durante 2 minutos | `warning` |

As regras foram carregadas no Prometheus. Na última verificação, o alvo da API retornou `1`, e a consulta de erros HTTP 5xx não apresentou séries. Os alertas estavam `Inactive`, comportamento esperado nessas condições.

**Alertmanager e notificações externas:** o envio de e-mails não está configurado atualmente.

Os valores Helm utilizados no laboratório ainda precisam ser organizados e versionados no repositório para facilitar a reprodução do monitoramento.

## Terraform e AWS

O repositório contém módulos de infraestrutura para rede, cluster EKS, managed node group e AWS Load Balancer Controller.

O ambiente local de API e monitoramento não exige recursos AWS ativos. Antes de executar `terraform apply`, revise os recursos, os custos, a região, as variáveis e as permissões.

Não versione estados do Terraform, planos, credenciais, chaves privadas ou arquivos de variáveis locais com dados sensíveis.

## CI/CD

O projeto tem histórico de configuração de GitHub Actions e publicação de imagens no Amazon ECR. A integração completa precisa ser revisada antes de ser considerada reproduzível.

Não inclua tokens, senhas ou chaves de acesso nos workflows ou no repositório. Utilize secrets e permissões mínimas.

## Segurança e boas práticas

- Execute containers com privilégios mínimos.
- Mantenha readiness e liveness probes.
- Defina requests e limits de recursos.
- Não versione credenciais nem arquivos `.env`.
- Revise o `.gitignore` antes de cada commit.
- Valide os testes e os manifests antes de implantar.
- Evite manter recursos AWS ativos quando não forem necessários.

## Estrutura principal

```text
.
├── cmd/
│   └── api/
│       ├── main.go
│       └── main_test.go
├── k8s/
│   ├── deployments.yml
│   └── service.yml
├── Dockerfile
├── go.mod
├── go.sum
├── .dockerignore
├── .gitignore
└── README.md
```

## Próximas melhorias

- Versionar os valores Helm do Prometheus e Grafana.
- Documentar a instalação e remoção do monitoramento.
- Configurar Alertmanager e notificações, se necessário.
- Revisar os workflows de CI/CD.
- Automatizar validações de Go, Docker e Kubernetes.
- Adicionar capturas de tela do dashboard.
- Atualizar a documentação automática do Terraform.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 3.3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 3.2.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_eks_cluster"></a> [eks\_cluster](#module\_eks\_cluster) | ./modules/cluster | n/a |
| <a name="module_eks_lb_controller"></a> [eks\_lb\_controller](#module\_eks\_lb\_controller) | ./modules/aws-load-balancer-controller | n/a |
| <a name="module_eks_mng"></a> [eks\_mng](#module\_eks\_mng) | ./modules/managed-node-group | n/a |
| <a name="module_eks_network"></a> [eks\_network](#module\_eks\_network) | ./modules/network | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block for the VPC | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The project name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->