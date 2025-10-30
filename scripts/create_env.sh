#!/usr/bin/env bash

set -e

# Usage function
usage() {
    cat << EOF
Usage: $0 --name <envName> --owner <ownerName> [--namespace <k8sNamespace>] [--help]

Required arguments:
  --name        Environment name
  --owner       Owner name

Optional arguments:
  --namespace   Kubernetes namespace (default: <envName>-ns)
  --help        Show this help message

Example:
  $0 --name demo1 --owner john.doe
  $0 --name demo1 --owner john.doe --namespace custom-namespace
EOF
}

# Initialize variables
ENV_NAME=""
OWNER_NAME=""
NAMESPACE=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            ENV_NAME="$2"
            shift 2
            ;;
        --owner)
            OWNER_NAME="$2"
            shift 2
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$ENV_NAME" ]]; then
    echo "Error: --name is required"
    usage
    exit 1
fi

if [[ -z "$OWNER_NAME" ]]; then
    echo "Error: --owner is required"
    usage
    exit 1
fi

# Set default namespace if not provided
if [[ -z "$NAMESPACE" ]]; then
    NAMESPACE="${ENV_NAME}-ns"
fi

# Echo provisioning actions
echo "Creating namespace ${NAMESPACE}"
echo "Deploying planner / monitor / optimizer services into ${NAMESPACE}"
echo "Exposing endpoint http://${ENV_NAME}.internal"

# Create state directory if it doesn't exist
mkdir -p ./state

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create JSON state file
STATE_FILE="./state/${ENV_NAME}.json"
cat > "$STATE_FILE" << EOF
{
  "name": "${ENV_NAME}",
  "owner": "${OWNER_NAME}",
  "namespace": "${NAMESPACE}",
  "status": "running",
  "created_at": "${TIMESTAMP}",
  "endpoint": "http://${ENV_NAME}.internal"
}
EOF

echo "Environment state saved to ${STATE_FILE}"
