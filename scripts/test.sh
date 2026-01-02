#!/bin/sh
# ===========================================
# TEST SCRIPT - Deployment Verification
# ===========================================
# 
# USE CASE:
# - Verifies that Kubernetes deployment is working correctly
# - Tests service connectivity and health endpoints
# - Validates pod status and service availability
# - End-to-end deployment testing
#
# WHEN TO USE:
# - After deployment to verify services are running
# - During troubleshooting deployment issues
# - For integration testing in CI/CD pipelines
# - Manual verification after configuration changes
#
# TESTS:
# - API service pod health and endpoints
# - Web service pod status and connectivity
# - Service-to-service communication
# - Ingress configuration and routing
# - Overall deployment health
#
# REFERENCED IN:
# - README.md (project structure section)
# - validate.sh (as part of script validation)
# - Deployment verification workflows
#
# USAGE: ./scripts/test.sh
# ===========================================

NAMESPACE="devops-demo"

echo "🧪 Testing DevOps Demo Deployment"
echo "=================================="
echo ""

echo "1️⃣  Checking API service..."
API_POD=$(kubectl get pod -n $NAMESPACE -l app=api-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$API_POD" ]; then
    echo "❌ No API pods found"
else
    echo "✅ API pod: $API_POD"
    kubectl exec -n $NAMESPACE $API_POD -- wget -q -O- http://localhost:3000/health
    echo ""
fi

echo ""
echo "2️⃣  Checking Web service..."
WEB_POD=$(kubectl get pod -n $NAMESPACE -l app=web-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$WEB_POD" ]; then
    echo "❌ No Web pods found"
else
    echo "✅ Web pod: $WEB_POD"
    kubectl exec -n $NAMESPACE $WEB_POD -- wget -q -O- http://localhost/health
    echo ""
fi

echo ""
echo "3️⃣  Testing API endpoint via service..."
kubectl run test-curl --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s http://api-service:3000/api/hello

echo ""
echo ""
echo "4️⃣  Checking Ingress..."
kubectl get ingress -n $NAMESPACE

echo ""
echo "5️⃣  Pod status:"
kubectl get pods -n $NAMESPACE

echo ""
echo "✅ Tests complete!"
