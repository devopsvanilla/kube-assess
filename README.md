# Kubernetes Assessment Script

Script automatizado para realizar assessment completo de clusters Kubernetes, coletando informações sobre infraestrutura, aplicações, segurança, performance e governança.

## 🎯 Propósito

Este script foi desenvolvido para facilitar a avaliação e auditoria de clusters Kubernetes, gerando um relatório abrangente com informações essenciais para:

- **Análise de Infraestrutura**: Avaliar a saúde e configuração dos nodes
- **Auditoria de Segurança**: Identificar vulnerabilidades e configurações inseguras
- **Assessment de Aplicações**: Verificar workloads, recursos e configurações
- **Análise de Performance**: Identificar gargalos e problemas de recursos
- **Governança e Compliance**: Validar políticas e padrões estabelecidos
- **Troubleshooting**: Diagnosticar problemas e identificar pods com falhas

## 📋 Requisitos

### Pré-requisitos Obrigatórios

- **kubectl**: Cliente de linha de comando do Kubernetes
- **jq**: Processador JSON para linha de comando
- **Acesso ao cluster**: Configuração válida do kubeconfig
- **Permissões**: Acesso de leitura aos recursos do cluster (recomendado: cluster-admin ou view)

### Requisitos Opcionais

- **helm**: Para coletar informações sobre releases Helm instalados
- **metrics-server**: Para coletar métricas de uso de recursos (CPU/memória)

### Instalação dos Requisitos (Ubuntu/Debian)

```bash
# Instalar kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Instalar jq
sudo apt update && sudo apt install -y jq

# Instalar helm (opcional)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 🔍 Informações Coletadas

### 🔧 Infraestrutura
- Versão do cluster Kubernetes
- Lista e status dos nodes
- Componentes do control plane
- Taints e labels dos nodes
- Alocação de recursos (CPU/memória)

### 📦 Workloads e Recursos
- Namespaces
- Deployments, DaemonSets, StatefulSets
- CronJobs e Jobs
- ConfigMaps e Secrets
- Horizontal Pod Autoscalers (HPA)
- Vertical Pod Autoscalers (VPA)
- Pod Disruption Budgets (PDB)

### 🌐 Exposição de Aplicações
- Services (ClusterIP, NodePort, LoadBalancer)
- Ingress e Ingress Classes
- Ingress Controllers
- Endpoints

### 🔒 Segurança
- Roles e RoleBindings (RBAC)
- ClusterRoles e ClusterRoleBindings
- Service Accounts
- Network Policies
- Pod Security Policies (deprecated)
- Secrets com configurações em plaintext
- Service Accounts com automount habilitado
- Labels de segurança por namespace

### 📊 Observabilidade
- Uso de recursos por node (top nodes)
- Uso de recursos por pod (top pods)
- Eventos do cluster
- Pods com problemas (não Running/Succeeded)
- Status do Metrics Server
- Pods com erros (CrashLoopBackOff, Error, OOMKilled)
- Contagem de restarts por pod
- Pods sem resource limits/requests definidos
- Readiness e Liveness probes

### ⚙️ Governança
- Resource Quotas
- Limit Ranges
- Validating Webhooks
- Mutating Webhooks
- API Resources disponíveis
- API Versions
- Custom Resource Definitions (CRDs)
- Políticas Kyverno (se instalado)
- Constraints OPA Gatekeeper (se instalado)

### 🚀 Performance e Saúde
- Status detalhado dos pods
- Pods com erros críticos
- Histórico de restarts
- Configuração de probes

### 💾 Armazenamento
- Persistent Volumes (PV)
- Persistent Volume Claims (PVC)
- Storage Classes e seus parâmetros
- Volume Snapshots (se disponível)
- Volume Snapshot Classes

### 🌐 Rede Avançada
- CNI Plugin em uso (Calico, Flannel, Weave, Cilium, Canal)
- Ingress Controllers
- Ingress Classes

### 🔐 Certificados
- Certificates (cert-manager)
- Certificate Requests
- Issuers e ClusterIssuers

### 🗄️ Componentes Especiais
- Pods do etcd
- Releases Helm instalados

## 🚀 Como Executar

### Execução Básica

```bash
# Dar permissão de execução ao script
chmod +x kube-assess.sh

