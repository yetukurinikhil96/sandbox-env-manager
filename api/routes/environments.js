const express = require('express');
const router = express.Router();
const environmentService = require('../services/environmentService');

// GET /api/envs - List all environments
router.get('/', async (req, res, next) => {
    try {
        const environments = await environmentService.listEnvironments();
        res.json(environments);
    } catch (error) {
        next(error);
    }
});

// GET /api/envs/:name - Get specific environment details
router.get('/:name', async (req, res, next) => {
    try {
        const { name } = req.params;
        const environment = await environmentService.getEnvironment(name);
        
        if (!environment) {
            return res.status(404).json({
                error: 'Environment not found',
                name: name
            });
        }
        
        res.json(environment);
    } catch (error) {
        next(error);
    }
});

// POST /api/envs - Create new environment
router.post('/', async (req, res, next) => {
    try {
        const { name, region, nodeCount, nodeSize, tags } = req.body;
        
        if (!name) {
            return res.status(400).json({
                error: 'Environment name is required'
            });
        }
        
        const result = await environmentService.createEnvironment({
            name,
            region,
            nodeCount,
            nodeSize,
            tags
        });
        
        res.status(201).json(result);
    } catch (error) {
        next(error);
    }
});

// DELETE /api/envs/:name - Delete environment
router.delete('/:name', async (req, res, next) => {
    try {
        const { name } = req.params;
        const { force } = req.query;
        
        const result = await environmentService.deleteEnvironment(name, force === 'true');
        res.json(result);
    } catch (error) {
        next(error);
    }
});

// GET /api/envs/:name/status - Get environment status
router.get('/:name/status', async (req, res, next) => {
    try {
        const { name } = req.params;
        const status = await environmentService.getEnvironmentStatus(name);
        
        if (!status) {
            return res.status(404).json({
                error: 'Environment not found',
                name: name
            });
        }
        
        res.json(status);
    } catch (error) {
        next(error);
    }
});

module.exports = router;
