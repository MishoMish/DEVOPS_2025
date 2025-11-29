# QUICK START GUIDE

## Prerequisites Checklist

- [ ] Docker installed and running
- [ ] Kubernetes cluster (Minikube/Docker Desktop/Kind)
- [ ] kubectl configured
- [ ] Node.js 18+ (for local testing)

## 🚀 Quick Start (5 minutes)

### 1. Setup Local Environment

```bash
# Run setup script
./scripts/setup.sh
```

### 2. Start Kubernetes Cluster

```bash
# If using Minikube
minikube start
minikube addons enable ingress

# If using Docker Desktop
# Enable Kubernetes in Docker Desktop settings
```

### 3. Deploy Application

```bash
# Deploy all resources
./scripts/deploy.sh

# Or manually
kubectl apply -f k8s/
```

### 4. Configure Local DNS

```bash
# Get cluster IP
minikube ip  # or use 127.0.0.1 for Docker Desktop

# Add to /etc/hosts (macOS/Linux)
echo "$(minikube ip) devops-demo.local" | sudo tee -a /etc/hosts

# For Windows, edit C:\Windows\System32\drivers\etc\hosts
```

### 5. Access Application

Open browser: http://devops-demo.local

## 🧪 Run Tests

```bash
# Run verification tests
./scripts/test.sh

# Or manually test API
kubectl port-forward -n devops-demo svc/api-service 3000:3000
curl http://localhost:3000/api/hello
```

## 🔧 Troubleshooting

### Pods not starting?

```bash
kubectl get pods -n devops-demo
kubectl describe pod -n devops-demo <pod-name>
kubectl logs -n devops-demo <pod-name>
```

### Ingress not working?

```bash
# Check ingress controller is running
kubectl get pods -n ingress-nginx

# Enable Minikube ingress addon
minikube addons enable ingress

# Wait for ingress controller
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

### Can't pull images?

The manifests use placeholder image names. Either:

1. **Use locally built images:**
   ```bash
   # Build images
   docker build -t api-service:local ./api-service
   docker build -t web-service:local ./web-service
   
   # If using Minikube, load images
   minikube image load api-service:local
   minikube image load web-service:local
   
   # Update manifests to use local images
   sed -i 's|ghcr.io/YOUR_GITHUB_USERNAME/api-service:latest|api-service:local|g' k8s/api-deployment.yaml
   sed -i 's|ghcr.io/YOUR_GITHUB_USERNAME/web-service:latest|web-service:local|g' k8s/web-deployment.yaml
   sed -i 's|imagePullPolicy: Always|imagePullPolicy: Never|g' k8s/*-deployment.yaml
   ```

2. **Or push to your own registry:**
   ```bash
   # Update YOUR_GITHUB_USERNAME in k8s/*.yaml files
   # Then run CI/CD pipeline to build and push images
   ```

## 🧹 Cleanup

```bash
# Remove all resources
./scripts/cleanup.sh

# Or manually
kubectl delete namespace devops-demo
```

## 📝 Next Steps

1. **Set up CI/CD:**
   - Fork this repo
   - Configure GitHub secrets (see README.md)
   - Push changes to trigger pipeline

2. **Customize:**
   - Modify API endpoints in `api-service/src/index.js`
   - Update web UI in `web-service/index.html`
   - Adjust K8s resources in `k8s/`

3. **Monitor:**
   ```bash
   # Watch pods
   watch kubectl get pods -n devops-demo
   
   # View logs
   kubectl logs -f -n devops-demo deployment/api-service
   
   # Check resource usage
   kubectl top pods -n devops-demo
   ```

## 📚 Full Documentation

See [README.md](README.md) for comprehensive documentation including:
- Detailed architecture
- CI/CD pipeline explanation
- Security deep-dive
- Advanced deployment options
- Future improvements
