#!/bin/bash

# Check the status of a specific sandbox environment

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

usage() {
    cat << EOF
Usage: $0 --name <env-name>

Check the status of a specific sandbox environment.

Options:
  --name <name>    Environment name to check
  --help           Display this help message

Example:
  $0 --name env1

EOF
    exit 1
}

# Parse arguments
ENV_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            ENV_NAME="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "${ENV_NAME}" ]]; then
    print_error "Environment name is required!"
    usage
fi

# Sanitize environment name
ENV_NAME=$(echo "${ENV_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

ENV_INFO_FILE=".env-${ENV_NAME}.json"

print_header "=========================================="
print_header "Environment Status: ${ENV_NAME}"
print_header "=========================================="
echo ""

# Check if environment info file exists
if [[ ! -f "${ENV_INFO_FILE}" ]]; then
    print_error "Environment ${ENV_NAME} not found!"
    print_error "No metadata file: ${ENV_INFO_FILE}"
    echo ""
    echo "Available environments:"
    ./scripts/list_envs.sh
    exit 1
fi

# Load environment details
if command -v jq &> /dev/null; then
    RESOURCE_GROUP=$(jq -r '.resourceGroup' "${ENV_INFO_FILE}")
    CLUSTER_NAME=$(jq -r '.aksCluster' "${ENV_INFO_FILE}")
    NAMESPACE=$(jq -r '.namespace' "${ENV_INFO_FILE}")
    REGISTRY_NAME=$(jq -r '.containerRegistry' "${ENV_INFO_FILE}")
    REGION=$(jq -r '.region' "${ENV_INFO_FILE}")
    KUBE_CONTEXT=$(jq -r '.kubeContext' "${ENV_INFO_FILE}")
    CREATED_AT=$(jq -r '.createdAt' "${ENV_INFO_FILE}")
else
    print_warning "jq not installed - install for detailed info"
    RESOURCE_GROUP="rg-sandbox-${ENV_NAME}"
    CLUSTER_NAME="aks-sandbox-${ENV_NAME}"
    NAMESPACE="ns-${ENV_NAME}"
    REGISTRY_NAME="acrsandbox${ENV_NAME//[-]/}"
    KUBE_CONTEXT="${ENV_NAME}"
fi

print_info "Environment Details:"
echo "  Name:            ${ENV_NAME}"
echo "  Resource Group:  ${RESOURCE_GROUP}"
echo "  AKS Cluster:     ${CLUSTER_NAME}"
echo "  Namespace:       ${NAMESPACE}"
echo "  Registry:        ${REGISTRY_NAME}"
echo "  Context:         ${KUBE_CONTEXT}"
if [[ -n "${REGION}" ]]; then
    echo "  Region:          ${REGION}"
fi
if [[ -n "${CREATED_AT}" ]]; then
    echo "  Created:         ${CREATED_AT}"
fi
echo ""

# Check Azure resource group
print_header "Checking Azure Resources..."
if az group show --name "${RESOURCE_GROUP}" &>/dev/null; then
    print_info "? Resource group exists"
    
    # Get resource group details
    RG_STATUS=$(az group show --name "${RESOURCE_GROUP}" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Unknown")
    echo "  Status: ${RG_STATUS}"
else
    print_error "? Resource group not found!"
    echo ""
    print_warning "Environment may have been deleted or creation failed"
    exit 1
fi

echo ""

# Check AKS cluster
print_header "Checking AKS Cluster..."
if az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" &>/dev/null; then
    print_info "? AKS cluster exists"
    
    # Get cluster details
    CLUSTER_STATUS=$(az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --query "powerState.code" -o tsv 2>/dev/null || echo "Unknown")
    NODE_COUNT=$(az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --query "agentPoolProfiles[0].count" -o tsv 2>/dev/null || echo "Unknown")
    K8S_VERSION=$(az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --query "kubernetesVersion" -o tsv 2>/dev/null || echo "Unknown")
    
    echo "  Power State:     ${CLUSTER_STATUS}"
    echo "  Node Count:      ${NODE_COUNT}"
    echo "  K8s Version:     ${K8S_VERSION}"
else
    print_error "? AKS cluster not found!"
fi

echo ""

# Check Container Registry
print_header "Checking Container Registry..."
if az acr show --name "${REGISTRY_NAME}" &>/dev/null 2>&1; then
    print_info "? Container registry exists"
    
    ACR_STATUS=$(az acr show --name "${REGISTRY_NAME}" --query "provisioningState" -o tsv 2>/dev/null || echo "Unknown")
    ACR_LOGIN=$(az acr show --name "${REGISTRY_NAME}" --query "loginServer" -o tsv 2>/dev/null || echo "Unknown")
    
    echo "  Status:          ${ACR_STATUS}"
    echo "  Login Server:    ${ACR_LOGIN}"
else
    print_error "? Container registry not found!"
fi

echo ""

# Check kubectl context
print_header "Checking Kubectl Context..."
if kubectl config get-contexts "${KUBE_CONTEXT}" &>/dev/null; then
    print_info "? Kubectl context exists"
    
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
    if [[ "${CURRENT_CONTEXT}" == "${KUBE_CONTEXT}" ]]; then
        echo "  Status:          Active (current context)"
    else
        echo "  Status:          Available (not current)"
    fi
else
    print_warning "? Kubectl context not found"
    echo "  Run: az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME} --context ${KUBE_CONTEXT}"
fi

echo ""

# Check namespace (if context is available)
print_header "Checking Kubernetes Namespace..."
if kubectl config get-contexts "${KUBE_CONTEXT}" &>/dev/null; then
    if kubectl get namespace "${NAMESPACE}" --context="${KUBE_CONTEXT}" &>/dev/null; then
        print_info "? Namespace exists"
        
        # Get pods in namespace
        POD_COUNT=$(kubectl get pods -n "${NAMESPACE}" --context="${KUBE_CONTEXT}" --no-headers 2>/dev/null | wc -l || echo "0")
        SERVICE_COUNT=$(kubectl get services -n "${NAMESPACE}" --context="${KUBE_CONTEXT}" --no-headers 2>/dev/null | wc -l || echo "0")
        DEPLOYMENT_COUNT=$(kubectl get deployments -n "${NAMESPACE}" --context="${KUBE_CONTEXT}" --no-headers 2>/dev/null | wc -l || echo "0")
        
        echo "  Pods:            ${POD_COUNT}"
        echo "  Services:        ${SERVICE_COUNT}"
        echo "  Deployments:     ${DEPLOYMENT_COUNT}"
    else
        print_error "? Namespace not found!"
    fi
else
    print_warning "Cannot check namespace (kubectl context not available)"
fi

echo ""
print_header "=========================================="
print_header "Quick Commands"
print_header "=========================================="
echo ""
echo "Switch to this environment:"
echo "  kubectl config use-context ${KUBE_CONTEXT}"
echo ""
echo "View resources:"
echo "  kubectl get all -n ${NAMESPACE}"
echo ""
echo "View pods:"
echo "  kubectl get pods -n ${NAMESPACE} --context=${KUBE_CONTEXT}"
echo ""
echo "Delete this environment:"
echo "  ./scripts/delete_env.sh --name ${ENV_NAME}"
echo ""
print_header "=========================================="
