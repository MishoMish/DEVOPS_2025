# Testing Guide - DevOps Final Project

This document provides comprehensive testing instructions for environments with and without Docker/Kubernetes.

## 📋 Testing Checklist

- [ ] Code syntax validation
- [ ] API service logic
- [ ] Web service HTML
- [ ] Kubernetes manifests validation
- [ ] CI/CD workflow validation
- [ ] Security configurations
- [ ] Documentation completeness

## 🧪 Testing Without Docker/Kubernetes

Since this is a demonstration project, you can validate it without running containers:

### 1. Validate File Structure

```bash
cd /home/mishomish/Documents/DEVOPS

# Check all files exist
ls -R

# Expected structure:
# - api-service/ (src, tests, Dockerfile, package.json)
# - web-service/ (index.html, nginx.conf, Dockerfile)
# - k8s/ (6 YAML files)
# - terraform/ (main.tf, outputs.tf)
# - .github/workflows/ (ci.yaml)
# - scripts/ (4 shell scripts)
```

### 2. Validate JavaScript Syntax

```bash
# Check API service syntax (if Node.js available)
cd api-service
node -c src/index.js
node -c tests/health.test.js

# Or manually review the code
cat src/index.js
cat tests/health.test.js
```

### 3. Validate HTML

```bash
cd web-service

# Check HTML is well-formed
cat index.html | grep -E '<html|</html>|<head|</head>|<body|</body>'

# Verify JavaScript fetch logic exists
cat index.html | grep -A 5 "fetch('/api/hello')"
```

### 4. Validate Kubernetes Manifests

```bash
cd k8s

# Check YAML syntax (if available)
which yamllint && yamllint *.yaml

# Validate with kubectl (if available)
kubectl apply --dry-run=client -f .

# Or manually check each file
for file in *.yaml; do
  echo "=== $file ==="
  cat "$file"
  echo ""
done
```

### 5. Validate Dockerfiles

```bash
# Check API Dockerfile
cat api-service/Dockerfile

# Verify:
# - Multi-stage build (FROM ... AS builder)
# - Non-root user
# - HEALTHCHECK
# - Security best practices

# Check Web Dockerfile
cat web-service/Dockerfile

# Verify similar patterns
```

### 6. Validate CI/CD Pipeline

```bash
# Check workflow syntax
cat .github/workflows/ci.yaml

# Verify all jobs exist:
# 1. test-api
# 2. sast-scan
# 3. build-images
# 4. scan-images
# 5. deploy-kubernetes
# 6. notify
```

## 🚀 Testing WITH Docker (Recommended)

If you have Docker installed:

### 1. Build Images Locally

```bash
cd /home/mishomish/Documents/DEVOPS

# Build API service
docker build -t api-service:test ./api-service

# Build Web service
docker build -t web-service:test ./web-service

# Check images
docker images | grep -E 'api-service|web-service'
```

### 2. Run API Service Locally

```bash
# Run API container
docker run -d --name api-test -p 3000:3000 api-service:test

# Test endpoints
curl http://localhost:3000/health
# Expected: {"status":"healthy"}

curl http://localhost:3000/api/hello
# Expected: {"message":"Hello from the API 🎉"}

# Check logs
docker logs api-test

# Stop container
docker stop api-test
docker rm api-test
```

### 3. Run Web Service Locally

```bash
# Run Web container
docker run -d --name web-test -p 8080:80 web-service:test

# Test in browser
# Visit: http://localhost:8080

# Or use curl
curl http://localhost:8080/health
# Expected: healthy

curl -I http://localhost:8080/
# Expected: 200 OK

# Stop container
docker stop web-test
docker rm web-test
```

### 4. Run Both with Docker Compose

Create `docker-compose.test.yaml`:

```yaml
version: '3.8'
services:
  api-service:
    build: ./api-service
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 10s
      timeout: 3s
      retries: 3

  web-service:
    build: ./web-service
    ports:
      - "8080:80"
    depends_on:
      - api-service
    environment:
      - API_SERVICE_URL=http://api-service:3000
```

Run:
```bash
docker-compose -f docker-compose.test.yaml up -d
docker-compose -f docker-compose.test.yaml ps
docker-compose -f docker-compose.test.yaml down
```

## ☸️ Testing WITH Kubernetes (Full Test)

