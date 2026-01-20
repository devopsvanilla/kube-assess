#!/bin/bash

# ============================================================
# Script de Assessment de Cluster Kubernetes
# Autor: Copilot
# Ambiente: Ubuntu
# ============================================================

# Função para verificar se um comando existe
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "[ERRO] O comando '$1' não foi encontrado."
        return 1
    fi
    return 0
}

# Verificação de requisitos
echo "🔍 Verificando requisitos..."

REQUIRED_CMDS=("kubectl" "jq")
MISSING=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! check_command "$cmd"; then
        MISSING+=("$cmd")
    fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
    echo "⚠️ Os seguintes comandos estão faltando: ${MISSING[*]}"
    echo "Sugestão: instale-os com:"
    echo "  sudo apt update && sudo apt install -y kubectl jq"
    echo "Interrompendo execução até que os requisitos sejam atendidos."
    exit 1
fi

# Criar diretório de saída
OUTPUT_DIR="k8s_assessment_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "📂 Resultados serão salvos em: $OUTPUT_DIR"

# ============================================================
# Coleta de informações
# ============================================================

echo "🔧 Coletando informações de infraestrutura..."
kubectl version --short > "$OUTPUT_DIR/cluster_version.txt"
kubectl get nodes -o wide > "$OUTPUT_DIR/nodes.txt"
kubectl describe nodes > "$OUTPUT_DIR/nodes_describe.txt"
kubectl get componentstatuses > "$OUTPUT_DIR/component_status.txt"
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, taints: .spec.taints, labels: .metadata.labels}' > "$OUTPUT_DIR/nodes_taints_labels.json"
kubectl describe nodes | grep -A 5 "Allocated resources" > "$OUTPUT_DIR/nodes_allocation.txt"

echo "📦 Coletando workloads e recursos..."
kubectl get namespaces > "$OUTPUT_DIR/namespaces.txt"
kubectl get all -A > "$OUTPUT_DIR/resources_all.txt"
kubectl get configmaps -A > "$OUTPUT_DIR/configmaps.txt"
kubectl get secrets -A > "$OUTPUT_DIR/secrets.txt"
kubectl get deployments -A -o wide > "$OUTPUT_DIR/deployments.txt"
kubectl get daemonsets -A -o wide > "$OUTPUT_DIR/daemonsets.txt"
kubectl get statefulsets -A -o wide > "$OUTPUT_DIR/statefulsets.txt"
kubectl get cronjobs -A -o wide > "$OUTPUT_DIR/cronjobs.txt"
kubectl get jobs -A -o wide > "$OUTPUT_DIR/jobs.txt"
kubectl get hpa -A > "$OUTPUT_DIR/hpa.txt"
kubectl get vpa -A > "$OUTPUT_DIR/vpa.txt" 2>/dev/null
kubectl get pdb -A > "$OUTPUT_DIR/pod_disruption_budgets.txt"

echo "🌐 Coletando informações de exposição das aplicações..."
kubectl get services -A -o wide > "$OUTPUT_DIR/services.txt"
kubectl describe services -A > "$OUTPUT_DIR/services_describe.txt"
kubectl get ingress -A > "$OUTPUT_DIR/ingress.txt"
kubectl describe ingress -A > "$OUTPUT_DIR/ingress_describe.txt"

echo "🔒 Coletando informações de segurança..."
kubectl get roles,rolebindings -A > "$OUTPUT_DIR/rbac_roles.txt"
kubectl get clusterroles,clusterrolebindings > "$OUTPUT_DIR/rbac_clusterroles.txt"
kubectl get sa -A > "$OUTPUT_DIR/service_accounts.txt"
kubectl get networkpolicies -A > "$OUTPUT_DIR/network_policies.txt"
kubectl get psp -A > "$OUTPUT_DIR/pod_security_policies.txt" 2>/dev/null
kubectl get podsecuritypolicies > "$OUTPUT_DIR/psp_list.txt" 2>/dev/null
kubectl get ns -o json | jq '.items[] | {name: .metadata.name, labels: .metadata.labels}' > "$OUTPUT_DIR/namespace_security_labels.json"
kubectl get secrets -A -o json | jq '.items[] | select(.metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"] != null) | {namespace: .metadata.namespace, name: .metadata.name}' > "$OUTPUT_DIR/secrets_plaintext.json"
kubectl get sa -A -o json | jq '.items[] | select(.automountServiceAccountToken != false) | {namespace: .metadata.namespace, name: .metadata.name}' > "$OUTPUT_DIR/sa_automount.json"

