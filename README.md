# DevOps API Platform

Laboratório DevOps que integra uma API REST em Go, Docker, Kubernetes, Terraform, Prometheus e Grafana. O projeto demonstra práticas de desenvolvimento, containerização, infraestrutura como código, observabilidade, automação de CI/CD e publicação de imagens em um registry privado.

> **Estado do projeto:** a API e o monitoramento foram validados localmente com Docker e Minikube. O pipeline de GitHub Actions foi executado com sucesso e publicou uma imagem no Amazon ECR. O cluster EKS não está ativo nesta versão, para evitar custos desnecessários. Notificações por e-mail ainda não estão configuradas.

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
    +---- Requests e limits de recursos

Infraestrutura como código
    +---- Terraform
    +---- Rede AWS
    +---- Cluster EKS
    +---- Managed Node Group
    +---- AWS Load Balancer Controller

CI/CD
    +---- GitHub Actions
    +---- Testes e validações Go
    +---- Build Docker
    +---- Autenticação AWS via OIDC
    +---- Publicação no Amazon ECR
```

## Tecnologias

- Go 1.26
- Docker com build multi-stage
- Kubernetes e Minikube
- Terraform
- AWS EKS e Amazon ECR
- GitHub Actions
- Prometheus
- Grafana
- Git e GitHub

## API

A aplicação está implementada em `cmd/api/main.go`.

| Endpoint | Finalidade |
|---|---|
| `/health` | Verifica a saúde da aplicação |
| `/ready` | Verifica se a aplicação está pronta para receber tráfego |
| `/metrics` | Expõe métricas no formato Prometheus |

A instrumentação inclui contagem de requisições HTTP, duração das requisições e métricas do runtime Go.

### Testes e validações

Requisitos: Go compatível com a versão indicada em `go.mod`.

```bash
go mod download
go test ./...
go vet ./...
go build ./cmd/api
```

### Executar localmente

Inicie a aplicação:

```bash
go run ./cmd/api
```

Em outro terminal, valide os endpoints:

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

O Dockerfile utiliza múltiplos estágios para compilar a aplicação e gerar uma imagem final mais enxuta.

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

Selecione o contexto do laboratório, caso o perfil `devops-lab` exista:

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

- `k8s/deployments.yml`: Deployment com duas réplicas, probes de saúde e limites de recursos.
- `k8s/service.yml`: Service do tipo NodePort que encaminha o tráfego para a API na porta 8080.

O Deployment utiliza `imagePullPolicy: Never`. Portanto, a imagem precisa estar disponível no ambiente de containers utilizado pelo Minikube antes da implantação.

Para acessar a API localmente:

```bash
kubectl port-forward service/devops-api 8080:8080
```

Com o encaminhamento ativo, acesse `http://localhost:8080/health` e `http://localhost:8080/metrics`.

## Prometheus e Grafana

O Prometheus coleta métricas da API pelo endpoint `/metrics`. O Grafana utiliza o Prometheus como fonte de dados para dashboards de observabilidade.

### Consultas PromQL

**Requisições por segundo:**

```promql
sum(rate(devops_api_http_requests_total[5m]))
```

**Latência no percentil 95:**

```promql
histogram_quantile(
  0.95,
  sum by (le) (
    rate(devops_api_http_request_duration_seconds_bucket[5m])
  )
)
```

**Taxa percentual de respostas HTTP 5xx:**

```promql
100 *
sum(rate(devops_api_http_requests_total{status=~"5.."}[5m]))
/
clamp_min(sum(rate(devops_api_http_requests_total[5m])), 1e-9)
```

Essas consultas dependem das métricas efetivamente expostas pela aplicação e do intervalo de coleta do Prometheus.

### Alertas configurados

| Alerta | Condição | Severidade |
|---|---|---|
| `DevopsApiDown` | `up{job="devops-api"} == 0` durante 1 minuto | `critical` |
| `DevopsApiHigh5xxErrorRate` | Taxa de erros HTTP 5xx superior a 5% durante 2 minutos | `warning` |

As regras foram carregadas no Prometheus durante a validação local. Na última verificação, o alvo da API retornou `1`, e a consulta de erros HTTP 5xx não apresentou séries. Os alertas estavam `Inactive`, comportamento esperado nessas condições.

O envio de notificações externas por Alertmanager e e-mail ainda não está configurado.

Os valores Helm utilizados no laboratório precisam ser organizados e versionados no repositório para facilitar a reprodução completa do ambiente de monitoramento.

## Terraform e AWS

O repositório contém módulos de infraestrutura para:

- Rede AWS.
- Cluster EKS.
- Managed Node Group.
- AWS Load Balancer Controller.

