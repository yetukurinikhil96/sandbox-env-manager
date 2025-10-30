#!/bin/bash

# Quick setup script for Sandbox Environment Manager API

set -e

echo "=========================================="
echo "Sandbox Environment Manager - API Setup"
echo "=========================================="
echo ""

# Check Node.js installation
if ! command -v node &> /dev/null; then
    echo "? Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version)
echo "? Node.js $NODE_VERSION detected"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "? npm is not installed!"
    exit 1
fi

echo "? npm $(npm --version) detected"
echo ""

# Install API dependencies
echo "Installing API dependencies..."
cd api
npm install

if [ $? -eq 0 ]; then
    echo "? API dependencies installed successfully"
else
    echo "? Failed to install API dependencies"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo ""
    echo "Creating .env file..."
    cp .env.example .env
    echo "? .env file created"
    echo "  Edit api/.env to customize configuration"
fi

cd ..

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Start the API server:"
echo "  cd api"
echo "  npm start"
echo ""
echo "Or run in development mode (with auto-reload):"
echo "  cd api"
echo "  npm run dev"
echo ""
echo "The API will be available at:"
echo "  http://localhost:3000"
echo ""
echo "Open the Web UI:"
echo "  Open ui/index.html in your browser"
echo ""
echo "API Documentation:"
echo "  See api/README.md for full API documentation"
echo ""
echo "=========================================="
