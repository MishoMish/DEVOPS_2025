#!/bin/sh
# ===========================================
# CLEANUP SCRIPT - Kubernetes Resource Cleanup
# ===========================================
# 
# USE CASE: 
# - Removes all Kubernetes resources from a specified namespace
# - Used for cleaning up after development, testing, or demos
# - Interactive safety prompts to prevent accidental deletion
#
# WHEN TO USE:
# - After completing development work
# - Before redeploying fresh environments
# - During environment teardown
# - For demo cleanup after presentations
#
# REFERENCED IN:
# - README.md (project structure section)
# - validate.sh (as part of script validation)
#
# USAGE: ./scripts/cleanup.sh [namespace]
# EXAMPLE: ./scripts/cleanup.sh devops-demo
# ===========================================

NAMESPACE=${1:-devops-demo}

echo "Cleaning up resources in: $NAMESPACE"
echo ""

read -p "Are you sure you want to delete all resources in namespace '$NAMESPACE'? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Deleting resources..."

kubectl delete -f k8s/ingress.yaml --ignore-not-found=true
kubectl delete -f k8s/web-service.yaml --ignore-not-found=true
kubectl delete -f k8s/web-deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/api-service.yaml --ignore-not-found=true
kubectl delete -f k8s/api-deployment.yaml --ignore-not-found=true

echo ""
read -p "Do you want to delete the namespace '$NAMESPACE' as well? (yes/no): " DELETE_NS

if [ "$DELETE_NS" = "yes" ]; then
    kubectl delete namespace $NAMESPACE
    echo "Namespace deleted"
else
    echo "Namespace preserved"
fi

echo ""
echo "Cleanup complete!"
