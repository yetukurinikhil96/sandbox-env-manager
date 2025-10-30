#!/bin/bash

# Sandbox Environment Creation Script
# Creates isolated, clean environments on demand with no shared resources

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default configuration (can be overridden)
DEFAULT_REGION="eastus"
DEFAULT_CLUSTER_PREFIX="aks-sandbox"
DEFAULT_REGISTRY_PREFIX="acrsandbox"
DEFAULT_RG_PREFIX="rg-sandbox"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 --name <env-name> [OPTIONS]

Required:
  --name <name>              Unique environment name (e.g., env1, user-alice, dev-team1)

Optional:
  --region <region>          Azure region (default: ${DEFAULT_REGION})
  --cluster-prefix <prefix>  AKS cluster name prefix (default: ${DEFAULT_CLUSTER_PREFIX})
  --registry-prefix <prefix> Container registry prefix (default: ${DEFAULT_REGISTRY_PREFIX})
  --rg-prefix <prefix>       Resource group prefix (default: ${DEFAULT_RG_PREFIX})
  --node-count <count>       Number of cluster nodes (default: 2)
  --node-size <size>         VM size for nodes (default: Standard_D2s_v3)
  --subscription <id>        Azure subscription ID (uses current if not specified)
  --tags <tags>              Additional tags as key=value pairs (comma-separated)
  --dry-run                  Show what would be created without creating it
  --help                     Display this help message

Examples:
  # Create a simple environment
  $0 --name env1

  # Create environment with custom settings
  $0 --name env2 --region westus2 --node-count 3

  # Create user-specific sandbox
  $0 --name user-alice --tags "owner=alice,purpose=testing"

  # Dry run to see what would be created
  $0 --name env3 --dry-run

EOF
    exit 1
}

# Parse command line arguments
ENV_NAME=""
REGION="${DEFAULT_REGION}"
CLUSTER_PREFIX="${DEFAULT_CLUSTER_PREFIX}"
REGISTRY_PREFIX="${DEFAULT_REGISTRY_PREFIX}"
RG_PREFIX="${DEFAULT_RG_PREFIX}"
NODE_COUNT=2
NODE_SIZE="Standard_D2s_v3"
SUBSCRIPTION=""
CUSTOM_TAGS=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            ENV_NAME="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --cluster-prefix)
            CLUSTER_PREFIX="$2"
            shift 2
            ;;
        --registry-prefix)
            REGISTRY_PREFIX="$2"
            shift 2
            ;;
        --rg-prefix)
            RG_PREFIX="$2"
            shift 2
            ;;
        --node-count)
            NODE_COUNT="$2"
            shift 2
            ;;
        --node-size)
            NODE_SIZE="$2"
            shift 2
            ;;
        --subscription)
            SUBSCRIPTION="$2"
            shift 2
            ;;
        --tags)
            CUSTOM_TAGS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
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

# Validate required parameters
if [[ -z "${ENV_NAME}" ]]; then
    print_error "Environment name is required!"
    usage
fi

