const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const environmentRoutes = require('./routes/environments');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// Routes
app.use('/api/envs', environmentRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        message: 'Sandbox Environment Manager API',
        version: '1.0.0',
        endpoints: {
            health: '/api/health',
            environments: {
                list: 'GET /api/envs',
                get: 'GET /api/envs/:name',
                create: 'POST /api/envs',
                delete: 'DELETE /api/envs/:name'
            }
        }
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        error: err.message || 'Internal Server Error',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        path: req.path,
        timestamp: new Date().toISOString()
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`? Sandbox Environment API running on port ${PORT}`);
    console.log(`? API endpoints available at http://localhost:${PORT}/api`);
    console.log(`? Health check: http://localhost:${PORT}/api/health`);
    console.log(`? Environments: http://localhost:${PORT}/api/envs`);
});

module.exports = app;
