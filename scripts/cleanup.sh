#!/bin/sh
# Cleanup script for Kubernetes resources
# Usage: ./scripts/cleanup.sh [namespace]

NAMESPACE=${1:-devops-demo}

echo "🧹 Cleaning up Kubernetes resources"
echo "Namespace: $NAMESPACE"
echo "===================================="
echo ""

read -p "Are you sure you want to delete all resources in namespace '$NAMESPACE'? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "🗑️  Deleting resources..."

kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/web-service.yaml --ignore-not-found=true
kubectl delete -f k8s/web-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/api-service.yaml --ignore-not-found=true
kubectl delete -f k8s/api-deployment.yaml --ignore-not-found=true

echo ""
read -p "Do you want to delete the namespace '$NAMESPACE' as well? (yes/no): " DELETE_NS

if [ "$DELETE_NS" = "yes" ]; then
    kubectl delete namespace $NAMESPACE
    echo "✅ Namespace deleted"
else
    echo "ℹ️  Namespace preserved"
fi

echo ""
echo "✅ Cleanup complete!"
