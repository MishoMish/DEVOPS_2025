# 🧪 Testing Guide

Quick reference for testing the project locally and in CI/CD.

## Local Testing

### Prerequisites

```bash
# Required
docker --version      # 20.x or higher
kubectl version       # 1.25 or higher
minikube version      # or Docker Desktop with K8s

# Optional (for API development)
node --version        # 18.x
```

### 1. Test API Service (without Docker)

```bash
cd api-service
npm install
npm run lint          # Check code style
npm test              # Run unit tests
npm start             # Start server on :3000
```

Test endpoints:
```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/hello
```

### 2. Build Docker Images

```bash
# Build both services
docker build -t devops-demo/api-service:latest ./api-service
docker build -t devops-demo/web-service:latest ./web-service

# Verify images
docker images | grep devops-demo
```

### 3. Test with Docker Compose

```bash
docker-compose up -d
curl http://localhost:3000/api/hello   # API
curl http://localhost:8080             # Web
docker-compose down
```

### 4. Deploy to Kubernetes (Minikube)

```bash
# Start cluster
minikube start
minikube addons enable ingress

# Load local images
minikube image load devops-demo/api-service:latest
minikube image load devops-demo/web-service:latest

# Deploy
kubectl apply -f k8s/

# Verify
kubectl get pods -n devops-demo
kubectl get svc -n devops-demo

# Port forward to test
kubectl port-forward -n devops-demo svc/api-service 3000:3000 &
curl http://localhost:3000/api/hello
```

### 5. Test Security Scanning

```bash
# SAST with Semgrep
pip install semgrep
semgrep --config=p/security-audit --config=p/nodejs api-service/

# Container scanning with Trivy
brew install trivy  # or apt-get install trivy
trivy image devops-demo/api-service:latest
```

## CI/CD Testing

### GitHub Actions Workflow

The pipeline runs automatically on:
- Push to `main` or `master` branch
- Pull requests to `main`

### Jobs Overview

| Job | What it does | Duration |
|-----|--------------|----------|
| `test-api` | Lint + Unit tests | ~1 min |
| `sast-scan` | Semgrep security scan | ~30s |
| `build-images` | Build & push Docker images | ~2 min |
| `scan-images` | Trivy vulnerability scan | ~1 min |
| `deploy-kubernetes` | Deploy to K8s cluster | ~2 min |
| `notify` | Create deployment summary | ~10s |

### Required Secrets

For full pipeline functionality, configure in GitHub Settings → Secrets:

| Secret | Purpose | Required |
|--------|---------|----------|
| `GITHUB_TOKEN` | Push images to GHCR | Auto-provided |
| `KUBE_CONFIG` | Deploy to K8s cluster | For deployment |

### Testing Without Kubernetes Deployment

The CI jobs (test, lint, SAST, build, scan) work without any secrets. Only the `deploy-kubernetes` job requires cluster access.

## Validation Checklist

```bash
# ✅ API tests pass
cd api-service && npm test

# ✅ Lint passes
npm run lint

# ✅ Docker builds succeed
docker build -t test ./api-service
docker build -t test ./web-service

# ✅ K8s manifests are valid
kubectl apply --dry-run=client -f k8s/

# ✅ Terraform is valid
cd terraform && terraform validate
```

## Troubleshooting

### ImagePullBackOff Error

```bash
# For Minikube - use local images
minikube image load devops-demo/api-service:latest
kubectl set image deployment/api-service api=devops-demo/api-service:latest -n devops-demo
```

### Ingress Not Working

```bash
# Enable ingress addon
minikube addons enable ingress

# Add to /etc/hosts
echo "$(minikube ip) devops-demo.local" | sudo tee -a /etc/hosts
```

### Pods CrashLoopBackOff

```bash
# Check logs
kubectl logs -n devops-demo -l app=api-service

# Check events
kubectl get events -n devops-demo --sort-by='.lastTimestamp'
```

### Port Already in Use

```bash
# Find and kill process
lsof -i :3000
kill -9 <PID>
```
