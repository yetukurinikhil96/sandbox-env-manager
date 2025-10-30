# ?? Getting Started Guide

Welcome to the Sandbox Environment Manager! This guide will get you up and running in minutes.

## What You'll Build

By following this guide, you'll:
1. ? Set up the REST API
2. ? Create your first sandbox environment
3. ? View it in the Web UI
4. ? Integrate it with your frontend

**Time required:** 15-20 minutes

## Prerequisites Checklist

Before starting, make sure you have:

- [ ] **Azure CLI** installed - [Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [ ] **kubectl** installed - [Download](https://kubernetes.io/docs/tasks/tools/)
- [ ] **Node.js** v16+ installed - [Download](https://nodejs.org/)
- [ ] **Bash** shell (Linux/macOS/Git Bash/WSL)
- [ ] **Azure account** with active subscription
- [ ] **jq** (optional but recommended) - `brew install jq` or `apt-get install jq`

### Quick Test

Run this command to verify:
```bash
chmod +x test.sh
./test.sh
```

## Step-by-Step Setup

### Step 1: Azure Authentication (2 minutes)

```bash
# Login to Azure
az login

# Set your subscription (optional)
az account set --subscription <your-subscription-id>

# Verify authentication
az account show
```

? **Expected output:** Your Azure account details

### Step 2: API Setup (3 minutes)

```bash
# Run the automated setup script
chmod +x setup-api.sh
./setup-api.sh
```

This will:
- Install Node.js dependencies
- Create configuration files
- Verify everything is ready

? **Expected output:**
```
? Node.js v18.x.x detected
? npm 9.x.x detected
? API dependencies installed successfully
? .env file created
Setup Complete!
```

### Step 3: Start the API (1 minute)

```bash
cd api
npm start
```

? **Expected output:**
```
? Sandbox Environment API running on port 3000
? API endpoints available at http://localhost:3000/api
? Health check: http://localhost:3000/api/health
```

**Verify it's working:**
```bash
# In a new terminal
curl http://localhost:3000/api/health
```

You should see: `{"status":"healthy","timestamp":"...","version":"1.0.0"}`

### Step 4: Create Your First Environment (10-15 minutes)

?? **Note:** Creating an AKS cluster takes 5-10 minutes. This is normal!

```bash
# In a new terminal, go back to project root
cd ..

# Make scripts executable
chmod +x scripts/*.sh

# Create your first environment
./scripts/create_env.sh --name env1
```

**What happens:**
1. Creates Azure Resource Group: `rg-sandbox-env1`
2. Creates Container Registry: `acrsandboxenv1`
3. Creates AKS Cluster: `aks-sandbox-env1` ?? (5-10 minutes)
4. Configures kubectl context: `env1`
5. Creates Kubernetes namespace: `ns-env1`
6. Saves metadata: `.env-env1.json`

? **Expected output:**
```
==========================================
? Environment env1 created successfully!
==========================================
Resource Group:      rg-sandbox-env1
AKS Cluster:         aks-sandbox-env1
Kubernetes Context:  env1
Namespace:           ns-env1
Container Registry:  acrsandboxenv1
```

### Step 5: View in Web UI (30 seconds)

While the environment is being created (or after it's complete):

1. Open `ui/index.html` in your browser
2. You'll see your environment listed with status

**Alternative:** Serve with HTTP server:
```bash
# Python
python -m http.server 8080

# Node.js
npx http-server ui -p 8080

# Then open: http://localhost:8080
```

? **Expected result:** Beautiful dashboard showing your environment(s)

### Step 6: Verify Everything Works

```bash
# List environments via script
./scripts/list_envs.sh

# List environments via API
curl http://localhost:3000/api/envs

# Check environment details
./scripts/check_env.sh --name env1

# Test kubectl access
kubectl config use-context env1
kubectl get nodes
kubectl get namespaces
```

## What to Do Next

### Create More Environments

```bash
# Create 5 environments at once
./scripts/create_multiple_envs.sh env2 env3 env4 env5

# Or create with custom configuration
./scripts/create_env.sh \
  --name prod-test \
  --region westus2 \
  --node-count 3 \
  --node-size Standard_D4s_v3 \
  --tags "team=devops,project=testing"
```

### Deploy an Application

```bash
# Switch to your environment
kubectl config use-context env1

# Deploy something
kubectl create deployment nginx --image=nginx -n ns-env1
kubectl expose deployment nginx --port=80 --type=LoadBalancer -n ns-env1

# Check it out
kubectl get all -n ns-env1
```

### Integrate with Your Frontend

**React Example:**
```jsx
import { useEffect, useState } from 'react';

function EnvironmentList() {
  const [environments, setEnvironments] = useState([]);

  useEffect(() => {
    fetch('http://localhost:3000/api/envs')
      .then(res => res.json())
      .then(data => setEnvironments(data));
  }, []);

  return (
    <div>
      <h2>Environments</h2>
      {environments.map(env => (
        <div key={env.name}>
          <h3>{env.name}</h3>
          <span>{env.status}</span>
        </div>
      ))}
    </div>
  );
}
```

**JavaScript Example:**
```javascript
async function loadEnvironments() {
  const response = await fetch('http://localhost:3000/api/envs');
  const environments = await response.json();
  
  console.log(`Found ${environments.length} environments`);
  environments.forEach(env => {
    console.log(`- ${env.name}: ${env.status}`);
  });
}

loadEnvironments();
```

### Clean Up (When Done Testing)

```bash
# Delete a specific environment
./scripts/delete_env.sh --name env1

# Delete all environments (be careful!)
for i in {1..5}; do
  ./scripts/delete_env.sh --name env$i --force
done
```

## Quick Reference

### Common Commands

```bash
# API Commands
cd api && npm start              # Start API
curl http://localhost:3000/api/envs  # List environments

# Script Commands
./scripts/create_env.sh --name <name>   # Create environment
./scripts/delete_env.sh --name <name>   # Delete environment
./scripts/list_envs.sh                  # List all environments
./scripts/check_env.sh --name <name>    # Check status

# Kubectl Commands
kubectl config use-context <name>       # Switch context
kubectl get all -n ns-<name>           # View resources
kubectl delete namespace ns-<name>     # Clean up namespace
```

### File Locations

```
Project Root/
??? api/                    # API server
??? ui/index.html          # Web dashboard
??? scripts/               # Management scripts
??? .env-*.json           # Environment metadata
??? Documentation files
```

### API Endpoints

```
GET    /api/health              # Health check
GET    /api/envs                # List environments
GET    /api/envs/:name          # Get environment
POST   /api/envs                # Create environment
DELETE /api/envs/:name          # Delete environment
GET    /api/envs/:name/status   # Get status
```

## Troubleshooting

### Issue: "Command not found: npm"

**Solution:** Install Node.js from https://nodejs.org/

### Issue: "Azure CLI not authenticated"

**Solution:**
```bash
az login
az account show  # Verify
```

### Issue: "Port 3000 already in use"

**Solution:**
```bash
# Find what's using port 3000
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Kill it or change port in api/.env:
PORT=3001
```

### Issue: "Environment creation fails"

**Solution:**
1. Check Azure CLI authentication: `az account show`
2. Verify you have permissions to create resources
3. Check your Azure subscription has available quota
4. Try creating in a different region

### Issue: "Can't see environments in UI"

**Solution:**
1. Make sure API is running: `http://localhost:3000/api/health`
2. Check browser console for errors (F12)
3. Verify CORS is enabled (should be by default)
4. Try refreshing the page

### Issue: "Script permission denied"

**Solution:**
```bash
chmod +x scripts/*.sh
chmod +x *.sh
```

## Need Help?

### Documentation

- ?? **Main README**: `README.md` - Complete documentation
- ?? **API Docs**: `api/README.md` - API reference
- ?? **Setup Guide**: `SETUP.md` - Detailed setup
- ?? **Quick Reference**: `QUICKSTART.md` - Command cheat sheet
- ?? **Architecture**: `ARCHITECTURE.md` - System design
- ?? **API Summary**: `API_SUMMARY.md` - API integration guide

### Test Your Setup

Run the test suite to diagnose issues:
```bash
./test.sh
```

### Common Questions

**Q: How long does environment creation take?**  
A: 5-10 minutes for the AKS cluster, plus 2-3 minutes for other resources.

**Q: How much does each environment cost?**  
A: Depends on region and VM size. A Standard_D2s_v3 cluster with 2 nodes costs ~$200-300/month if running 24/7. Delete when not in use!

**Q: Can I have more than 5 environments?**  
A: Yes! Create as many as you need. Just use unique names.

**Q: Can multiple people share environments?**  
A: Each environment is isolated, but you can grant Azure RBAC permissions to others.

**Q: Can I deploy the API to Azure?**  
A: Yes! See the Docker and Azure Container Apps deployment instructions in `api/README.md`.

## Success Checklist

By the end of this guide, you should have:

- [x] Azure CLI authenticated
- [x] API running on port 3000
- [x] At least one environment created (env1)
- [x] Web UI showing your environments
- [x] kubectl access to your cluster
- [x] Understanding of how to create/delete environments
- [x] Knowledge of API endpoints for integration

## What's Next?

1. **Read the full documentation** in `README.md`
2. **Explore the API** in `api/README.md`
3. **Create more environments** for your team
4. **Integrate with your app** using the API
5. **Customize** the scripts for your needs
6. **Deploy** the API to Azure for production use

## Congratulations! ??

You've successfully set up the Sandbox Environment Manager!

You can now:
- ? Create isolated environments on demand
- ? Manage them via scripts, API, or Web UI
- ? Deploy applications to separate sandboxes
- ? Integrate environment management into your workflows

Enjoy your new sandbox environment system!
