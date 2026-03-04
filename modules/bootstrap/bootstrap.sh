#!/bin/bash
# =============================================================================
# EKS Bootstrap Script
# =============================================================================
# Dois tipos de passo:
#   🔒 CRÍTICO  — 
#   🔄 NORMAL   — 
#
# No final SEMPRE mostra relatório completo do que passou e do que falhou.
# =============================================================================

set -uo pipefail

# ── Variáveis (Terraform templatefile) ───────────────────────────────────────
CLUSTER_NAME="${cluster_name}"
REGION="${region}"
KUBECTL_VERSION="${kubectl_version}"
HELM_VERSION="${helm_version}"
ARGOCD_NAMESPACE="${argocd_namespace}"
ARGOCD_VERSION="${argocd_version}"
EXTERNAL_SECRETS_VERSION="${external_secrets_version}"

# ── Logging ──────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/eks-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# ── Tracking de resultados ───────────────────────────────────────────────────
declare -a STEP_NAMES=()
declare -a STEP_RESULTS=()
declare -a STEP_TYPES=()
ABORTED=false
ABORT_REASON=""

record() {
  STEP_NAMES+=("$1")
  STEP_RESULTS+=("$2")  # OK | FAIL | SKIP | ABORTED
  STEP_TYPES+=("$3")    # CRITICAL | NORMAL
}

# ── Retry com backoff ────────────────────────────────────────────────────────
retry() {
  local max_attempts=$1
  local delay=$2
  local description=$3
  shift 3

  for attempt in $(seq 1 "$max_attempts"); do
    log "  [$attempt/$max_attempts] $description"
    if "$@"; then
      return 0
    fi
    if [[ $attempt -lt $max_attempts ]]; then
      local wait=$((delay * attempt))
      log "  ⏳ Falhou. Retry em ${wait}s..."
      sleep "$wait"
    fi
  done
  return 1
}

# ── Cleanup: SEMPRE roda, mostra relatório, e termina a instância ────────────
cleanup() {
  echo ""
  log "══════════════════════════════════════════════════"
  log "  📋 RELATÓRIO DO BOOTSTRAP"
  log "══════════════════════════════════════════════════"

  local passed=0 failed=0 skipped=0 aborted=0

  for i in "$${!STEP_NAMES[@]}"; do
    local name="$${STEP_NAMES[$i]}"
    local result="$${STEP_RESULTS[$i]}"
    local type="$${STEP_TYPES[$i]}"

    case "$result" in
      OK)      icon="✅"; ((passed++))  ;;
      FAIL)    icon="❌"; ((failed++))  ;;
      SKIP)    icon="⏭️ "; ((skipped++)) ;;
      ABORTED) icon="🚫"; ((aborted++)) ;;
    esac

    local type_label=""
    [[ "$type" == "CRITICAL" ]] && type_label=" [CRÍTICO]"

    log "  $icon $name$type_label — $result"
  done

  local total=$((passed + failed + skipped + aborted))
  echo ""
  log "  Total: $total | ✅ $passed | ❌ $failed | ⏭️  $skipped | 🚫 $aborted"

  if [[ "$ABORTED" == "true" ]]; then
    log ""
    log "  🛑 BOOTSTRAP ABORTADO"
    log "  Motivo: $ABORT_REASON"
    log "  Os passos restantes não foram executados porque"
    log "  um passo CRÍTICO falhou."
  elif [[ $failed -gt 0 ]]; then
    log ""
    log "  ⚠️  BOOTSTRAP PARCIAL — $failed passo(s) falharam"
    log "  Corrija e rode terraform apply novamente."
  else
    log ""
    log "  ✅ BOOTSTRAP CONCLUÍDO COM SUCESSO"
  fi

  log ""
  log "  Instância será terminada em 30 segundos..."
  log "══════════════════════════════════════════════════"
  sleep 30
  shutdown -h now
}
trap cleanup EXIT

