# Sandbox Environment Manager - Complete Setup Guide

## What You Have Now

? **Scripts** - Create, delete, and manage sandbox environments  
? **API** - REST API for programmatic environment management  
? **Web UI** - Beautiful web interface to view and manage environments  

## Quick Start (3 Steps)

### 1. Setup Prerequisites

Make sure you have:
- Azure CLI installed and authenticated (`az login`)
- kubectl installed
- Node.js v16+ installed
- Bash (Linux/macOS/Git Bash/WSL)

### 2. Setup API

```bash
# Run the setup script
chmod +x setup-api.sh
./setup-api.sh

# Start the API
cd api
npm start
```

The API will be running at `http://localhost:3000`

### 3. Open Web UI

Simply open `ui/index.html` in your browser!

The UI will automatically connect to the API and show your environments.

## Complete Workflow Example

### Create Environments (Using Scripts)

```bash
# Create a single environment
./scripts/create_env.sh --name env1

# Create multiple environments
./scripts/create_multiple_envs.sh env1 env2 env3
```

### View Environments (Using Web UI)

1. Open `ui/index.html` in your browser
2. See all your environments with status
3. Click "Details" to see more info
4. Click "Delete" to remove an environment

### Or Use API Directly

```javascript
// Fetch all environments
fetch('http://localhost:3000/api/envs')
  .then(res => res.json())
  .then(envs => console.log(envs));

// Create environment via API
fetch('http://localhost:3000/api/envs', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'env4',
    region: 'eastus',
    nodeCount: 2
  })
})
.then(res => res.json())
.then(result => console.log(result));
```

## API Response Example

```json
[
  {
    "name": "env1",
    "status": "Running",
    "resourceGroup": "rg-sandbox-env1",
    "aksCluster": "aks-sandbox-env1",
    "namespace": "ns-env1",
    "containerRegistry": "acrsandboxenv1",
    "region": "eastus",
    "nodeCount": 2,
    "nodeSize": "Standard_D2s_v3",
    "createdAt": "2024-01-15T10:30:00Z",
    "kubeContext": "env1",
    "tags": "environment=env1,created=2024-01-15"
  }
]
```

## Frontend Integration Examples

### Vanilla JavaScript

```javascript
async function fetchEnvironments() {
  const response = await fetch('http://localhost:3000/api/envs');
  const environments = await response.json();
  
  // Render list
  document.getElementById('env-list').innerHTML = environments.map(env => `
    <div class="env-card">
      <h3>${env.name}</h3>
      <span class="status">${env.status}</span>
      <p>Cluster: ${env.aksCluster}</p>
      <p>Region: ${env.region}</p>
    </div>
  `).join('');
}

fetchEnvironments();
```

### React

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

### Vue.js

```vue
<template>
  <div v-for="env in environments" :key="env.name">
    <h3>{{ env.name }}</h3>
    <span>{{ env.status }}</span>
  </div>
</template>

<script>
export default {
  data() {
    return { environments: [] };
  },
  mounted() {
    fetch('http://localhost:3000/api/envs')
      .then(res => res.json())
      .then(data => this.environments = data);
  }
};
</script>
```

### Angular

```typescript
import { HttpClient } from '@angular/common/http';
import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-environments',
  template: `
    <div *ngFor="let env of environments">
      <h3>{{ env.name }}</h3>
      <span>{{ env.status }}</span>
    </div>
  `
})
export class EnvironmentsComponent implements OnInit {
  environments: any[] = [];

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.http.get<any[]>('http://localhost:3000/api/envs')
      .subscribe(data => this.environments = data);
  }
}
```

## Project Structure

```
Sandbox-env-manager/
??? api/                          # REST API
?   ??? server.js                 # Express server
?   ??? routes/
?   ?   ??? environments.js       # Environment endpoints
?   ??? services/
?   ?   ??? environmentService.js # Business logic
?   ??? package.json
?   ??? Dockerfile
?   ??? README.md                 # API documentation
??? ui/
?   ??? index.html                # Web UI
??? scripts/                      # Shell scripts
?   ??? create_env.sh
?   ??? delete_env.sh
?   ??? list_envs.sh
?   ??? create_multiple_envs.sh
?   ??? check_env.sh
??? .env-*.json                   # Environment metadata
??? setup-api.sh                  # API setup script
??? README.md                     # Main documentation
??? QUICKSTART.md                 # Quick reference
```

## API Endpoints Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/envs` | List all environments |
| GET | `/api/envs/:name` | Get environment details |
| GET | `/api/envs/:name/status` | Get environment status |
| POST | `/api/envs` | Create new environment |
| DELETE | `/api/envs/:name` | Delete environment |

## Development Tips

### Running API in Development Mode

```bash
cd api
npm run dev  # Auto-reloads on file changes
```

### Testing API with curl

```bash
# List environments
curl http://localhost:3000/api/envs

# Get specific environment
curl http://localhost:3000/api/envs/env1

# Create environment
curl -X POST http://localhost:3000/api/envs \
  -H "Content-Type: application/json" \
  -d '{"name":"test","region":"eastus"}'

# Delete environment
curl -X DELETE http://localhost:3000/api/envs/test?force=true
```

### CORS Configuration

If your frontend is on a different port, configure CORS in `api/.env`:

```env
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:3001
```

## Deployment

### Docker

```bash
cd api
docker build -t sandbox-api .
docker run -p 3000:3000 sandbox-api
```

### Azure Container Apps

```bash
# Build and push
az acr build --registry myregistry --image sandbox-api:latest ./api

# Deploy
az containerapp create \
  --name sandbox-api \
  --resource-group my-rg \
  --image myregistry.azurecr.io/sandbox-api:latest \
  --target-port 3000 \
  --ingress external
```

## Troubleshooting

### API won't start

```bash
# Check if port 3000 is in use
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# Check Node.js version
node --version  # Should be v16+

# Reinstall dependencies
cd api
rm -rf node_modules package-lock.json
npm install
```

### UI can't connect to API

1. Ensure API is running: `http://localhost:3000/api/health`
2. Check browser console for CORS errors
3. Update CORS_ORIGINS in `api/.env`

### Environments not showing

1. Ensure you've created environments using the scripts
2. Check that `.env-*.json` files exist in project root
3. Verify Azure CLI is authenticated: `az account show`

## Next Steps

1. ? **Create environments** using scripts
2. ? **Start the API** with `npm start`
3. ? **Open the UI** in your browser
4. ? **Integrate with your app** using the API
5. ?? **Add authentication** for production use
6. ?? **Deploy to Azure** for team access

## Support

- ?? [Main README](./README.md) - Full documentation
- ?? [API README](./api/README.md) - API documentation
- ?? [QUICKSTART](./QUICKSTART.md) - Quick reference

For issues or questions, check the troubleshooting sections in the documentation.
