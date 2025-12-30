# 🎮 Live Demo Commands

Quick reference commands for the live presentation demo.

## 🖥️ VM Connection

```bash
ssh misho@<ip>
export KUBECONFIG=$HOME/.kube/config
```

## 📊 Cluster Status Commands

### Show Nodes
```bash
kubectl get nodes -o wide
```

### Show All Resources in Namespace
```bash
kubectl get all -n devops-demo
```

### Show Pods with Details
```bash
kubectl get pods -n devops-demo -o wide
```

### Show Services
```bash
kubectl get svc -n devops-demo
```

### Show Ingress
```bash
kubectl get ingress -n devops-demo
```

### Show Deployments
```bash
kubectl get deployments -n devops-demo
```

## 🔍 Detailed Inspection

### Describe a Pod
```bash
kubectl describe pod -n devops-demo -l app=api-service
```

### Show Pod Logs
```bash
kubectl logs -n devops-demo -l app=api-service --tail=20
kubectl logs -n devops-demo -l app=web-service --tail=20
```

### Show Security Context
```bash
kubectl get pod -n devops-demo -l app=api-service -o yaml | grep -A 15 securityContext
```

### Show Rolling Update Strategy
```bash
kubectl get deployment api-service -n devops-demo -o yaml | grep -A 5 strategy
```

### Show Resource Limits
```bash
kubectl describe pod -n devops-demo -l app=api-service | grep -A 5 "Limits\|Requests"
```

## 🌐 Test Endpoints

### From VM
```bash
curl http://<ip>/
curl http://<ip>/api/hello
curl http://<ip>/health
```

### From Browser (any machine on network)
- Web UI: http://<ip>
- API: http://<ip>/api/hello

## 🔄 Demonstrate Rolling Update

### Scale Up
```bash
kubectl scale deployment api-service -n devops-demo --replicas=3
kubectl get pods -n devops-demo -w  # Watch pods scale
```

### Scale Down
```bash
kubectl scale deployment api-service -n devops-demo --replicas=2
```

### Trigger Rolling Update (restart pods)
```bash
kubectl rollout restart deployment/api-service -n devops-demo
kubectl rollout status deployment/api-service -n devops-demo
```

## 🐳 Docker Images

### List Images on VM
```bash
docker images | grep devops
```

### Show Images in K3s
```bash
sudo k3s ctr images list | grep devops
```

## 📈 GitHub Actions

### View Recent Workflow Runs
URL: https://github.com/MishoMish/DEVOPS_2025/actions

### Show Workflow File
```bash
cat .github/workflows/ci.yaml
```

## 🔒 Security Demo Commands

### Show Non-Root User in Pod
```bash
kubectl exec -n devops-demo -it $(kubectl get pod -n devops-demo -l app=api-service -o jsonpath='{.items[0].metadata.name}') -- whoami
# Should output: nodejs (not root)
```

### Show Dropped Capabilities
```bash
kubectl get pod -n devops-demo -l app=api-service -o jsonpath='{.items[0].spec.containers[0].securityContext}' | jq .
```

## 🏗️ Infrastructure as Code

### Show Terraform Config
```bash
cat terraform/main.tf
```

### Show K8s Manifests
```bash
ls -la k8s/
cat k8s/api-deployment.yaml
```

## 📋 Quick Health Check (All-in-One)

```bash
echo "=== Nodes ===" && kubectl get nodes && \
echo -e "\n=== Pods ===" && kubectl get pods -n devops-demo && \
echo -e "\n=== Services ===" && kubectl get svc -n devops-demo && \
echo -e "\n=== Ingress ===" && kubectl get ingress -n devops-demo && \
echo -e "\n=== API Test ===" && curl -s http://<ip>/api/hello && \
echo -e "\n=== Web Test ===" && curl -s http://<ip>/ | head -5
```
