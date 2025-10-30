const fs = require('fs').promises;
const path = require('path');
const glob = require('glob');
const { promisify } = require('util');
const { exec } = require('child_process');

const globAsync = promisify(glob);
const execAsync = promisify(exec);

// Path to the project root (one level up from api/)
const PROJECT_ROOT = path.join(__dirname, '..', '..');
const ENV_FILE_PATTERN = path.join(PROJECT_ROOT, '.env-*.json');

/**
 * List all sandbox environments
 * Reads .env-*.json files to get environment information
 */
async function listEnvironments() {
    try {
        // Find all environment metadata files
        const envFiles = await globAsync(ENV_FILE_PATTERN);
        
        if (envFiles.length === 0) {
            return [];
        }
        
        const environments = [];
        
        for (const filePath of envFiles) {
            try {
                const content = await fs.readFile(filePath, 'utf8');
                const envData = JSON.parse(content);
                
                // Get status from Azure (optional - can be slow)
                let status = 'Unknown';
                try {
                    status = await getEnvironmentStatusFromAzure(envData.environmentName);
                } catch (error) {
                    console.warn(`Could not get status for ${envData.environmentName}:`, error.message);
                }
                
                environments.push({
                    name: envData.environmentName,
                    status: status,
                    resourceGroup: envData.resourceGroup,
                    aksCluster: envData.aksCluster,
                    namespace: envData.namespace,
                    containerRegistry: envData.containerRegistry,
                    region: envData.region,
                    nodeCount: envData.nodeCount,
                    nodeSize: envData.nodeSize,
                    createdAt: envData.createdAt,
                    kubeContext: envData.kubeContext,
                    tags: envData.tags
                });
            } catch (error) {
                console.error(`Error reading environment file ${filePath}:`, error.message);
            }
        }
        
        // Sort by creation date (newest first)
        environments.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        
        return environments;
    } catch (error) {
        console.error('Error listing environments:', error);
        throw new Error('Failed to list environments');
    }
}

/**
 * Get specific environment details
 */
async function getEnvironment(name) {
    try {
        const sanitizedName = sanitizeEnvironmentName(name);
        const envFilePath = path.join(PROJECT_ROOT, `.env-${sanitizedName}.json`);
        
        // Check if file exists
        try {
            await fs.access(envFilePath);
        } catch {
            return null;
        }
        
        const content = await fs.readFile(envFilePath, 'utf8');
        const envData = JSON.parse(content);
        
        // Get detailed status
        const status = await getEnvironmentStatusFromAzure(sanitizedName);
        
        return {
            ...envData,
            status: status
        };
    } catch (error) {
        console.error(`Error getting environment ${name}:`, error);
        throw new Error(`Failed to get environment ${name}`);
    }
}

/**
 * Create a new environment
 */
async function createEnvironment(options) {
    try {
        const { name, region, nodeCount, nodeSize, tags } = options;
        
        // Build command
        const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'create_env.sh');
        let command = `bash "${scriptPath}" --name ${name}`;
        
        if (region) command += ` --region ${region}`;
        if (nodeCount) command += ` --node-count ${nodeCount}`;
        if (nodeSize) command += ` --node-size ${nodeSize}`;
        if (tags) command += ` --tags "${tags}"`;
        
        console.log(`Executing: ${command}`);
        
        // Execute script (this will take several minutes)
        // In production, you'd want to run this asynchronously with job tracking
        const { stdout, stderr } = await execAsync(command, {
            cwd: PROJECT_ROOT,
            timeout: 30 * 60 * 1000 // 30 minute timeout
        });
        
        if (stderr) {
            console.warn('Script warnings:', stderr);
        }
        
        return {
            success: true,
            message: `Environment ${name} created successfully`,
            name: name,
            output: stdout
        };
    } catch (error) {
        console.error('Error creating environment:', error);
        throw new Error(`Failed to create environment: ${error.message}`);
    }
}

/**
 * Delete an environment
 */
async function deleteEnvironment(name, force = false) {
    try {
        const sanitizedName = sanitizeEnvironmentName(name);
        const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'delete_env.sh');
        
        let command = `bash "${scriptPath}" --name ${sanitizedName}`;
        if (force) {
            command += ' --force';
        }
        
        console.log(`Executing: ${command}`);
        
        const { stdout, stderr } = await execAsync(command, {
            cwd: PROJECT_ROOT,
            timeout: 10 * 60 * 1000 // 10 minute timeout
        });
        
        if (stderr) {
            console.warn('Script warnings:', stderr);
        }
        
        return {
            success: true,
            message: `Environment ${name} deletion initiated`,
            name: sanitizedName,
            output: stdout
        };
    } catch (error) {
        console.error('Error deleting environment:', error);
        throw new Error(`Failed to delete environment: ${error.message}`);
    }
}

/**
 * Get environment status from Azure
 */
async function getEnvironmentStatusFromAzure(name) {
    try {
        const sanitizedName = sanitizeEnvironmentName(name);
        const resourceGroup = `rg-sandbox-${sanitizedName}`;
        
        // Check if resource group exists
        const { stdout } = await execAsync(
            `az group show --name ${resourceGroup} --query "properties.provisioningState" -o tsv`,
            { timeout: 30000 }
        );
        
        const provisioningState = stdout.trim();
        
        if (provisioningState === 'Succeeded') {
            // Check AKS cluster status
            const clusterName = `aks-sandbox-${sanitizedName}`;
            try {
                const { stdout: clusterStatus } = await execAsync(
                    `az aks show --resource-group ${resourceGroup} --name ${clusterName} --query "powerState.code" -o tsv`,
                    { timeout: 30000 }
                );
                
                return clusterStatus.trim() === 'Running' ? 'Running' : 'Stopped';
            } catch {
                return 'Starting';
            }
        }
        
        return provisioningState;
    } catch (error) {
        // If resource group doesn't exist or other error
        return 'Unknown';
    }
}

/**
 * Get detailed environment status
 */
async function getEnvironmentStatus(name) {
    try {
        const sanitizedName = sanitizeEnvironmentName(name);
        const scriptPath = path.join(PROJECT_ROOT, 'scripts', 'check_env.sh');
        
        const command = `bash "${scriptPath}" --name ${sanitizedName}`;
        
        const { stdout, stderr } = await execAsync(command, {
            cwd: PROJECT_ROOT,
            timeout: 60000 // 1 minute timeout
        });
        
        // Parse the output (you can enhance this to parse structured data)
        return {
            name: sanitizedName,
            status: 'Running', // Parse from output
            details: stdout
        };
    } catch (error) {
        return {
            name: sanitizedName,
            status: 'Unknown',
            error: error.message
        };
    }
}

/**
 * Sanitize environment name
 */
function sanitizeEnvironmentName(name) {
    return name.toLowerCase().replace(/[^a-z0-9-]/g, '-');
}

module.exports = {
    listEnvironments,
    getEnvironment,
    createEnvironment,
    deleteEnvironment,
    getEnvironmentStatus,
    getEnvironmentStatusFromAzure
};
