# Sandbox Environment Manager

A toolkit for creating isolated, on-demand sandbox environments in Azure with AKS and ACR.

## Overview

This project provides scripts to create, manage, and delete isolated sandbox environments. Each environment is completely independent with its own:
- Azure Resource Group
- AKS (Azure Kubernetes Service) Cluster
- Azure Container Registry (ACR)
- Kubernetes Namespace
- Kubectl Context

Multiple environments can coexist without conflicts, making it ideal for:
- Development and testing
- Per-user sandboxes
- Team-based environments
- Temporary demo environments
- CI/CD testing

## ?? NEW: Web API & UI

This project now includes a REST API and web UI for managing environments!

**Quick Start API:**
```bash
cd api
npm install
npm start
```

**Access Web UI:**
Open `ui/index.html` in your browser or visit `http://localhost:3000` after starting the API.

**API Endpoints:**
- `GET /api/envs` - List all environments
- `GET /api/envs/:name` - Get environment details
- `POST /api/envs` - Create new environment
- `DELETE /api/envs/:name` - Delete environment
- `GET /api/health` - Health check

?? See [API Documentation](./api/README.md) for full details.

## Prerequisites

Before using these scripts, ensure you have:

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **kubectl** - [Install kubectl](https://kubernetes.io/docs/tasks/tools/)
3. **Bash** - Linux/macOS native, or Git Bash/WSL on Windows
4. **jq** (optional) - For enhanced environment listing: `apt-get install jq` or `brew install jq`
5. **Node.js** (for API) - [Install Node.js](https://nodejs.org/) v16 or higher

### Azure Login

```bash
az login
az account set --subscription <your-subscription-id>
```

## Quick Start

### Create a Single Environment

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Create your first environment
./scripts/create_env.sh --name env1
```

The script will:
1. Create a resource group named `rg-sandbox-env1`
2. Create an AKS cluster named `aks-sandbox-env1`
3. Create a container registry named `acrsandboxenv1`
4. Create a Kubernetes namespace named `ns-env1`
5. Configure kubectl context as `env1`
6. Save environment details to `.env-env1.json`

### Create Multiple Environments

Create 5 isolated environments (env1 through env5):

```bash
# Option 1: Using the multi-environment script
./scripts/create_multiple_envs.sh env1 env2 env3 env4 env5

# Option 2: Create them individually
./scripts/create_env.sh --name env1
./scripts/create_env.sh --name env2
./scripts/create_env.sh --name env3
./scripts/create_env.sh --name env4
./scripts/create_env.sh --name env5
```

Each environment is completely isolated and can coexist with others.

### List All Environments

```bash
./scripts/list_envs.sh
```

Example output:
```
==========================================
Sandbox Environments
==========================================

? env1
    Resource Group:  rg-sandbox-env1
    Cluster:         aks-sandbox-env1
    Namespace:       ns-env1
    Registry:        acrsandboxenv1
    Region:          eastus
    Created:         2024-01-15T10:30:00Z

? env2
    Resource Group:  rg-sandbox-env2
    Cluster:         aks-sandbox-env2
    Namespace:       ns-env2
    Registry:        acrsandboxenv2
    Region:          eastus
    Created:         2024-01-15T10:45:00Z
```

### Switch Between Environments

```bash
# Switch to env1
kubectl config use-context env1
kubectl get all -n ns-env1

# Switch to env2
kubectl config use-context env2
kubectl get all -n ns-env2
```

### Delete an Environment

```bash
# Delete with confirmation
./scripts/delete_env.sh --name env1

# Force delete without confirmation
./scripts/delete_env.sh --name env2 --force

# Dry run to see what would be deleted
./scripts/delete_env.sh --name env3 --dry-run
```

## Advanced Usage

### Custom Configuration

```bash
# Create environment with custom settings
./scripts/create_env.sh \
  --name production-test \
  --region westus2 \
  --node-count 3 \
  --node-size Standard_D4s_v3 \
  --tags "team=devops,project=api-test"

# Create user-specific sandbox
./scripts/create_env.sh \
  --name user-alice \
  --tags "owner=alice,purpose=development"

# Dry run to preview configuration
./scripts/create_env.sh --name env-test --dry-run
```

### Available Options

#### create_env.sh

```bash
Required:
  --name <name>              Unique environment name

Optional:
  --region <region>          Azure region (default: eastus)
  --cluster-prefix <prefix>  AKS cluster name prefix (default: aks-sandbox)
  --registry-prefix <prefix> Container registry prefix (default: acrsandbox)
  --rg-prefix <prefix>       Resource group prefix (default: rg-sandbox)
  --node-count <count>       Number of cluster nodes (default: 2)
  --node-size <size>         VM size for nodes (default: Standard_D2s_v3)
  --subscription <id>        Azure subscription ID
  --tags <tags>              Additional tags (comma-separated key=value pairs)
  --dry-run                  Preview without creating
  --help                     Display help
```

#### delete_env.sh

```bash
Required:
  --name <name>              Environment name to delete

Optional:
  --rg-prefix <prefix>       Resource group prefix (default: rg-sandbox)
  --force                    Skip confirmation prompt
  --keep-context             Keep kubectl context
  --dry-run                  Preview without deleting
  --help                     Display help
```

## Usage Examples

### Example 1: Create 5 Test Environments

```bash
# Create environments env1 through env5
for i in {1..5}; do
  ./scripts/create_env.sh --name env$i
done

# Or use the helper script
./scripts/create_multiple_envs.sh env1 env2 env3 env4 env5
```

### Example 2: Per-User Sandboxes

```bash
# Create sandboxes for team members
./scripts/create_env.sh --name user-alice --tags "owner=alice,team=frontend"
./scripts/create_env.sh --name user-bob --tags "owner=bob,team=backend"
./scripts/create_env.sh --name user-carol --tags "owner=carol,team=devops"
```

### Example 3: Deploy Application to Environment

```bash
# Switch to env1
kubectl config use-context env1

# Deploy your application
kubectl apply -f deployment.yaml -n ns-env1

# Check deployment
kubectl get pods -n ns-env1
kubectl get services -n ns-env1

# View logs
kubectl logs -f <pod-name> -n ns-env1
```

### Example 4: Clean Up Multiple Environments

```bash
# Delete environments env1 through env5
for i in {1..5}; do
  ./scripts/delete_env.sh --name env$i --force
done
```

## File Structure

```
Sandbox-env-manager/
??? api/                        # New API directory
?   ??? README.md              # API documentation
?   ??? package.json            # NPM package file
?   ??? server.js              # API server code
??? scripts/
?   ??? create_env.sh           # Main environment creation script
?   ??? delete_env.sh           # Environment deletion script
?   ??? list_envs.sh            # List all environments
?   ??? create_multiple_envs.sh # Batch creation helper
??? .environments/               # Tracking directory (auto-created)
?   ??? created_environments.txt
??? .env-*.json                 # Environment metadata files
??? .gitignore                  # Git ignore patterns
??? README.md                   # This file
```

## Environment Isolation

Each environment is completely isolated:

1. **Separate Resource Groups**: All Azure resources are grouped per environment
2. **Unique Naming**: Each resource has a unique name based on the environment name
3. **Isolated Namespaces**: Kubernetes namespaces prevent resource conflicts
4. **Dedicated Contexts**: Each environment has its own kubectl context
5. **No Shared Resources**: No resources are reused between environments

### Naming Convention

For an environment named `env1`:
- Resource Group: `rg-sandbox-env1`
- AKS Cluster: `aks-sandbox-env1`
- Container Registry: `acrsandboxenv1`
- Namespace: `ns-env1`
- Kubectl Context: `env1`

## Future Enhancements

The current structure supports future additions:

- **Per-User Access Control**: RBAC can be added per environment
- **Cost Tracking**: Tags enable cost allocation per environment
- **Auto-Cleanup**: Scheduled deletion based on age or inactivity
- **Resource Quotas**: Limit resources per environment
- **Monitoring**: Add Azure Monitor or Prometheus per environment

## Troubleshooting

### Environment Already Exists

```bash
# Check if resource group exists
az group show --name rg-sandbox-env1

# Use a different name or delete the existing environment
./scripts/delete_env.sh --name env1
```

### Kubectl Context Conflicts

```bash
# List all contexts
kubectl config get-contexts

# Delete a specific context
kubectl config delete-context env1
```

### View Environment Details

```bash
# Check environment file
cat .env-env1.json

# Or with jq for formatted output
jq . .env-env1.json
```

### Check Azure Resources

```bash
# List all sandbox resource groups
az group list --query "[?starts_with(name, 'rg-sandbox-')]" -o table

# View resources in a specific group
az resource list --resource-group rg-sandbox-env1 -o table
```

## Cost Management

Each environment incurs Azure costs. Remember to:

1. **Delete unused environments** using `delete_env.sh`
2. **Use smaller node sizes** for development: `--node-size Standard_B2s`
3. **Reduce node count** for testing: `--node-count 1`
4. **Monitor costs** using Azure Cost Management with environment tags

## Security Best Practices

1. **Limit Access**: Use Azure RBAC to control who can create environments
2. **Tag Resources**: Always tag environments with owner and purpose
3. **Regular Cleanup**: Delete environments when no longer needed
4. **Use Private Registries**: ACR is private by default
5. **Network Policies**: Implement Kubernetes network policies per namespace

## Contributing

To add features or improvements:

1. Test changes with `--dry-run` flag first
2. Ensure naming conventions prevent conflicts
3. Update this README with new features
4. Add appropriate error handling

## License

[Add your license here]

## Support

For issues or questions:
- Check the troubleshooting section
- Review Azure CLI documentation
- Check kubectl and AKS documentation
