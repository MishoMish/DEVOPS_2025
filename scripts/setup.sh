# Local Development Setup Script
# This script helps set up the local development environment

echo "🚀 DevOps Demo - Local Setup"
echo "=============================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting."; exit 1; }
echo "✅ Docker found: $(docker --version)"

command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting."; exit 1; }
echo "✅ kubectl found: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

command -v node >/dev/null 2>&1 || { echo "❌ Node.js is required but not installed. Aborting."; exit 1; }
echo "✅ Node.js found: $(node --version)"

echo ""
echo "📦 Installing API service dependencies..."
cd api-service
npm install
cd ..

echo ""
echo "🧪 Running tests..."
cd api-service
npm test
cd ..

echo ""
echo "🐳 Building Docker images..."
docker build -t api-service:local ./api-service
docker build -t web-service:local ./web-service

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Start your Kubernetes cluster (minikube start)"
echo "2. Enable ingress: minikube addons enable ingress"
echo "3. Deploy: kubectl apply -f k8s/"
echo "4. Add to /etc/hosts: \$(minikube ip) devops-demo.local"
echo "5. Visit: http://devops-demo.local"