# Executar o script
./kube-assess.sh
```

### Execução com Contexto Específico

```bash
# Verificar contexto atual
kubectl config current-context

# Mudar para contexto desejado
kubectl config use-context <nome-do-contexto>

# Executar o script
./kube-assess.sh
```

### Execução em Múltiplos Clusters

```bash
# Loop para executar em todos os contextos
for context in $(kubectl config get-contexts -o name); do
    echo "Coletando dados do cluster: $context"
    kubectl config use-context $context
    ./kube-assess.sh
done
```

## 📂 Estrutura de Saída

O script cria um diretório com timestamp contendo todos os arquivos coletados:

```
k8s_assessment_YYYYMMDD_HHMMSS/
├── cluster_version.txt
├── nodes.txt
├── nodes_describe.txt
├── nodes_taints_labels.json
├── deployments.txt
├── services.txt
├── ingress.txt
├── rbac_roles.txt
├── network_policies.txt
├── events.txt
├── pods_status.txt
├── pods_errors.txt
├── persistent_volumes.txt
├── storage_classes.txt
├── helm_releases.txt
└── ... (e muitos outros arquivos)
```

### Tipos de Arquivo

- **`.txt`**: Saída tabular legível
- **`.json`**: Dados estruturados para análise automatizada

## ⚠️ Observações Importantes

### Segurança
- O script **não modifica** nenhum recurso do cluster (apenas leitura)
- Alguns arquivos podem conter informações sensíveis (secrets, configurações)
- **Não compartilhe** os arquivos gerados sem revisar o conteúdo
- Considere criptografar ou proteger o diretório de saída

### Performance
- A execução pode levar alguns minutos em clusters grandes
- Comandos com `2>/dev/null` falham silenciosamente se o recurso não existir
- Alguns comandos requerem extensões específicas (metrics-server, cert-manager, etc.)

### Permissões
- O script requer permissões de **leitura** em todos os recursos
- Alguns comandos podem falhar se o usuário não tiver permissões suficientes
- Para assessment completo, recomenda-se role **cluster-admin** ou **view**

## 🔧 Troubleshooting

### Erro: "kubectl: command not found"
```bash
# Instalar kubectl conforme documentação oficial
# Verificar PATH
echo $PATH
```

### Erro: "jq: command not found"
```bash
sudo apt install -y jq
```

### Erro: "The connection to the server was refused"
```bash
# Verificar configuração do kubeconfig
kubectl config view

# Testar conexão
kubectl cluster-info
```

### Erro de Permissão
```bash
# Verificar permissões atuais
kubectl auth can-i --list

# Solicitar acesso adequado ao administrador do cluster
```

## 📊 Análise dos Resultados

Após a execução, você pode:

1. **Revisar arquivos críticos primeiro**:
   - `pods_errors.txt` - Pods com problemas
   - `events.txt` - Eventos recentes
   - `pods_no_resources.json` - Pods sem limits definidos

2. **Usar ferramentas de análise**:
   ```bash
   # Contar pods por namespace
   grep -E "^[a-z]" pods_status.txt | awk '{print $1}' | sort | uniq -c
   
   # Identificar pods com muitos restarts
   jq -r 'select(.restarts > 5)' pod_restarts.json
   ```

3. **Comparar assessments ao longo do tempo** para identificar tendências

## 📝 Licença

Este script é fornecido "como está" para fins de assessment e diagnóstico de clusters Kubernetes.

## 🤝 Contribuições

Sugestões e melhorias são bem-vindas! Considere adicionar:
- Análise de logs de pods com problemas
- Verificação de imagens vulneráveis
- Validação de best practices
- Geração de relatório consolidado em HTML/PDF

---

**Desenvolvido para facilitar o assessment e manutenção de clusters Kubernetes** 🚀
