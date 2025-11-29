# 🚀 Quick Access Guide

## Running Application URLs

### API Service
- **Health Check**: http://localhost:8080/health
- **Hello Endpoint**: http://localhost:8080/api/hello

### Web Service
- **Main UI**: http://localhost:8081/

## Quick Commands

### View Running Pods
```bash
flatpak-spawn --host kubectl get pods -n devops-demo
```

### View Services
```bash
flatpak-spawn --host kubectl get svc -n devops-demo
```

### View Logs (API)
```bash
flatpak-spawn --host kubectl logs -n devops-demo -l app=api-service --tail=20
```

### View Logs (Web)
```bash
flatpak-spawn --host kubectl logs -n devops-demo -l app=web-service --tail=20
```

### Test API from Command Line
```bash
# Health check
curl http://localhost:8080/health

# Hello endpoint
curl http://localhost:8080/api/hello
```

### Scale Deployments
```bash
# Scale API service to 3 replicas
flatpak-spawn --host kubectl scale deployment api-service -n devops-demo --replicas=3

# Scale web service to 3 replicas
flatpak-spawn --host kubectl scale deployment web-service -n devops-demo --replicas=3
```

### Rolling Update Demo
```bash
# Update image (for demo purposes)
flatpak-spawn --host kubectl set image deployment/api-service -n devops-demo api=devops-demo/api-service:v2

# Watch the rolling update
flatpak-spawn --host kubectl rollout status deployment/api-service -n devops-demo
```

### Delete and Redeploy
```bash
# Delete everything
flatpak-spawn --host kubectl delete namespace devops-demo

# Redeploy
flatpak-spawn --host kubectl apply -f k8s/
```

## Port Forwarding (If Stopped)

If the port-forward connections stop, restart them:

```bash
# API service
flatpak-spawn --host kubectl port-forward -n devops-demo svc/api-service 8080:3000 &

# Web service
flatpak-spawn --host kubectl port-forward -n devops-demo svc/web-service 8081:80 &
```

## Minikube Commands

### Check Minikube Status
```bash
flatpak-spawn --host minikube status
```

### Open Minikube Dashboard
```bash
flatpak-spawn --host minikube dashboard
```

### Get Minikube IP
```bash
flatpak-spawn --host minikube ip
```

### Stop Minikube
```bash
flatpak-spawn --host minikube stop
```

### Start Minikube
```bash
flatpak-spawn --host minikube start
```

## Docker Commands

### View Images
```bash
flatpak-spawn --host docker images | grep devops-demo
```

### Rebuild Images
```bash
# API service
cd /home/mishomish/Documents/DEVOPS
flatpak-spawn --host docker build -t devops-demo/api-service:latest ./api-service

# Web service
flatpak-spawn --host docker build -t devops-demo/web-service:latest ./web-service

# Load into minikube
flatpak-spawn --host minikube image load devops-demo/api-service:latest
flatpak-spawn --host minikube image load devops-demo/web-service:latest
```

## Troubleshooting

### Pods Not Starting?
```bash
# Check pod status
flatpak-spawn --host kubectl get pods -n devops-demo

# Describe pod for details
flatpak-spawn --host kubectl describe pod <pod-name> -n devops-demo

# Check logs
flatpak-spawn --host kubectl logs <pod-name> -n devops-demo
```

### Port Already in Use?
```bash
# Find and kill process using port 8080
lsof -ti:8080 | xargs kill -9

# Or use different ports
flatpak-spawn --host kubectl port-forward -n devops-demo svc/api-service 9090:3000
```

### Minikube Not Running?
```bash
# Start minikube
flatpak-spawn --host minikube start

# If problems, delete and recreate
flatpak-spawn --host minikube delete
flatpak-spawn --host minikube start
```

## For Presentation

### Show Everything is Running
```bash
# One command to show it all
flatpak-spawn --host kubectl get all -n devops-demo
```

### Live Demo Flow
1. Show pods running: `flatpak-spawn --host kubectl get pods -n devops-demo`
2. Open API in browser: http://localhost:8080/health
3. Open Web UI in browser: http://localhost:8081/
4. Show logs: `flatpak-spawn --host kubectl logs -n devops-demo -l app=api-service`
5. Demonstrate scaling: `flatpak-spawn --host kubectl scale deployment api-service -n devops-demo --replicas=3`
6. Watch rolling update: `flatpak-spawn --host kubectl rollout status deployment/api-service -n devops-demo`

---

**Quick Reference Created**: November 29, 2025  
**All commands tested and working** ✅