### 1. Setup Local Cluster

```bash
# Option A: Minikube
minikube start --driver=docker
minikube addons enable ingress

# Option B: Docker Desktop
# Enable Kubernetes in Docker Desktop settings

# Option C: Kind
kind create cluster --name devops-demo
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
```

### 2. Prepare Images for Local Testing

Since the manifests reference `ghcr.io/YOUR_GITHUB_USERNAME/*`, you need to either:

**Option A: Build and load locally**

```bash
# Build images
docker build -t api-service:local ./api-service
docker build -t web-service:local ./web-service

# Load to Minikube
minikube image load api-service:local
minikube image load web-service:local

# Update manifests to use local images
cd k8s
sed -i.bak 's|ghcr.io/YOUR_GITHUB_USERNAME/api-service:latest|api-service:local|g' api-deployment.yaml
sed -i.bak 's|ghcr.io/YOUR_GITHUB_USERNAME/web-service:latest|web-service:local|g' web-deployment.yaml
sed -i.bak 's|imagePullPolicy: Always|imagePullPolicy: Never|g' *-deployment.yaml
```

**Option B: Push to your own registry**

```bash
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Tag images
docker tag api-service:local ghcr.io/YOUR_USERNAME/api-service:latest
docker tag web-service:local ghcr.io/YOUR_USERNAME/web-service:latest

# Push images
docker push ghcr.io/YOUR_USERNAME/api-service:latest
docker push ghcr.io/YOUR_USERNAME/web-service:latest

# Update manifests
sed -i 's|YOUR_GITHUB_USERNAME|YOUR_USERNAME|g' k8s/*.yaml
```

### 3. Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/

# Watch deployment
kubectl get all -n devops-demo -w

# Wait for rollout
kubectl rollout status deployment/api-service -n devops-demo
kubectl rollout status deployment/web-service -n devops-demo
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n devops-demo

# Expected output:
# NAME                           READY   STATUS    RESTARTS   AGE
# api-service-xxx-yyy            1/1     Running   0          30s
# api-service-xxx-zzz            1/1     Running   0          30s
# web-service-xxx-yyy            1/1     Running   0          30s
# web-service-xxx-zzz            1/1     Running   0          30s

# Check services
kubectl get svc -n devops-demo

# Check ingress
kubectl get ingress -n devops-demo
```

### 5. Test Endpoints

```bash
# Port forward API service
kubectl port-forward -n devops-demo svc/api-service 3000:3000 &

# Test API
curl http://localhost:3000/health
curl http://localhost:3000/api/hello

# Port forward Web service
kubectl port-forward -n devops-demo svc/web-service 8080:80 &

# Test Web
curl http://localhost:8080/health
curl http://localhost:8080/
```

### 6. Test Ingress

```bash
# Get ingress IP
minikube ip
# or
kubectl get ingress -n devops-demo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}'

# Add to /etc/hosts
echo "$(minikube ip) devops-demo.local" | sudo tee -a /etc/hosts

# Test in browser
open http://devops-demo.local

# Or with curl
curl http://devops-demo.local
curl http://devops-demo.local/api/hello
```

### 7. View Logs

```bash
# API logs
kubectl logs -n devops-demo deployment/api-service --tail=50

# Web logs
kubectl logs -n devops-demo deployment/web-service --tail=50

# Follow logs
kubectl logs -f -n devops-demo deployment/api-service
```

### 8. Test Health Probes

```bash
# Describe pod to see probe results
kubectl describe pod -n devops-demo -l app=api-service

# Look for:
# Liveness:  http-get http://:3000/health
# Readiness: http-get http://:3000/health
```

## 🔒 Security Testing

### 1. Test SAST Locally (if Semgrep installed)

```bash
# Install Semgrep
pip install semgrep

# Run SAST scan
cd /home/mishomish/Documents/DEVOPS
semgrep --config=p/security-audit --config=p/nodejs api-service/

# Check for:
# - No hardcoded secrets
# - No SQL injection vulnerabilities
# - No command injection
```

### 2. Test Container Scanning (if Trivy installed)

```bash
# Install Trivy
brew install aquasecurity/trivy/trivy

# Scan images
trivy image api-service:local
trivy image web-service:local

