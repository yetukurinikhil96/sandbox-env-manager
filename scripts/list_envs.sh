#!/bin/bash

# List all created sandbox environments

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_header "=========================================="
print_header "Sandbox Environments"
print_header "=========================================="
echo ""

# Check for environment files
ENV_FILES=(.env-*.json)

if [[ ! -e "${ENV_FILES[0]}" ]]; then
    print_info "No environments found."
    echo ""
    echo "Create one with:"
    echo "  ./scripts/create_env.sh --name env1"
    exit 0
fi

# Display each environment
for file in .env-*.json; do
    if [[ -f "$file" ]]; then
        if command -v jq &> /dev/null; then
            ENV_NAME=$(jq -r '.environmentName' "$file")
            RESOURCE_GROUP=$(jq -r '.resourceGroup' "$file")
            CLUSTER=$(jq -r '.aksCluster' "$file")
            NAMESPACE=$(jq -r '.namespace' "$file")
            REGISTRY=$(jq -r '.containerRegistry' "$file")
            CREATED=$(jq -r '.createdAt' "$file")
            REGION=$(jq -r '.region' "$file")
            
            echo -e "${GREEN}?${NC} ${ENV_NAME}"
            echo "    Resource Group:  ${RESOURCE_GROUP}"
            echo "    Cluster:         ${CLUSTER}"
            echo "    Namespace:       ${NAMESPACE}"
            echo "    Registry:        ${REGISTRY}"
            echo "    Region:          ${REGION}"
            echo "    Created:         ${CREATED}"
            echo ""
        else
            echo "  $file (install jq for detailed info)"
        fi
    fi
done

echo "=========================================="
echo "Commands:"
echo "  Switch context:    kubectl config use-context <env-name>"
echo "  Delete environment: ./scripts/delete_env.sh --name <env-name>"
echo "=========================================="
