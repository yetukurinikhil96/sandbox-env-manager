# Quick Reference Guide

## Common Commands

### Create Single Environment
```bash
chmod +x scripts/*.sh
./scripts/create_env.sh --name env1
```

### Create 5 Environments (env1-env5)
```bash
# Method 1: Using helper script
./scripts/create_multiple_envs.sh env1 env2 env3 env4 env5

# Method 2: Loop
for i in {1..5}; do ./scripts/create_env.sh --name env$i; done
```

### List Environments
```bash
./scripts/list_envs.sh
```

### Switch Context
```bash
kubectl config use-context env1
kubectl get all -n ns-env1
```

### Delete Environment
```bash
# With confirmation
./scripts/delete_env.sh --name env1

# Force delete
./scripts/delete_env.sh --name env1 --force
```

### Delete Multiple Environments
```bash
for i in {1..5}; do ./scripts/delete_env.sh --name env$i --force; done
```

## Advanced Examples

### Custom Configuration
```bash
./scripts/create_env.sh \
  --name prod-test \
  --region westus2 \
  --node-count 3 \
  --node-size Standard_D4s_v3 \
  --tags "team=devops,project=api"
```

### Per-User Sandboxes
```bash
./scripts/create_env.sh --name user-alice --tags "owner=alice"
./scripts/create_env.sh --name user-bob --tags "owner=bob"
```

### Deploy Application
```bash
kubectl config use-context env1
kubectl apply -f deployment.yaml -n ns-env1
kubectl get pods -n ns-env1
```

## Troubleshooting

### View Environment Details
```bash
cat .env-env1.json
```

### List All Resource Groups
```bash
az group list --query "[?starts_with(name, 'rg-sandbox-')]" -o table
```

### Check Cluster Status
```bash
az aks show --resource-group rg-sandbox-env1 --name aks-sandbox-env1
```

### View All Contexts
```bash
kubectl config get-contexts
```
