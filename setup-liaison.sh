#!/bin/bash
set -e

echo "🚀 Setting up lIAison Platform..."

# Check prerequisites
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 24+ is required"
    echo "📥 Install from: https://nodejs.org/"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required"
    echo "📥 Install from: https://docker.com/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is required"
    echo "📥 Install Docker Desktop or docker-compose"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
if [ "$NODE_VERSION" -lt 24 ]; then
    echo "❌ Node.js 24+ is required (current: $(node -v))"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create directory structure
echo "📁 Creating project structure..."
mkdir -p frontend/{src/{components,pages,styles,utils,hooks},public,__tests__}
mkdir -p backend/{src/{controllers,models,routes,middleware,services,utils},tests,prisma}
mkdir -p ai-engine/{models,services,utils,tests}
mkdir -p blockchain/{contracts,scripts,test,migrations}
mkdir -p scripts/{deployment,monitoring,backup}
mkdir -p docs/{api,architecture,deployment,user-guide}
mkdir -p nginx/{conf.d,ssl}
mkdir -p monitoring/{prometheus,grafana,alerts}
mkdir -p .github/workflows

# Install root dependencies
echo "📦 Installing root dependencies..."
npm install

# Set up environment variables
echo "🔧 Setting up environment..."
if [ ! -f .env ]; then
    cat > .env << 'EOF'
# lIAison Platform Environment Configuration

# Database
DATABASE_URL="postgresql://postgres:password@localhost:5432/liaison"
REDIS_URL="redis://localhost:6379"

# Authentication
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
JWT_EXPIRES_IN="24h"

# API Keys (Required - Update with your keys)
OPENAI_API_KEY="your-openai-api-key"
HUGGINGFACE_API_KEY="your-huggingface-api-key"
STRIPE_SECRET_KEY="your-stripe-secret-key"
STRIPE_PUBLISHABLE_KEY="your-stripe-publishable-key"

# Blockchain
ETHEREUM_RPC_URL="https://mainnet.infura.io/v3/your-infura-key"
POLYGON_RPC_URL="https://polygon-mainnet.infura.io/v3/your-infura-key"
ARBITRUM_RPC_URL="https://arbitrum-mainnet.infura.io/v3/your-infura-key"
PRIVATE_KEY="your-deployment-private-key"

# Vector Database
VECTOR_DB_URL="http://localhost:8001"
PINECONE_API_KEY="your-pinecone-api-key"
PINECONE_INDEX_NAME="liaison-vectors"

# Email Service
SMTP_HOST="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="your-email@gmail.com"
SMTP_PASS="your-app-password"

# File Storage
AWS_ACCESS_KEY_ID="your-aws-access-key"
AWS_SECRET_ACCESS_KEY="your-aws-secret-key"
AWS_S3_BUCKET="liaison-storage"
AWS_REGION="us-east-1"

# Monitoring
GRAFANA_ADMIN_PASSWORD="admin"
PROMETHEUS_RETENTION="30d"

# Development
NODE_ENV="development"
LOG_LEVEL="debug"
EOF
    echo "✅ Created .env file - IMPORTANT: Update with your API keys!"
    echo "🔑 Required keys: OPENAI_API_KEY, STRIPE_SECRET_KEY, ETHEREUM_RPC_URL"
else
    echo "✅ .env file already exists"
fi

# Initialize database services
echo "🗄️ Starting database services..."
docker-compose up -d db redis chromadb
echo "⏳ Waiting for databases to initialize..."
sleep 15

# Check database connectivity
echo "🔍 Testing database connectivity..."
if docker-compose exec -T db psql -U postgres -d liaison -c 'SELECT 1;' > /dev/null 2>&1; then
    echo "✅ PostgreSQL connected successfully"
else
    echo "❌ PostgreSQL connection failed"
    echo "🔧 Try: docker-compose logs db"
fi

if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis connected successfully"
else
    echo "❌ Redis connection failed"
    echo "🔧 Try: docker-compose logs redis"
fi

# Build all services
echo "🔨 Building all services..."
docker-compose build --parallel

# Start all services
echo "🚀 Starting lIAison Platform..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to initialize..."
sleep 30

# Health checks
echo "🏥 Performing health checks..."

# Check frontend
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend is running"
else
    echo "⚠️ Frontend not responding"
fi

# Check backend
if curl -s http://localhost:4000/health > /dev/null; then
    echo "✅ Backend API is running"
else
    echo "⚠️ Backend API not responding"
fi

# Check AI engine
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ AI Engine is running"
else
    echo "⚠️ AI Engine not responding"
fi

echo ""
echo "🎉 lIAison Platform Setup Complete!"
echo ""
echo "🌐 Access Points:"
echo "   Frontend Dashboard: http://localhost:3000"
echo "   Backend API: http://localhost:4000"
echo "   AI Engine: http://localhost:8000"
echo "   Grafana Monitoring: http://localhost:3001 (admin/admin)"
echo "   Prometheus Metrics: http://localhost:9090"
echo ""
echo "📋 Next Steps:"
echo "   1. Update .env with your API keys"
echo "   2. Visit http://localhost:3000 to access the platform"
echo "   3. Check docker-compose logs for any issues"
echo "   4. Read docs/README.md for detailed documentation"
echo ""
echo "🛠️ Useful Commands:"
echo "   View logs: docker-compose logs -f [service]"
echo "   Restart: docker-compose restart [service]"
echo "   Stop all: docker-compose down"
echo "   Update: git pull && docker-compose build && docker-compose up -d"
echo ""
echo "🚀 Happy building with lIAison!"
