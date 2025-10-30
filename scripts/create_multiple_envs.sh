#!/bin/bash

# Create multiple sandbox environments in sequence
# Usage: ./scripts/create_multiple_envs.sh env1 env2 env3 env4 env5

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATE_SCRIPT="${SCRIPT_DIR}/create_env.sh"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $# -eq 0 ]]; then
    print_error "No environment names provided!"
    echo ""
    echo "Usage: $0 <env-name-1> <env-name-2> ... <env-name-n>"
    echo ""
    echo "Example:"
    echo "  $0 env1 env2 env3 env4 env5"
    exit 1
fi

print_info "Creating ${#} environments: $@"
echo ""

CREATED_COUNT=0
FAILED_COUNT=0

for ENV_NAME in "$@"; do
    print_info "=========================================="
    print_info "Creating environment: ${ENV_NAME}"
    print_info "=========================================="
    
    if "${CREATE_SCRIPT}" --name "${ENV_NAME}"; then
        print_info "? ${ENV_NAME} created successfully"
        ((CREATED_COUNT++))
    else
        print_error "? Failed to create ${ENV_NAME}"
        ((FAILED_COUNT++))
    fi
    
    echo ""
done

print_info "=========================================="
print_info "Summary"
print_info "=========================================="
print_info "Successfully created: ${CREATED_COUNT}"
if [[ ${FAILED_COUNT} -gt 0 ]]; then
    print_error "Failed: ${FAILED_COUNT}"
fi
print_info "=========================================="
