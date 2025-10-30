# Refactoring Summary

## What Was Changed

### ? Complete Refactoring Accomplished

The environment creation scripts have been completely refactored to support isolated, on-demand sandbox environments with zero shared resources.

## Key Improvements

### 1. **Zero Hardcoded Values**
All previously hardcoded values have been converted to parameters:
- Environment name
- Resource group prefix
- Cluster name prefix
- Registry name prefix
- Region
- Node count and size
- Azure subscription
- Custom tags

### 2. **Complete Isolation**
Each environment gets:
- Unique resource group
- Unique AKS cluster
- Unique container registry
- Unique Kubernetes namespace
- Unique kubectl context
- Unique identifier in all resource names

### 3. **No Resource Reuse**
Every `create_env.sh` run creates brand new resources from scratch. No sharing whatsoever.

### 4. **Multiple Environment Support**
Environments can coexist without conflicts:
- env1, env2, env3, env4, env5 can all run simultaneously
- Different users can have their own sandboxes (user-alice, user-bob, etc.)
- Naming convention ensures no collisions

### 5. **Future-Ready Structure**
The design supports future enhancements:
- Per-user RBAC (resources already tagged with owner)
- Cost allocation (comprehensive tagging system)
- Automated cleanup (metadata files track all environments)
- Resource quotas per environment

## Files Created

### Scripts (in `scripts/` directory)

1. **`create_env.sh`** - Main environment creation script
   - Fully parameterized
   - Dry-run support
   - Confirmation prompts
   - Generates metadata files
   - Creates unique kubectl contexts

2. **`delete_env.sh`** - Environment deletion script
   - Safe deletion with confirmation
   - Cleans up all resources
   - Removes kubectl contexts
   - Deletes metadata files

3. **`list_envs.sh`** - Lists all created environments
   - Shows environment details
   - Reads from metadata files
   - Pretty formatted output

4. **`create_multiple_envs.sh`** - Batch creation helper
   - Creates multiple environments sequentially
   - Error handling and reporting
   - Success/failure summary

### Documentation

1. **`README.md`** - Comprehensive documentation
   - Quick start guide
   - Advanced usage examples
   - Troubleshooting section
   - Architecture explanation

2. **`QUICKSTART.md`** - Command reference
   - Common commands
   - Quick copy-paste examples
   - Troubleshooting shortcuts

3. **`.gitignore`** - Git ignore patterns
   - Excludes environment metadata
   - Ignores temporary files
   - Protects sensitive data

## Usage Examples

### Create 1 Environment

```bash
# Make scripts executable (Linux/Mac/Git Bash)
chmod +x scripts/*.sh

# Create single environment
./scripts/create_env.sh --name env1
```

**What this creates:**
- Resource Group: `rg-sandbox-env1`
- AKS Cluster: `aks-sandbox-env1`
- Container Registry: `acrsandboxenv1`
- Namespace: `ns-env1`
- Kubectl Context: `env1`
- Metadata: `.env-env1.json`

### Create 5 Environments (env1-env5)

**Method 1: Using helper script**
```bash
./scripts/create_multiple_envs.sh env1 env2 env3 env4 env5
```

**Method 2: Individual commands**
```bash
./scripts/create_env.sh --name env1
./scripts/create_env.sh --name env2
./scripts/create_env.sh --name env3
./scripts/create_env.sh --name env4
./scripts/create_env.sh --name env5
```

**Method 3: Loop (Bash)**
```bash
for i in {1..5}; do
  ./scripts/create_env.sh --name env$i
done
```

**Result:** 5 completely isolated environments, each with:
- Separate Azure resource groups
- Independent AKS clusters
- Private container registries
- Isolated Kubernetes namespaces
- Unique kubectl contexts

### Working with Multiple Environments

```bash
# List all environments
./scripts/list_envs.sh

# Switch between environments
kubectl config use-context env1
kubectl get all -n ns-env1

kubectl config use-context env2
kubectl get all -n ns-env2

kubectl config use-context env3
kubectl get all -n ns-env3

# Deploy to specific environment
kubectl config use-context env1
kubectl apply -f app.yaml -n ns-env1

# View environment details
cat .env-env1.json
cat .env-env2.json
```

### Cleanup

**Delete single environment:**
```bash
./scripts/delete_env.sh --name env1
```

**Delete all 5 environments:**
```bash
for i in {1..5}; do
  ./scripts/delete_env.sh --name env$i --force
done
```

**Delete specific environments:**
```bash
./scripts/delete_env.sh --name env2 --force
./scripts/delete_env.sh --name env4 --force
```

## Advanced Features

### Custom Configuration

```bash
# Larger environment with custom region
./scripts/create_env.sh \
  --name production-test \
  --region westus2 \
  --node-count 3 \
  --node-size Standard_D4s_v3 \
  --tags "team=devops,project=api,env=prod-test"

# Minimal environment for testing
./scripts/create_env.sh \
  --name dev-test \
  --node-count 1 \
  --node-size Standard_B2s \
  --tags "purpose=development"
```

### Per-User Sandboxes

```bash
# Create sandboxes for team members
./scripts/create_env.sh --name user-alice --tags "owner=alice,team=frontend"
./scripts/create_env.sh --name user-bob --tags "owner=bob,team=backend"
./scripts/create_env.sh --name user-carol --tags "owner=carol,team=devops"

# Each user gets their own isolated environment
kubectl config use-context user-alice
kubectl config use-context user-bob
kubectl config use-context user-carol
```

