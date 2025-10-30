# Sandbox Environment Manager API

REST API for managing Azure sandbox environments with AKS and ACR.

## Quick Start

### Installation

```bash
cd api
npm install
```

### Configuration

Create a `.env` file (copy from `.env.example`):

```bash
cp .env.example .env
```

### Start the Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The API will be available at: `http://localhost:3000`

## API Endpoints

### Health Check

```http
GET /api/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "version": "1.0.0"
}
```

### List All Environments

```http
GET /api/envs
```

Response:
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
  },
  {
    "name": "env2",
    "status": "Starting",
    "resourceGroup": "rg-sandbox-env2",
    "aksCluster": "aks-sandbox-env2",
    "namespace": "ns-env2",
    "containerRegistry": "acrsandboxenv2",
    "region": "eastus",
    "nodeCount": 2,
    "nodeSize": "Standard_D2s_v3",
    "createdAt": "2024-01-15T11:00:00Z",
    "kubeContext": "env2",
    "tags": "environment=env2,created=2024-01-15"
  }
]
```

### Get Specific Environment

```http
GET /api/envs/:name
```

Example:
```http
GET /api/envs/env1
```

Response:
```json
{
  "environmentName": "env1",
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
```

### Create Environment

```http
POST /api/envs
Content-Type: application/json

{
  "name": "env3",
  "region": "westus2",
  "nodeCount": 3,
  "nodeSize": "Standard_D4s_v3",
  "tags": "team=devops,project=test"
}
```

Response:
```json
{
  "success": true,
  "message": "Environment env3 created successfully",
  "name": "env3",
  "output": "..."
}
```

**Note:** Environment creation takes several minutes. Consider implementing job queuing for production use.

### Delete Environment

```http
DELETE /api/envs/:name?force=true
```

Example:
```http
DELETE /api/envs/env1?force=true
```

Response:
```json
{
  "success": true,
  "message": "Environment env1 deletion initiated",
  "name": "env1",
  "output": "..."
}
```

### Get Environment Status

```http
GET /api/envs/:name/status
```

Example:
```http
GET /api/envs/env1/status
```

Response:
```json
{
  "name": "env1",
  "status": "Running",
  "details": "..."
}
```

## Frontend Integration

### Basic Fetch Example

```javascript
// Fetch all environments
async function fetchEnvironments() {
  try {
    const response = await fetch('http://localhost:3000/api/envs');
    const environments = await response.json();
    console.log('Environments:', environments);
    return environments;
  } catch (error) {
    console.error('Error fetching environments:', error);
    throw error;
  }
}

// Render environment list
async function renderEnvironmentList() {
  const environments = await fetchEnvironments();
  
  const container = document.getElementById('env-list');
  container.innerHTML = environments.map(env => `
    <div class="environment-card">
      <h3>${env.name}</h3>
      <span class="status status-${env.status.toLowerCase()}">${env.status}</span>
      <p>Cluster: ${env.aksCluster}</p>
      <p>Region: ${env.region}</p>
      <p>Created: ${new Date(env.createdAt).toLocaleString()}</p>
    </div>
  `).join('');
}

// Call on page load
renderEnvironmentList();
```

### React Example

```jsx
import { useEffect, useState } from 'react';

function EnvironmentList() {
  const [environments, setEnvironments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchEnvironments();
  }, []);

  async function fetchEnvironments() {
    try {
      const response = await fetch('http://localhost:3000/api/envs');
      if (!response.ok) throw new Error('Failed to fetch environments');
      const data = await response.json();
      setEnvironments(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  if (loading) return <div>Loading environments...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div className="environment-list">
      <h2>Sandbox Environments</h2>
      {environments.length === 0 ? (
        <p>No environments found</p>
      ) : (
        <div className="grid">
          {environments.map(env => (
            <div key={env.name} className="environment-card">
              <h3>{env.name}</h3>
              <span className={`status status-${env.status.toLowerCase()}`}>
                {env.status}
              </span>
              <div className="details">
                <p><strong>Cluster:</strong> {env.aksCluster}</p>
                <p><strong>Region:</strong> {env.region}</p>
                <p><strong>Namespace:</strong> {env.namespace}</p>
                <p><strong>Created:</strong> {new Date(env.createdAt).toLocaleString()}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default EnvironmentList;
```

### Vue.js Example

```vue
<template>
  <div class="environment-list">
    <h2>Sandbox Environments</h2>
    <div v-if="loading">Loading environments...</div>
    <div v-else-if="error">Error: {{ error }}</div>
    <div v-else-if="environments.length === 0">No environments found</div>
    <div v-else class="grid">
      <div 
        v-for="env in environments" 
        :key="env.name" 
        class="environment-card"
      >
        <h3>{{ env.name }}</h3>
        <span :class="['status', `status-${env.status.toLowerCase()}`]">
          {{ env.status }}
        </span>
        <div class="details">
          <p><strong>Cluster:</strong> {{ env.aksCluster }}</p>
          <p><strong>Region:</strong> {{ env.region }}</p>
          <p><strong>Namespace:</strong> {{ env.namespace }}</p>
          <p><strong>Created:</strong> {{ formatDate(env.createdAt) }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      environments: [],
      loading: true,
      error: null
    };
  },
  mounted() {
    this.fetchEnvironments();
  },
  methods: {
    async fetchEnvironments() {
      try {
        const response = await fetch('http://localhost:3000/api/envs');
        if (!response.ok) throw new Error('Failed to fetch environments');
        this.environments = await response.json();
      } catch (err) {
        this.error = err.message;
      } finally {
        this.loading = false;
      }
    },
    formatDate(dateString) {
      return new Date(dateString).toLocaleString();
    }
  }
};
</script>
```

## Error Handling

The API returns standard HTTP status codes:

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request parameters
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

Error response format:
```json
{
  "error": "Error message",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## CORS Configuration

By default, CORS is enabled for development. Configure allowed origins in `.env`:

```env
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080
```

## Deployment

### Docker

Build and run the API in a container:

```bash
docker build -t sandbox-api .
docker run -p 3000:3000 -v $(pwd)/../.env-*.json:/app/.env-*.json sandbox-api
```

### Azure Container Apps

Deploy to Azure Container Apps for a serverless API:

```bash
# Build and push image
az acr build --registry myregistry --image sandbox-api:latest .

# Deploy to Container Apps
az containerapp create \
  --name sandbox-api \
  --resource-group my-rg \
  --image myregistry.azurecr.io/sandbox-api:latest \
  --target-port 3000 \
  --ingress external
```

## Development

### Project Structure

```
api/
??? server.js                 # Main server entry point
??? routes/
?   ??? environments.js       # Environment routes
??? services/
?   ??? environmentService.js # Business logic
??? package.json              # Dependencies
??? .env.example              # Environment variables template
??? README.md                 # This file
```

### Adding New Endpoints

1. Create route handler in `routes/`
2. Implement business logic in `services/`
3. Register route in `server.js`
4. Update this README

## Testing

Test the API using curl:

```bash
# Health check
curl http://localhost:3000/api/health

# List environments
curl http://localhost:3000/api/envs

# Get specific environment
curl http://localhost:3000/api/envs/env1

# Create environment
curl -X POST http://localhost:3000/api/envs \
  -H "Content-Type: application/json" \
  -d '{"name":"test-env","region":"eastus"}'

# Delete environment
curl -X DELETE http://localhost:3000/api/envs/test-env?force=true
```

## Security Considerations

For production deployment:

1. **Authentication**: Add JWT or OAuth authentication
2. **Rate Limiting**: Implement rate limiting to prevent abuse
3. **Input Validation**: Add comprehensive input validation
4. **HTTPS**: Always use HTTPS in production
5. **API Keys**: Consider API key authentication
6. **RBAC**: Implement role-based access control

## Troubleshooting

### API not starting

- Check that port 3000 is not in use: `lsof -i :3000`
- Verify Node.js is installed: `node --version`
- Check logs for errors

### Environments not listing

- Ensure `.env-*.json` files exist in the project root
- Check file permissions
- Verify Azure CLI is installed and authenticated

### Script execution failing

- Ensure bash is available: `which bash`
- Check script permissions: `chmod +x scripts/*.sh`
- Verify Azure CLI authentication: `az account show`

## License

[Add your license here]