# Sanitize environment name (lowercase, alphanumeric, hyphens only)
ENV_NAME=$(echo "${ENV_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

# Generate unique resource names based on environment name
RESOURCE_GROUP="${RG_PREFIX}-${ENV_NAME}"
CLUSTER_NAME="${CLUSTER_PREFIX}-${ENV_NAME}"
NAMESPACE="ns-${ENV_NAME}"
REGISTRY_NAME="${REGISTRY_PREFIX}${ENV_NAME//[-]/}"  # Remove hyphens for ACR (not allowed)

# Ensure registry name meets Azure requirements (5-50 alphanumeric chars)
REGISTRY_NAME=$(echo "${REGISTRY_NAME}" | cut -c1-50)

# Build tags
TAGS="environment=${ENV_NAME},created=$(date +%Y-%m-%d),managed-by=sandbox-script"
if [[ -n "${CUSTOM_TAGS}" ]]; then
    TAGS="${TAGS},${CUSTOM_TAGS}"
fi

# Display configuration
print_info "=========================================="
print_info "Sandbox Environment Configuration"
print_info "=========================================="
print_info "Environment Name:    ${ENV_NAME}"
print_info "Resource Group:      ${RESOURCE_GROUP}"
print_info "AKS Cluster:         ${CLUSTER_NAME}"
print_info "Kubernetes Namespace: ${NAMESPACE}"
print_info "Container Registry:  ${REGISTRY_NAME}"
print_info "Region:              ${REGION}"
print_info "Node Count:          ${NODE_COUNT}"
print_info "Node Size:           ${NODE_SIZE}"
print_info "Tags:                ${TAGS}"
print_info "=========================================="

if [[ "${DRY_RUN}" == true ]]; then
    print_warning "DRY RUN MODE - No resources will be created"
    exit 0
fi

# Confirmation prompt
read -p "Create this environment? (yes/no): " CONFIRM
if [[ "${CONFIRM}" != "yes" ]]; then
    print_warning "Environment creation cancelled"
    exit 0
fi

# Set subscription if provided
if [[ -n "${SUBSCRIPTION}" ]]; then
    print_info "Setting Azure subscription to ${SUBSCRIPTION}"
    az account set --subscription "${SUBSCRIPTION}"
fi

# Check if resource group already exists
if az group show --name "${RESOURCE_GROUP}" &>/dev/null; then
    print_error "Resource group ${RESOURCE_GROUP} already exists!"
    print_error "This environment may already be created. Use a different name or delete the existing environment."
    exit 1
fi

# Create resource group
print_info "Creating resource group: ${RESOURCE_GROUP}"
az group create \
    --name "${RESOURCE_GROUP}" \
    --location "${REGION}" \
    --tags ${TAGS//,/ }

# Create container registry
print_info "Creating container registry: ${REGISTRY_NAME}"
az acr create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${REGISTRY_NAME}" \
    --sku Basic \
    --tags ${TAGS//,/ }

# Create AKS cluster
print_info "Creating AKS cluster: ${CLUSTER_NAME} (this may take several minutes)"
az aks create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}" \
    --node-count "${NODE_COUNT}" \
    --node-vm-size "${NODE_SIZE}" \
    --enable-managed-identity \
    --generate-ssh-keys \
    --attach-acr "${REGISTRY_NAME}" \
    --tags ${TAGS//,/ }

# Get AKS credentials
print_info "Getting AKS credentials"
az aks get-credentials \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${CLUSTER_NAME}" \
    --context "${ENV_NAME}" \
    --overwrite-existing

# Create Kubernetes namespace
print_info "Creating Kubernetes namespace: ${NAMESPACE}"
kubectl create namespace "${NAMESPACE}" --context="${ENV_NAME}"

# Label namespace for identification
kubectl label namespace "${NAMESPACE}" \
    environment="${ENV_NAME}" \
    managed-by=sandbox-script \
    --context="${ENV_NAME}"

# Create environment info file
ENV_INFO_FILE=".env-${ENV_NAME}.json"
print_info "Saving environment details to ${ENV_INFO_FILE}"
cat > "${ENV_INFO_FILE}" << EOF
{
  "environmentName": "${ENV_NAME}",
  "resourceGroup": "${RESOURCE_GROUP}",
  "aksCluster": "${CLUSTER_NAME}",
  "namespace": "${NAMESPACE}",
  "containerRegistry": "${REGISTRY_NAME}",
  "region": "${REGION}",
  "nodeCount": ${NODE_COUNT},
  "nodeSize": "${NODE_SIZE}",
  "createdAt": "$(date -Iseconds)",
  "kubeContext": "${ENV_NAME}",
  "tags": "${TAGS}"
}
EOF

# Display success message
print_info "=========================================="
print_info "? Environment ${ENV_NAME} created successfully!"
print_info "=========================================="
print_info "Resource Group:      ${RESOURCE_GROUP}"
print_info "AKS Cluster:         ${CLUSTER_NAME}"
print_info "Kubernetes Context:  ${ENV_NAME}"
print_info "Namespace:           ${NAMESPACE}"
print_info "Container Registry:  ${REGISTRY_NAME}"
print_info ""
print_info "Quick Start Commands:"
print_info "  # Switch to this environment"
print_info "  kubectl config use-context ${ENV_NAME}"
print_info ""
print_info "  # Deploy to this namespace"
print_info "  kubectl apply -f your-app.yaml -n ${NAMESPACE}"
print_info ""
print_info "  # View resources"
print_info "  kubectl get all -n ${NAMESPACE}"
print_info ""
print_info "  # Delete this environment"
print_info "  ./scripts/delete_env.sh --name ${ENV_NAME}"
print_info "=========================================="

# Save environment name to tracking file
mkdir -p .environments
echo "${ENV_NAME}" >> .environments/created_environments.txt

print_info "Environment details saved to: ${ENV_INFO_FILE}"
print_info "Done!"