O ambiente local de API e monitoramento não exige recursos AWS ativos.

Antes de executar `terraform apply`, revise os recursos, a região, as variáveis, as permissões e os custos envolvidos. O cluster EKS não está ativo nesta versão do projeto.

Não versione estados do Terraform, planos, credenciais, chaves privadas ou arquivos de variáveis locais com dados sensíveis.

## CI/CD com GitHub Actions

O projeto utiliza GitHub Actions para executar verificações de qualidade, construir a imagem Docker e publicar a imagem no Amazon ECR.

O workflow é executado em eventos de `push` e `pull_request` direcionados à branch `main`.

### Etapas do pipeline

1. Checkout do repositório.
2. Configuração do Go a partir do `go.mod`.
3. Verificação da formatação com `gofmt`.
4. Execução dos testes automatizados com `go test -v ./...`.
5. Análise estática com `go vet ./...`.
6. Compilação da aplicação com `go build`.
7. Construção da imagem Docker.
8. Autenticação na AWS usando OIDC e a role `GitHubActionsECRPushRole`.
9. Login no Amazon ECR.
10. Publicação da imagem no repositório ECR `devops-api`.

### Comportamento por evento

- **Pull request para `main`:** executa as verificações de Go e constrói a imagem Docker, sem publicar no ECR.
- **Push para `main`:** executa as verificações, constrói a imagem, autentica na AWS e publica a imagem no ECR.

As imagens são identificadas pelo SHA completo do commit, facilitando a rastreabilidade entre o código-fonte e o artefato publicado.

### Amazon ECR

O repositório utilizado pelo workflow é:

```text
090082365393.dkr.ecr.us-east-1.amazonaws.com/devops-api
```

A publicação de imagem foi validada no commit `837ddec`. O digest registrado nessa execução foi:

```text
sha256:fafda11503aa8418824b0bc411e69422cedfd9ad05886b037a59b73c10156599
```

Para consultar as imagens publicadas, acesse o Amazon ECR no console da AWS, na região `us-east-1`, e abra o repositório `devops-api`.

### Segurança do pipeline

- A autenticação na AWS utiliza OIDC, evitando a necessidade de armazenar chaves de acesso permanentes da AWS no workflow.
- A role `GitHubActionsECRPushRole` utiliza uma trust policy vinculada ao provedor OIDC do GitHub.
- A política inline `PushDevopsApiToECR` limita as permissões de publicação ao repositório ECR `devops-api`, além da permissão necessária para obter um token de autorização.
- A trust policy e as permissões IAM devem continuar restritas ao repositório e à branch autorizados.
- Não inclua tokens, senhas, chaves privadas ou credenciais nos arquivos do repositório.

A publicação da imagem no ECR foi validada. O deploy automatizado no EKS não faz parte do fluxo validado nesta versão.

## Segurança e boas práticas

- Execute containers com privilégios mínimos.
- Mantenha readiness e liveness probes.
- Defina requests e limits de recursos.
- Não versione credenciais nem arquivos `.env`.
- Revise o `.gitignore` antes de cada commit.
- Valide testes, build e manifests antes de implantar.
- Restrinja as permissões de IAM ao mínimo necessário.
- Evite manter recursos AWS ativos quando não forem necessários.

## Estrutura principal

```text
.
├── .github/
│   └── workflows/
├── cmd/
│   └── api/
│       ├── main.go
│       └── main_test.go
├── k8s/
│   ├── deployments.yml
│   └── service.yml
├── modules/
│   ├── aws-load-balancer-controller/
│   ├── cluster/
│   ├── managed-node-group/
│   └── network/
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
- Configurar Alertmanager e notificações externas, se necessário.
- Adicionar capturas de tela do dashboard Grafana.
- Automatizar a validação dos manifests Kubernetes na CI.
- Documentar um procedimento opcional de implantação no EKS, incluindo custos e limpeza dos recursos.
- Atualizar a documentação automática do Terraform.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| [terraform](#requirement_terraform) | >= 1.10.0 |
| [aws](#requirement_aws) | ~> 5.0 |
| [helm](#requirement_helm) | 3.3.0 |
| [kubernetes](#requirement_kubernetes) | 3.2.1 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| [eks_cluster](#module_eks_cluster) | ./modules/cluster | n/a |
| [eks_lb_controller](#module_eks_lb_controller) | ./modules/aws-load-balancer-controller | n/a |
| [eks_mng](#module_eks_mng) | ./modules/managed-node-group | n/a |
| [eks_network](#module_eks_network) | ./modules/network | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| [cidr_block](#input_cidr_block) | The CIDR block for the VPC | `string` | n/a | yes |
| [project_name](#input_project_name) | The project name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