# ── Passo CRÍTICO: se falha, marca todos os restantes como ABORTED ───────────
run_critical() {
  local step_name=$1
  shift

  if [[ "$ABORTED" == "true" ]]; then
    record "$step_name" "ABORTED" "CRITICAL"
    return 1
  fi

  log "────────────────────────────────────────────────"
  log "🔒 [CRÍTICO] $step_name"
  log "────────────────────────────────────────────────"

  if "$@"; then
    record "$step_name" "OK" "CRITICAL"
    return 0
  else
    record "$step_name" "FAIL" "CRITICAL"
    ABORTED=true
    ABORT_REASON="$step_name falhou"
    log "  🛑 Passo CRÍTICO falhou — abortando passos restantes"
    return 1
  fi
}

# ── Passo NORMAL: se falha, registra e continua ──────────────────────────────
run_step() {
  local step_name=$1
  shift

  if [[ "$ABORTED" == "true" ]]; then
    record "$step_name" "ABORTED" "NORMAL"
    return 1
  fi

  log "────────────────────────────────────────────────"
  log "🔄 $step_name"
  log "────────────────────────────────────────────────"

  if "$@"; then
    record "$step_name" "OK" "NORMAL"
    return 0
  else
    record "$step_name" "FAIL" "NORMAL"
    log "  ⚠️ Falhou, mas continuando para o próximo passo..."
    return 0  # Retorna 0 para não abortar
  fi
}

log "══════════════════════════════════════════════════"
log "  EKS BOOTSTRAP — $CLUSTER_NAME"
log "  Region: $REGION"
log "══════════════════════════════════════════════════"

# =============================================================================
# 🔒 CRÍTICO: Dependências do sistema
# =============================================================================
install_system_deps() {
  dnf install -y unzip jq tar gzip --quiet 2>/dev/null || yum install -y unzip jq tar gzip --quiet
}
run_critical "Dependências do sistema" install_system_deps

# =============================================================================
# 🔒 CRÍTICO: kubectl
# =============================================================================
install_kubectl() {
  retry 3 5 "Download kubectl" \
    curl -sLo /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl"
  chmod +x /usr/local/bin/kubectl
  kubectl version --client 2>/dev/null
}
run_critical "kubectl v$KUBECTL_VERSION" install_kubectl

# =============================================================================
# 🔒 CRÍTICO: Helm
# =============================================================================
install_helm() {
  retry 3 5 "Download Helm" \
    curl -sL "https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz" -o /tmp/helm.tar.gz
  tar xzf /tmp/helm.tar.gz -C /tmp
  mv /tmp/linux-amd64/helm /usr/local/bin/
  rm -rf /tmp/linux-amd64 /tmp/helm.tar.gz
  helm version --short
}
run_critical "Helm v$HELM_VERSION" install_helm

# =============================================================================
# 🔒 CRÍTICO: Kubeconfig + aguardar EKS API
# =============================================================================
configure_kubeconfig() {
  retry 10 15 "aws eks update-kubeconfig" \
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

  log "  Aguardando nodes ficarem Ready (máx 5 min)..."
  local timeout=300
  local elapsed=0
  while [[ $elapsed -lt $timeout ]]; do
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || echo "0")
    if [[ "$READY_NODES" -gt 0 ]]; then
      log "  ✅ $READY_NODES node(s) Ready"
      kubectl get nodes -o wide
      return 0
    fi
    sleep 15
    elapsed=$((elapsed + 15))
    log "  Aguardando nodes... (${elapsed}s/${timeout}s)"
  done

  # Se não tem node Ready, é falha crítica
  log "  ❌ Nenhum node Ready após ${timeout}s"
  return 1
}
run_critical "Kubeconfig + Aguardar EKS" configure_kubeconfig

