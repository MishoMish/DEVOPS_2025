#!/bin/sh
# ===========================================
# DEPLOYMENT SCRIPT - Kubernetes Deployment Automation
# ===========================================
# 
# USE CASE:
# - Automated deployment of the complete application stack to Kubernetes
# - Handles namespace creation, service deployment, and readiness checks
# - Production-ready deployment with connectivity validation
#
# WHEN TO USE:
# - Initial deployment to a new environment
# - Redeployment after infrastructure changes
# - Automated deployment from CI/CD pipelines
# - Manual deployments during development
#
# REFERENCED IN:
# - README.md (project structure section)
# - validate.sh (as part of script validation)
# - CI/CD workflows (automated deployment)
#
# USAGE: ./scripts/deploy.sh [namespace]
# EXAMPLE: ./scripts/deploy.sh production
# ===========================================

NAMESPACE=${1:-devops-demo}

echo "Deploying to namespace: $NAMESPACE"
echo ""

# Check if kubectl is available
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl is not installed"
    exit 1
fi

# Check cluster connectivity
echo "Checking cluster connectivity..."
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi
echo "Connected to cluster"
echo ""

# Create namespace if it doesn't exist
echo "Creating namespace: $NAMESPACE"
kubectl apply -f k8s/namespace.yaml

echo ""
echo "Deploying API service..."
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/api-service.yaml

echo ""
echo "Deploying Web service..."
kubectl apply -f k8s/web-deployment.yaml
kubectl apply -f k8s/web-service.yaml

echo ""
echo "Deploying Ingress..."
kubectl apply -f k8s/ingress.yaml

echo ""
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/api-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/web-service -n $NAMESPACE

echo ""
echo "Deployment complete!"
echo ""
echo "Current status:"
kubectl get all -n $NAMESPACE

echo ""
echo "Access the application:"
echo "   Add to /etc/hosts: \$(minikube ip) devops-demo.local"
echo "   Then visit: http://devops-demo.local"