echo "📊 Coletando observabilidade..."
kubectl top nodes > "$OUTPUT_DIR/top_nodes.txt"
kubectl top pods -A > "$OUTPUT_DIR/top_pods.txt"
kubectl get events -A --sort-by=.metadata.creationTimestamp > "$OUTPUT_DIR/events.txt"
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded -o json > "$OUTPUT_DIR/problematic_pods.json"
kubectl get apiservices | grep metrics > "$OUTPUT_DIR/metrics_server_status.txt"
kubectl get endpoints -A > "$OUTPUT_DIR/endpoints.txt"

echo "⚙️ Coletando governança..."
kubectl get resourcequotas -A > "$OUTPUT_DIR/resource_quotas.txt"
kubectl get limitranges -A > "$OUTPUT_DIR/limit_ranges.txt"
kubectl get validatingwebhookconfigurations > "$OUTPUT_DIR/validating_webhooks.txt"
kubectl get mutatingwebhookconfigurations > "$OUTPUT_DIR/mutating_webhooks.txt"
kubectl api-resources > "$OUTPUT_DIR/api_resources.txt"
kubectl api-versions > "$OUTPUT_DIR/api_versions.txt"
kubectl get crd > "$OUTPUT_DIR/custom_resources.txt"
kubectl get crd -o json | jq '.items[] | {name: .metadata.name, group: .spec.group, version: .spec.versions}' > "$OUTPUT_DIR/crd_details.json"

echo "🚀 Coletando performance e saúde..."
kubectl get pods -A -o wide > "$OUTPUT_DIR/pods_status.txt"
kubectl get pods -A | grep -i "CrashLoopBackOff\|Error\|OOMKilled" > "$OUTPUT_DIR/pods_errors.txt"
kubectl get pods -A -o json | jq '.items[] | {namespace: .metadata.namespace, name: .metadata.name, restarts: [.status.containerStatuses[]?.restartCount] | add}' | grep -v "null" > "$OUTPUT_DIR/pod_restarts.json"
kubectl get pods -A -o json | jq '.items[] | select(.spec.containers[].resources.limits == null or .spec.containers[].resources.requests == null) | {namespace: .metadata.namespace, name: .metadata.name}' > "$OUTPUT_DIR/pods_no_resources.json"
kubectl get pods -A -o json | jq '.items[] | {namespace: .metadata.namespace, name: .metadata.name, containers: [.spec.containers[] | {name: .name, readiness: .readinessProbe, liveness: .livenessProbe}]}' > "$OUTPUT_DIR/pod_probes.json"

echo "💾 Coletando informações de armazenamento..."
kubectl get pv -o wide > "$OUTPUT_DIR/persistent_volumes.txt"
kubectl get pvc -A -o wide > "$OUTPUT_DIR/persistent_volume_claims.txt"
kubectl get storageclass > "$OUTPUT_DIR/storage_classes.txt"
kubectl get storageclass -o json | jq '.items[] | {name: .metadata.name, provisioner: .provisioner, parameters: .parameters}' > "$OUTPUT_DIR/storage_class_details.json"
kubectl get volumesnapshots -A > "$OUTPUT_DIR/volume_snapshots.txt" 2>/dev/null
kubectl get volumesnapshotclasses > "$OUTPUT_DIR/volume_snapshot_classes.txt" 2>/dev/null

echo "🌐 Coletando informações avançadas de rede..."
kubectl get pods -n kube-system -o wide | grep -i "calico\|flannel\|weave\|cilium\|canal" > "$OUTPUT_DIR/cni_pods.txt"
kubectl get pods -A -l app.kubernetes.io/name=ingress-nginx -o wide > "$OUTPUT_DIR/ingress_controllers.txt" 2>/dev/null
kubectl get ingressclass > "$OUTPUT_DIR/ingress_classes.txt" 2>/dev/null

echo "🔐 Coletando informações de certificados..."
kubectl get certificates -A > "$OUTPUT_DIR/certificates.txt" 2>/dev/null
kubectl get certificaterequests -A > "$OUTPUT_DIR/certificate_requests.txt" 2>/dev/null
kubectl get issuers,clusterissuers -A > "$OUTPUT_DIR/cert_issuers.txt" 2>/dev/null

echo "🗄️ Coletando informações do etcd..."
kubectl get pods -n kube-system -l component=etcd -o wide > "$OUTPUT_DIR/etcd_pods.txt" 2>/dev/null

echo "📦 Coletando informações do Helm..."
if command -v helm &> /dev/null; then
    helm list -A > "$OUTPUT_DIR/helm_releases.txt" 2>/dev/null
fi

echo "📋 Coletando políticas de governança..."
kubectl get clusterpolicies > "$OUTPUT_DIR/kyverno_policies.txt" 2>/dev/null
kubectl get constraints > "$OUTPUT_DIR/opa_constraints.txt" 2>/dev/null

# ============================================================
# Finalização
# ============================================================

echo "✅ Assessment concluído!"
echo "📂 Confira os arquivos gerados em: $OUTPUT_DIR"