# =============================================================================
# 🔄 NORMAL: Namespaces
# =============================================================================
%{ if apply_namespaces && namespaces_yaml != "" ~}
apply_namespaces() {
  cat <<'NAMESPACES_EOF' | kubectl apply -f -
${namespaces_yaml}
NAMESPACES_EOF
}
run_step "Namespaces" apply_namespaces
%{ else ~}
record "Namespaces" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Metrics Server
# =============================================================================
%{ if install_metrics_server ~}
install_metrics_server() {
  retry 3 10 "Apply Metrics Server" \
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

  log "  Aguardando rollout (máx 3 min)..."
  kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
}
run_step "Metrics Server" install_metrics_server
%{ else ~}
record "Metrics Server" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Ingress NGINX
# =============================================================================
%{ if install_ingress_nginx && ingress_nginx_yaml != "" ~}
install_ingress_nginx() {
  cat <<'INGRESS_EOF' > /tmp/ingress-nginx.yaml
${ingress_nginx_yaml}
INGRESS_EOF

  retry 3 10 "Apply Ingress NGINX" \
    kubectl apply -f /tmp/ingress-nginx.yaml

  log "  Aguardando rollout (máx 5 min)..."
  kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s

%{ if ingress_nginx_acm_yaml != "" ~}
  log "  Aplicando Service ACM/NLB..."
  cat <<'INGRESS_ACM_EOF' | kubectl apply -f -
${ingress_nginx_acm_yaml}
INGRESS_ACM_EOF
%{ endif ~}
}
run_step "Ingress NGINX" install_ingress_nginx
%{ else ~}
record "Ingress NGINX" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: External Secrets
# =============================================================================
%{ if install_external_secrets ~}
install_external_secrets() {
  retry 3 10 "Apply ESO CRDs" \
    kubectl apply -f 'https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml' --server-side=true

  log "  Aguardando CRDs propagarem (30s)..."
  sleep 30

  retry 3 5 "Helm repo add" helm repo add external-secrets https://charts.external-secrets.io
  helm repo update

%{ if external_secrets_values != "" ~}
  cat <<'ESO_VALUES_EOF' > /tmp/external-secrets-values.yaml
${external_secrets_values}
ESO_VALUES_EOF

  retry 3 15 "Helm install external-secrets" \
    helm upgrade --install external-secrets external-secrets/external-secrets \
      --namespace kube-system \
      --version "$EXTERNAL_SECRETS_VERSION" \
      --values /tmp/external-secrets-values.yaml \
      --wait --timeout 5m0s
%{ else ~}
  retry 3 15 "Helm install external-secrets" \
    helm upgrade --install external-secrets external-secrets/external-secrets \
      --namespace kube-system \
      --version "$EXTERNAL_SECRETS_VERSION" \
      --wait --timeout 5m0s
%{ endif ~}
}
run_step "External Secrets Operator" install_external_secrets
%{ else ~}
record "External Secrets" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: ArgoCD
# =============================================================================
%{ if install_argocd ~}
install_argocd() {
  kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  retry 3 5 "Helm repo add argo" helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update

  retry 3 20 "Helm install argocd" \
    helm upgrade --install argocd argo/argo-cd \
      --namespace "$ARGOCD_NAMESPACE" \
      --version "$ARGOCD_VERSION" \
      --set server.service.type=ClusterIP \
      --set "server.extraArgs={--insecure}" \
      --set configs.params."server\.insecure"=true \
      --set dex.enabled=false \
      --set notifications.enabled=false \
      --wait --timeout 8m0s

  log "  Aguardando rollout (máx 3 min)..."
  kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=180s

  # Capturar senha
  local argocd_pass
  argocd_pass=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "INDISPONÍVEL")

  log "  ┌──────────────────────────────────────────┐"
  log "  │ 🔑 ArgoCD Password: $argocd_pass"
  log "  │ 📌 Salve! Visível no System Log da EC2  │"
  log "  └──────────────────────────────────────────┘"
}
run_step "ArgoCD" install_argocd
%{ else ~}
record "ArgoCD" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Comandos extras
# =============================================================================
%{ if extra_commands != "" ~}
run_extra() {
${extra_commands}
}
run_step "Comandos extras" run_extra
%{ endif ~}

# =============================================================================
# 🔄 Verificação final (sempre roda, mesmo com falhas)
# =============================================================================
if [[ "$ABORTED" != "true" ]]; then
  verify_cluster() {
    echo ""
    log "── Nodes ──"
    kubectl get nodes -o wide 2>/dev/null || true
    echo ""
    log "── Namespaces ──"
    kubectl get namespaces 2>/dev/null || true
    echo ""
    log "── Pods (all namespaces) ──"
    kubectl get pods --all-namespaces 2>/dev/null || true
    echo ""
    log "── Services ──"
    kubectl get svc -A 2>/dev/null || true
    echo ""
  }
  run_step "Verificação final" verify_cluster
fi

# O trap EXIT chama cleanup() → mostra RELATÓRIO COMPLETO → shutdown
exit 0
