#!/bin/bash
# K8s Startup Script for DevOps Demo
# This script ensures all services are running after VM reboot
# Can be added to crontab: @reboot /path/to/k8s-startup.sh

set -e

NAMESPACE="devops-demo"
KUBECONFIG="${KUBECONFIG:-/home/misho/.kube/config}"
export KUBECONFIG

echo "🚀 Starting K8s services health check..."

# Wait for K3s to be ready
echo "⏳ Waiting for K3s to be ready..."
until kubectl cluster-info &>/dev/null; do
  echo "  Waiting for cluster..."
  sleep 5
done
echo "✅ Cluster is ready!"

# Ensure namespace exists
kubectl get namespace $NAMESPACE &>/dev/null || kubectl create namespace $NAMESPACE

# Apply secrets and configs first (required by other deployments)
echo "📦 Applying secrets and configs..."
kubectl apply -f /home/misho/actions-runner/_work/DEVOPS_2025/DEVOPS_2025/k8s/postgres-secret.yaml 2>/dev/null || true

# Check if PostgreSQL is running
echo "🗄️ Checking PostgreSQL..."
POSTGRES_STATUS=$(kubectl get pods -n $NAMESPACE -l app=postgres -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

if [ "$POSTGRES_STATUS" != "Running" ]; then
  echo "⚠️ PostgreSQL not running (status: $POSTGRES_STATUS). Restarting..."
  kubectl rollout restart deployment/postgres -n $NAMESPACE 2>/dev/null || true
  
  # Wait for PostgreSQL to be ready
  echo "⏳ Waiting for PostgreSQL to be ready..."
  kubectl rollout status deployment/postgres -n $NAMESPACE --timeout=120s || true
fi

# Check if API service is running
echo "🔌 Checking API service..."
API_STATUS=$(kubectl get pods -n $NAMESPACE -l app=api-service -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

if [ "$API_STATUS" != "Running" ]; then
  echo "⚠️ API service not running (status: $API_STATUS). Restarting..."
  kubectl rollout restart deployment/api-service -n $NAMESPACE 2>/dev/null || true
fi

# Check if Web service is running
echo "🌐 Checking Web service..."
WEB_STATUS=$(kubectl get pods -n $NAMESPACE -l app=web-service -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "NotFound")

if [ "$WEB_STATUS" != "Running" ]; then
  echo "⚠️ Web service not running (status: $WEB_STATUS). Restarting..."
  kubectl rollout restart deployment/web-service -n $NAMESPACE 2>/dev/null || true
fi

# Wait for all deployments
echo "⏳ Waiting for all deployments to be ready..."
kubectl rollout status deployment/postgres -n $NAMESPACE --timeout=120s 2>/dev/null || true
kubectl rollout status deployment/api-service -n $NAMESPACE --timeout=120s 2>/dev/null || true
kubectl rollout status deployment/web-service -n $NAMESPACE --timeout=120s 2>/dev/null || true

# Final status
echo ""
echo "📊 Final Status:"
echo "================"
kubectl get pods -n $NAMESPACE -o wide
echo ""
kubectl get services -n $NAMESPACE
echo ""

# Health check
echo "🧪 Running health checks..."
sleep 5

API_POD=$(kubectl get pods -n $NAMESPACE -l app=api-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$API_POD" ]; then
  HEALTH=$(kubectl exec -n $NAMESPACE $API_POD -- wget -qO- http://localhost:3000/health 2>/dev/null || echo "error")
  if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ API health check passed!"
  else
    echo "⚠️ API health check: $HEALTH"
  fi
fi

echo ""
echo "🎉 Startup check complete!"
