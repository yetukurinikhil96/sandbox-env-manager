// API Configuration
const API_BASE_URL = 'http://localhost:3000/api';

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    loadEnvironments();
    
    // Auto-refresh every 30 seconds
    setInterval(loadEnvironments, 30000);
});

// Load environments from API
async function loadEnvironments() {
    const spinner = document.getElementById('loadingSpinner');
    const tableBody = document.getElementById('environmentTableBody');
    const emptyState = document.getElementById('emptyState');
    const table = document.getElementById('environmentTable');
    
    try {
        spinner.style.display = 'block';
        table.style.display = 'none';
        emptyState.style.display = 'none';
        
        const response = await fetch(`${API_BASE_URL}/envs`);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const environments = await response.json();
        
        spinner.style.display = 'none';
        
        if (environments.length === 0) {
            emptyState.style.display = 'block';
            table.style.display = 'none';
        } else {
            tableBody.innerHTML = '';
            environments.forEach(env => {
                const row = createEnvironmentRow(env);
                tableBody.appendChild(row);
            });
            table.style.display = 'table';
            emptyState.style.display = 'none';
        }
    } catch (error) {
        console.error('Error loading environments:', error);
        spinner.style.display = 'none';
        showAlert('danger', `Failed to load environments: ${error.message}`);
    }
}

// Create table row for environment
function createEnvironmentRow(env) {
    const row = document.createElement('tr');
    
    const statusBadge = getStatusBadge(env.status);
    const createdDate = new Date(env.createdAt).toLocaleString();
    
    row.innerHTML = `
        <td><strong>${env.name}</strong></td>
        <td>${statusBadge}</td>
        <td><small>${env.resourceGroup}</small></td>
        <td><small>${env.aksCluster}</small></td>
        <td>${env.region}</td>
        <td><small>${createdDate}</small></td>
        <td>
            <button class="btn btn-sm btn-info" onclick="viewDetails('${env.name}')" title="View Details">
                <i class="bi bi-eye"></i>
            </button>
            <button class="btn btn-sm btn-danger" onclick="confirmDelete('${env.name}')" title="Delete">
                <i class="bi bi-trash"></i>
            </button>
        </td>
    `;
    
    return row;
}

// Get status badge HTML
function getStatusBadge(status) {
    const statusClasses = {
        'Running': 'bg-success',
        'Starting': 'bg-warning',
        'Stopped': 'bg-danger',
        'Unknown': 'bg-secondary'
    };
    
    const badgeClass = statusClasses[status] || 'bg-secondary';
    return `<span class="badge ${badgeClass}">${status}</span>`;
}

// Show create environment modal
function showCreateModal() {
    const modal = new bootstrap.Modal(document.getElementById('createEnvModal'));
    document.getElementById('createEnvForm').reset();
    modal.show();
}

// Create new environment
async function createEnvironment() {
    const name = document.getElementById('envName').value.trim();
    const region = document.getElementById('envRegion').value;
    const nodeCount = parseInt(document.getElementById('nodeCount').value);
    
    if (!name) {
        showAlert('warning', 'Please enter an environment name');
        return;
    }
    
    // Validate name format
    if (!/^[a-z0-9-]+$/.test(name)) {
        showAlert('warning', 'Environment name must contain only lowercase letters, numbers, and hyphens');
        return;
    }
    
    const modal = bootstrap.Modal.getInstance(document.getElementById('createEnvModal'));
    modal.hide();
    
    showAlert('info', `Creating environment "${name}"... This will take 5-10 minutes.`);
    
    try {
        const response = await fetch(`${API_BASE_URL}/envs`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: name,
                region: region,
                nodeCount: nodeCount
            })
        });
        
        const result = await response.json();
        
        if (response.ok) {
            showAlert('success', `Environment "${name}" is being created. Refresh the page in a few minutes to see it.`);
            // Reload environments after a delay
            setTimeout(loadEnvironments, 5000);
        } else {
            showAlert('danger', `Failed to create environment: ${result.error || result.message}`);
        }
    } catch (error) {
        console.error('Error creating environment:', error);
        showAlert('danger', `Failed to create environment: ${error.message}`);
    }
}

// View environment details
async function viewDetails(name) {
    try {
        const response = await fetch(`${API_BASE_URL}/envs/${name}`);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const env = await response.json();
        
        const detailsBody = document.getElementById('detailsModalBody');
        detailsBody.innerHTML = `
            <table class="table table-bordered">
                <tr>
                    <th>Name</th>
                    <td>${env.environmentName || env.name}</td>
                </tr>
                <tr>
                    <th>Status</th>
                    <td>${getStatusBadge(env.status)}</td>
                </tr>
                <tr>
                    <th>Resource Group</th>
                    <td>${env.resourceGroup}</td>
                </tr>
                <tr>
                    <th>AKS Cluster</th>
                    <td>${env.aksCluster}</td>
                </tr>
                <tr>
                    <th>Container Registry</th>
                    <td>${env.containerRegistry}</td>
                </tr>
                <tr>
                    <th>Namespace</th>
                    <td>${env.namespace}</td>
                </tr>
                <tr>
                    <th>Region</th>
                    <td>${env.region}</td>
                </tr>
                <tr>
                    <th>Node Count</th>
                    <td>${env.nodeCount}</td>
                </tr>
                <tr>
                    <th>Node Size</th>
                    <td>${env.nodeSize}</td>
                </tr>
                <tr>
                    <th>Kubectl Context</th>
                    <td><code>${env.kubeContext}</code></td>
                </tr>
                <tr>
                    <th>Created</th>
                    <td>${new Date(env.createdAt).toLocaleString()}</td>
                </tr>
                <tr>
                    <th>Tags</th>
                    <td><small>${env.tags || 'None'}</small></td>
                </tr>
            </table>
        `;
        
        const modal = new bootstrap.Modal(document.getElementById('detailsModal'));
        modal.show();
    } catch (error) {
        console.error('Error loading environment details:', error);
        showAlert('danger', `Failed to load details: ${error.message}`);
    }
}

// Confirm delete environment
function confirmDelete(name) {
    if (confirm(`Are you sure you want to delete environment "${name}"?\n\nThis action cannot be undone!`)) {
        deleteEnvironment(name);
    }
}

// Delete environment
async function deleteEnvironment(name) {
    showAlert('info', `Deleting environment "${name}"...`);
    
    try {
        const response = await fetch(`${API_BASE_URL}/envs/${name}?force=true`, {
            method: 'DELETE'
        });
        
        const result = await response.json();
        
        if (response.ok) {
            showAlert('success', `Environment "${name}" has been deleted.`);
            loadEnvironments();
        } else {
            showAlert('danger', `Failed to delete environment: ${result.error || result.message}`);
        }
    } catch (error) {
        console.error('Error deleting environment:', error);
        showAlert('danger', `Failed to delete environment: ${error.message}`);
    }
}

// Show alert message
function showAlert(type, message) {
    const alertContainer = document.getElementById('alertContainer');
    const alertId = 'alert-' + Date.now();
    
    const alertHtml = `
        <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show" role="alert">
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;
    
    alertContainer.innerHTML = alertHtml;
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        const alert = document.getElementById(alertId);
        if (alert) {
            const bsAlert = bootstrap.Alert.getInstance(alert);
            if (bsAlert) {
                bsAlert.close();
            }
        }
    }, 5000);
}