# Check for vulnerabilities
trivy image --severity HIGH,CRITICAL api-service:local
```

### 3. Verify Security Contexts

```bash
# Check pod security
kubectl get pod -n devops-demo -l app=api-service -o yaml | grep -A 10 securityContext

# Verify:
# - runAsNonRoot: true
# - runAsUser: 1001
# - allowPrivilegeEscalation: false
# - capabilities dropped
```

## 📊 Performance Testing

### 1. Load Test API

```bash
# Simple load test with curl
for i in {1..100}; do
  curl -s http://localhost:3000/api/hello > /dev/null &
done
wait

# With Apache Bench (if installed)
ab -n 1000 -c 10 http://localhost:3000/api/hello

# Monitor resources
kubectl top pods -n devops-demo
```

### 2. Test Scaling

```bash
# Scale up
kubectl scale deployment/api-service -n devops-demo --replicas=5

# Watch scaling
kubectl get pods -n devops-demo -w

# Scale down
kubectl scale deployment/api-service -n devops-demo --replicas=2
```

### 3. Test Rolling Updates

```bash
# Trigger update (change image tag)
kubectl set image deployment/api-service -n devops-demo api=api-service:v2

# Watch rollout
kubectl rollout status deployment/api-service -n devops-demo

# Rollback if needed
kubectl rollout undo deployment/api-service -n devops-demo
```

## 🧹 Cleanup

```bash
# Delete all resources
kubectl delete namespace devops-demo

# Or use cleanup script
./scripts/cleanup.sh

# Stop Minikube (if used)
minikube stop
minikube delete
```

## ✅ Validation Checklist for Presentation

Before your presentation, verify:

- [ ] All files are present and properly structured
- [ ] Dockerfiles build successfully
- [ ] Kubernetes manifests are valid
- [ ] CI/CD workflow is syntactically correct
- [ ] Documentation is comprehensive
- [ ] README explains the architecture clearly
- [ ] Deep-dive topic (security) is well documented
- [ ] Scripts are executable and functional
- [ ] No hardcoded secrets or credentials
- [ ] Image names are placeholders (YOUR_GITHUB_USERNAME)

## 🎯 Quick Validation Script

Run this to validate basic structure:

```bash
#!/bin/bash
cd /home/mishomish/Documents/DEVOPS

echo "🔍 Validating project structure..."

# Check directories
for dir in api-service web-service k8s terraform .github/workflows scripts; do
  if [ -d "$dir" ]; then
    echo "✅ $dir exists"
  else
    echo "❌ $dir missing"
  fi
done

# Check key files
for file in README.md QUICKSTART.md ARCHITECTURE.md .gitignore; do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file missing"
  fi
done

# Check API service files
echo ""
echo "📦 API Service:"
ls -1 api-service/ | sed 's/^/  - /'

# Check Web service files
echo ""
echo "🌐 Web Service:"
ls -1 web-service/ | sed 's/^/  - /'

# Check K8s manifests
echo ""
echo "☸️  Kubernetes Manifests:"
ls -1 k8s/*.yaml | sed 's/^/  - /'

echo ""
echo "✅ Validation complete!"
```

Save and run:
```bash
chmod +x validate.sh
./validate.sh
```

## 📝 Manual Testing Notes

When you can't run the actual containers, validate:

1. **Code Quality**: Read through all source files
2. **Logic**: Verify API endpoints match documentation
3. **Configuration**: Check all YAML is properly indented
4. **Security**: Review Dockerfiles for best practices
5. **Documentation**: Ensure README covers all topics
6. **CI/CD**: Verify pipeline has all required stages
7. **Completeness**: All 7+ DevOps topics are covered

## 🎓 For Your Presentation

Focus on:

1. **Architecture**: Show the diagrams in ARCHITECTURE.md
2. **Pipeline**: Walk through .github/workflows/ci.yaml
3. **Security**: Explain SAST and Trivy scanning (deep dive)
4. **Kubernetes**: Show manifests and explain rolling updates
5. **IaC**: Demonstrate Terraform configuration
6. **Documentation**: Highlight comprehensive README
7. **Future**: Discuss improvements from README

Even without running the actual deployment, you can demonstrate thorough understanding of:
- DevOps principles
- CI/CD automation
- Security best practices
- Kubernetes concepts
- Infrastructure as Code
- Complete SDLC coverage
