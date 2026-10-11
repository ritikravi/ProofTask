#!/bin/bash

# ProofTask Backend Setup Script

set -e

echo "🚀 ProofTask Backend Setup"
echo "=========================="
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version $NODE_VERSION is too old. Please upgrade to Node.js 18+"
    exit 1
fi

echo "✅ Node.js $(node -v) found"

# Check MongoDB
if ! command -v mongod &> /dev/null && ! command -v docker &> /dev/null; then
    echo "⚠️  MongoDB not found. You'll need either:"
    echo "   1. MongoDB installed locally"
    echo "   2. Docker to run MongoDB in a container"
    echo ""
    echo "   macOS: brew install mongodb-community"
    echo "   Docker: docker run -d -p 27017:27017 --name mongodb mongo:latest"
    echo ""
fi

# Install dependencies
echo ""
echo "📦 Installing npm dependencies..."
npm install

# Setup .env if not exists
if [ ! -f .env ]; then
    echo ""
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo ""
    echo "⚠️  IMPORTANT: Edit backend/.env and add:"
    echo "   - XAI_API_KEY (get from console.x.ai)"
    echo "   - MONGODB_URI (default: mongodb://localhost:27017/prooftask)"
    echo "   - JWT_SECRET (generate a random string)"
    echo ""
else
    echo ""
    echo "✅ .env file already exists"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit .env with your configuration"
echo "  2. Start MongoDB (if not running)"
echo "  3. Run: npm start"
echo ""
echo "MongoDB quick start:"
echo "  brew services start mongodb-community  # macOS"
echo "  docker run -d -p 27017:27017 --name mongodb mongo:latest  # Docker"
echo ""
