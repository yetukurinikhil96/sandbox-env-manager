#!/bin/bash

# Sandbox Environment Deletion Script
# Safely deletes isolated sandbox environments

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
  --name <name>              Environment name to delete (e.g., env1, user-alice)

Optional:
  --rg-prefix <prefix>       Resource group prefix (default: rg-sandbox)
  --force                    Skip confirmation prompt
  --keep-context             Keep kubectl context (default: delete it)
  --dry-run                  Show what would be deleted without deleting it
  --help                     Display this help message

Examples:
  # Delete an environment (with confirmation)
  $0 --name env1

  # Force delete without confirmation
  $0 --name env2 --force

  # Dry run to see what would be deleted
  $0 --name env3 --dry-run

  # Delete but keep kubectl context
  $0 --name env4 --keep-context

EOF
    exit 1
}

# Parse command line arguments
ENV_NAME=""
RG_PREFIX="rg-sandbox"
FORCE=false
KEEP_CONTEXT=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            ENV_NAME="$2"
            shift 2
            ;;
        --rg-prefix)
            RG_PREFIX="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --keep-context)
            KEEP_CONTEXT=true
            shift
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

# Sanitize environment name
ENV_NAME=$(echo "${ENV_NAME}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

# Generate resource names
RESOURCE_GROUP="${RG_PREFIX}-${ENV_NAME}"
ENV_INFO_FILE=".env-${ENV_NAME}.json"

# Check if environment info file exists
if [[ -f "${ENV_INFO_FILE}" ]]; then
    print_info "Found environment info file: ${ENV_INFO_FILE}"
    
    # Load details from file
    if command -v jq &> /dev/null; then
        CLUSTER_NAME=$(jq -r '.aksCluster' "${ENV_INFO_FILE}")
        NAMESPACE=$(jq -r '.namespace' "${ENV_INFO_FILE}")
        REGISTRY_NAME=$(jq -r '.containerRegistry' "${ENV_INFO_FILE}")
        KUBE_CONTEXT=$(jq -r '.kubeContext' "${ENV_INFO_FILE}")
    else
        print_warning "jq not installed, using default naming convention"
        CLUSTER_NAME="aks-sandbox-${ENV_NAME}"
        NAMESPACE="ns-${ENV_NAME}"
        REGISTRY_NAME="acrsandbox${ENV_NAME//[-]/}"
        KUBE_CONTEXT="${ENV_NAME}"
    fi
else
    print_warning "Environment info file not found, using default naming convention"
    CLUSTER_NAME="aks-sandbox-${ENV_NAME}"
    NAMESPACE="ns-${ENV_NAME}"
    REGISTRY_NAME="acrsandbox${ENV_NAME//[-]/}"
    KUBE_CONTEXT="${ENV_NAME}"
fi

# Check if resource group exists
if ! az group show --name "${RESOURCE_GROUP}" &>/dev/null; then
    print_error "Resource group ${RESOURCE_GROUP} not found!"
    print_error "Environment ${ENV_NAME} may not exist or was already deleted."
    exit 1
fi

# Display what will be deleted
print_warning "=========================================="
print_warning "DELETION WARNING"
print_warning "=========================================="
print_warning "The following resources will be PERMANENTLY DELETED:"
print_warning ""
print_warning "Environment Name:    ${ENV_NAME}"
print_warning "Resource Group:      ${RESOURCE_GROUP}"
print_warning "AKS Cluster:         ${CLUSTER_NAME}"
print_warning "Container Registry:  ${REGISTRY_NAME}"
print_warning "Kubernetes Context:  ${KUBE_CONTEXT}"
print_warning "Namespace:           ${NAMESPACE}"
print_warning "=========================================="
print_warning "This action CANNOT be undone!"
print_warning "=========================================="

if [[ "${DRY_RUN}" == true ]]; then
    print_info "DRY RUN MODE - No resources will be deleted"
    exit 0
fi

# Confirmation prompt (unless --force is used)
if [[ "${FORCE}" != true ]]; then
    read -p "Type 'DELETE' to confirm deletion: " CONFIRM
    if [[ "${CONFIRM}" != "DELETE" ]]; then
        print_info "Deletion cancelled"
        exit 0
    fi
fi

# Delete resource group (this deletes all resources within it)
print_info "Deleting resource group: ${RESOURCE_GROUP}"
print_info "This may take several minutes..."
az group delete \
    --name "${RESOURCE_GROUP}" \
    --yes \
    --no-wait

print_info "Resource group deletion initiated (running in background)"

# Delete kubectl context unless --keep-context is specified
if [[ "${KEEP_CONTEXT}" != true ]]; then
    print_info "Deleting kubectl context: ${KUBE_CONTEXT}"
    kubectl config delete-context "${KUBE_CONTEXT}" 2>/dev/null || print_warning "Context not found or already deleted"
fi

# Delete environment info file
if [[ -f "${ENV_INFO_FILE}" ]]; then
    print_info "Deleting environment info file: ${ENV_INFO_FILE}"
    rm -f "${ENV_INFO_FILE}"
fi

# Remove from tracking file
if [[ -f ".environments/created_environments.txt" ]]; then
    sed -i.bak "/^${ENV_NAME}$/d" .environments/created_environments.txt
    rm -f .environments/created_environments.txt.bak
fi

# Display success message
print_info "=========================================="
print_info "? Environment ${ENV_NAME} deletion initiated!"
print_info "=========================================="
print_info ""
print_info "Note: Azure resource deletion is running in the background."
print_info "To check deletion status:"
print_info "  az group show --name ${RESOURCE_GROUP}"
print_info ""
print_info "The command will fail once deletion is complete."
print_info "=========================================="

print_info "Done!"