### Dry Run (Preview)

```bash
# See what would be created without actually creating it
./scripts/create_env.sh --name test-preview --dry-run

# See what would be deleted without deleting it
./scripts/delete_env.sh --name env1 --dry-run
```

## Architecture Details

### Naming Convention

For environment name: `<env-name>`

| Resource | Pattern | Example (env1) |
|----------|---------|----------------|
| Resource Group | `rg-sandbox-<env-name>` | `rg-sandbox-env1` |
| AKS Cluster | `aks-sandbox-<env-name>` | `aks-sandbox-env1` |
| Container Registry | `acrsandbox<env-name>` | `acrsandboxenv1` |
| Namespace | `ns-<env-name>` | `ns-env1` |
| Kubectl Context | `<env-name>` | `env1` |
| Metadata File | `.env-<env-name>.json` | `.env-env1.json` |

### Isolation Mechanisms

1. **Azure Level**: Separate resource groups prevent any resource sharing
2. **Kubernetes Level**: Unique namespaces prevent pod/service conflicts
3. **Client Level**: Separate kubectl contexts prevent accidental cross-environment operations
4. **Registry Level**: Each environment has its own private container registry

### Metadata Tracking

Each environment creates a JSON metadata file:

```json
{
  "environmentName": "env1",
  "resourceGroup": "rg-sandbox-env1",
  "aksCluster": "aks-sandbox-env1",
  "namespace": "ns-env1",
  "containerRegistry": "acrsandboxenv1",
  "region": "eastus",
  "nodeCount": 2,
  "nodeSize": "Standard_D2s_v3",
  "createdAt": "2024-01-15T10:30:00Z",
  "kubeContext": "env1",
  "tags": "environment=env1,created=2024-01-15,managed-by=sandbox-script"
}
```

This enables:
- Easy environment listing
- Clean deletion
- Audit trails
- Cost tracking
- Access control (future)

## Security & Best Practices

### Current Implementation

? All resources tagged with environment name  
? Unique naming prevents conflicts  
? Private container registries by default  
? Isolated namespaces  
? AKS managed identity enabled  

### Future Enhancements (Ready for Implementation)

The structure supports:
- **RBAC**: Tags enable per-environment access control
- **Network Policies**: Namespace isolation ready for network policies
- **Resource Quotas**: Can add quotas per namespace
- **Cost Alerts**: Tags enable cost tracking per environment/owner
- **Auto-Cleanup**: Metadata enables age-based deletion

## Troubleshooting

### Common Issues

**Environment already exists:**
```bash
# Delete existing environment first
./scripts/delete_env.sh --name env1 --force

# Or use a different name
./scripts/create_env.sh --name env1-new
```

**Azure CLI not authenticated:**
```bash
az login
az account set --subscription <your-subscription-id>
```

**kubectl context conflicts:**
```bash
# List all contexts
kubectl config get-contexts

# Delete specific context
kubectl config delete-context env1
```

**Check environment status:**
```bash
# View metadata
cat .env-env1.json

# Check Azure resources
az group show --name rg-sandbox-env1
az aks show --resource-group rg-sandbox-env1 --name aks-sandbox-env1
```

## Cost Management

Each environment incurs Azure costs. To minimize:

1. **Delete unused environments immediately**
   ```bash
   ./scripts/delete_env.sh --name env1 --force
   ```

2. **Use smaller node sizes for development**
   ```bash
   ./scripts/create_env.sh --name dev --node-size Standard_B2s
   ```

3. **Reduce node count**
   ```bash
   ./scripts/create_env.sh --name test --node-count 1
   ```

4. **Monitor costs using tags**
   - All resources tagged with environment name
   - Use Azure Cost Management to track per-environment costs

## Next Steps

### Recommended Actions

1. **Test the scripts:**
   ```bash
   ./scripts/create_env.sh --name test1 --dry-run
   ./scripts/create_env.sh --name test1
   ./scripts/list_envs.sh
   ./scripts/delete_env.sh --name test1
   ```

2. **Create your environments:**
   ```bash
   ./scripts/create_multiple_envs.sh env1 env2 env3 env4 env5
   ```

3. **Deploy applications:**
   ```bash
   kubectl config use-context env1
   kubectl apply -f your-app.yaml -n ns-env1
   ```

### Future Enhancements to Consider

1. **Access Control**: Implement RBAC per environment
2. **Monitoring**: Add Azure Monitor or Prometheus
3. **Auto-Cleanup**: Delete environments after X days
4. **CI/CD Integration**: Create environments in pipelines
5. **Cost Alerts**: Set budget alerts per environment
6. **Resource Quotas**: Limit resources per namespace

## Summary

? **Zero hardcoded values** - Everything is parameterized  
? **Complete isolation** - No shared resources between environments  
? **Multiple environments** - env1-env5 (or more) can coexist  
? **Clean architecture** - Ready for per-user access control  
? **Easy management** - Simple create, list, delete operations  
? **Production-ready** - Error handling, validation, dry-run support  

The refactored solution provides a robust foundation for managing isolated sandbox environments at scale.
