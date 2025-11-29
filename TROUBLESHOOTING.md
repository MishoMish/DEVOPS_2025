# 🔧 Troubleshooting Guide

Common issues and their solutions when deploying the DevOps project.

## 🚨 Common Issues

### 1. Images Not Pulling (ImagePullBackOff)

**Symptom:**
```bash
kubectl get pods -n devops-demo
# NAME                           READY   STATUS             RESTARTS   AGE
# api-service-xxx                0/1     ImagePullBackOff   0          30s
```

**Cause:** Image doesn't exist in registry or placeholder not replaced

**Solution:**

```bash
# Option 1: Build and use local images
docker build -t api-service:local ./api-service
docker build -t web-service:local ./web-service

# For Minikube, load images
minikube image load api-service:local
minikube image load web-service:local

# Update deployments to use local images
kubectl set image deployment/api-service api=api-service:local -n devops-demo
kubectl set image deployment/web-service web=web-service:local -n devops-demo

# OR edit manifests before applying
sed -i 's|ghcr.io/YOUR_GITHUB_USERNAME/api-service:latest|api-service:local|g' k8s/api-deployment.yaml
sed -i 's|imagePullPolicy: Always|imagePullPolicy: Never|g' k8s/api-deployment.yaml
```

**Option 2: Push to your registry**
```bash
# Replace YOUR_GITHUB_USERNAME in all files
find k8s/ -type f -name "*.yaml" -exec sed -i 's/YOUR_GITHUB_USERNAME/your-actual-username/g' {} +

# Then push images (see below)
```

---

### 2. Ingress Not Working

**Symptom:** Can't access http://devops-demo.local

**Diagnosis:**
```bash
# Check ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress -n devops-demo
kubectl describe ingress devops-demo-ingress -n devops-demo
```

**Solutions:**

**A. Ingress controller not installed**
```bash
# For Minikube
minikube addons enable ingress

# For other K8s clusters
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

**B. DNS not configured**
```bash
# Get ingress IP
INGRESS_IP=$(minikube ip)
# Or
INGRESS_IP=$(kubectl get ingress -n devops-demo -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')

# Add to /etc/hosts
echo "$INGRESS_IP devops-demo.local" | sudo tee -a /etc/hosts

# Test
curl http://devops-demo.local
```

**C. Ingress class not matching**
```bash
# Check available ingress classes
kubectl get ingressclass

# Update ingress.yaml if needed
spec:
  ingressClassName: nginx  # or whatever is available
```

---

### 3. Pods Crash (CrashLoopBackOff)

**Symptom:**
```bash
kubectl get pods -n devops-demo
# NAME                           READY   STATUS             RESTARTS   AGE
# api-service-xxx                0/1     CrashLoopBackOff   3          2m
```

**Diagnosis:**
```bash
# Check logs
kubectl logs -n devops-demo <pod-name>

# Check previous logs if restarting
kubectl logs -n devops-demo <pod-name> --previous

# Describe pod
kubectl describe pod -n devops-demo <pod-name>
```

**Common Causes:**

**A. Missing dependencies**
```bash
# For API service - check package.json exists in image
# Rebuild with proper COPY commands
docker build -t api-service:local ./api-service
```

**B. Port mismatch**
```yaml
# Ensure containerPort matches application port
containers:
  - name: api
    ports:
      - containerPort: 3000  # Must match PORT in code
    env:
      - name: PORT
        value: "3000"        # Must match
```

**C. Permission issues**
```bash
# Check securityContext
# If runAsUser: 1001, make sure app files are readable
# May need to adjust Dockerfile
```

---

### 4. Health Checks Failing

**Symptom:** Pods keep restarting or never become ready

**Diagnosis:**
```bash
kubectl describe pod -n devops-demo <pod-name>
# Look for:
# Liveness probe failed: ...
# Readiness probe failed: ...
```

**Solutions:**

**A. Increase initialDelaySeconds**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 15  # Increase if app takes time to start
  periodSeconds: 10
```

**B. Check endpoint exists**
```bash
# Port forward to pod
kubectl port-forward -n devops-demo <pod-name> 3000:3000

# Test health endpoint
curl http://localhost:3000/health
# Should return: {"status":"healthy"}
```

**C. Fix probe configuration**
```yaml
# Make sure port and path are correct
livenessProbe:
  httpGet:
    path: /health      # Correct path
    port: 3000         # Correct port number
```

---

### 5. Service Can't Connect to Pods

**Symptom:** Service exists but requests fail

**Diagnosis:**
```bash
# Check endpoints
kubectl get endpoints -n devops-demo

# Should show pod IPs
# NAME          ENDPOINTS
# api-service   10.244.0.5:3000,10.244.0.6:3000
```

**Solutions:**

**A. Label mismatch**
```yaml
# Service selector must match deployment labels
# In api-service.yaml:
selector:
  app: api-service

# In api-deployment.yaml:
template:
  metadata:
    labels:
      app: api-service  # Must match!
```

**B. Port mismatch**
```yaml
# Service port configuration
ports:
  - name: http
    port: 3000         # Service port
    targetPort: 3000   # Must match container port
```

---

### 6. Pipeline Failures in GitHub Actions

**A. npm ci fails**

**Error:** `Cannot read property 'version' of undefined`

**Solution:**
```bash
# Make sure package-lock.json exists
cd api-service
npm install  # This generates package-lock.json
git add package-lock.json
git commit -m "Add package-lock.json"
git push
```

**B. SAST scan fails**

**Error:** `Semgrep rules not found`

**Solution:**
```yaml
# In .github/workflows/ci.yaml
# Make sure config is properly formatted
config: >-
  p/security-audit
  p/secrets
  p/owasp-top-ten
  p/nodejs
```

**C. Docker build fails**

**Error:** `COPY failed: stat /var/lib/docker/.../src: no such file or directory`

**Solution:**
```dockerfile
# In Dockerfile, make sure paths are correct
# Check .dockerignore isn't excluding needed files
COPY package*.json ./
COPY src ./src  # Make sure src/ directory exists
```

**D. Trivy scan fails with timeout**

**Solution:**
```yaml
# Increase timeout or reduce scan scope
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    timeout: '10m0s'  # Increase timeout
    severity: 'CRITICAL,HIGH'  # Only scan high severity
```

**E. kubectl deployment fails**

**Error:** `error: You must be logged in to the server (Unauthorized)`

**Solution:**
```bash
# Make sure KUBE_CONFIG secret is set in GitHub
# Go to Settings → Secrets → Actions
# Add KUBE_CONFIG with base64 encoded kubeconfig
cat ~/.kube/config | base64 | pbcopy
```

---

### 7. Namespace Issues

**Symptom:** Resources not found

**Diagnosis:**
```bash
# Check namespace exists
kubectl get namespace devops-demo

# List resources in namespace
kubectl get all -n devops-demo
```

**Solution:**
```bash
# Create namespace first
kubectl apply -f k8s/namespace.yaml

# Or create manually
kubectl create namespace devops-demo

# Then apply other resources
kubectl apply -f k8s/
```

---

### 8. Resource Limits Preventing Scheduling

**Symptom:** Pods stuck in Pending state

**Diagnosis:**
```bash
kubectl describe pod -n devops-demo <pod-name>
# Look for: "Insufficient cpu" or "Insufficient memory"
```

**Solution:**

**A. Reduce resource requests**
```yaml
resources:
  requests:
    memory: "32Mi"   # Reduce from 64Mi
    cpu: "50m"       # Reduce from 100m
```

**B. Or add more nodes**
```bash
# For Minikube, increase resources
minikube stop
minikube start --cpus=4 --memory=4096
```

---

### 9. Web Service Can't Reach API Service

**Symptom:** Web page shows "Failed to connect to API"

**Diagnosis:**
```bash
# Check both services are running
kubectl get pods -n devops-demo

# Test API directly
kubectl port-forward -n devops-demo svc/api-service 3000:3000
curl http://localhost:3000/api/hello
```

**Solutions:**

**A. Nginx proxy configuration**
```nginx
# In web-service/nginx.conf
location /api/ {
    proxy_pass http://api-service:3000;  # Must match service name
    # ...
}
```

**B. Service name resolution**
```bash
# Services should be in same namespace
# DNS format: <service-name>.<namespace>.svc.cluster.local
# Or just: <service-name> if same namespace
```

**C. Check browser console**
```javascript
// In index.html, API call should be:
fetch('/api/hello')  // Relative URL, goes through ingress
// NOT
fetch('http://api-service:3000/api/hello')  // This won't work from browser
```

---

### 10. Permission Denied Errors

**Symptom:** Pods fail with permission errors in logs

**Diagnosis:**
```bash
kubectl logs -n devops-demo <pod-name>
# Look for: "EACCES: permission denied"
```

**Solution:**

**A. Fix file ownership in Dockerfile**
```dockerfile
# Make sure files are owned by non-root user
COPY --chown=nodejs:nodejs src ./src
RUN chown -R nodejs:nodejs /app

USER nodejs
```

**B. Adjust security context**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001  # Group ID for file access
```

---

## 🧰 Useful Debugging Commands

### Quick Status Check
```bash
# One-liner to check everything
kubectl get all,ingress -n devops-demo
```

### Watch Resources
```bash
# Watch pods in real-time
watch kubectl get pods -n devops-demo

# Or with auto-refresh
kubectl get pods -n devops-demo -w
```

### Get Events
```bash
# See recent events
kubectl get events -n devops-demo --sort-by='.lastTimestamp'

# Watch events
kubectl get events -n devops-demo -w
```

### Exec into Pod
```bash
# For debugging
kubectl exec -it -n devops-demo <pod-name> -- /bin/sh

# Test from inside pod
wget -O- http://localhost:3000/health
```

### Port Forwarding
```bash
# Access service locally
kubectl port-forward -n devops-demo svc/api-service 3000:3000
kubectl port-forward -n devops-demo svc/web-service 8080:80

# Access pod directly
kubectl port-forward -n devops-demo <pod-name> 3000:3000
```

### Resource Usage
```bash
# Check resource usage
kubectl top pods -n devops-demo
kubectl top nodes
```

### Delete and Recreate
```bash
# Sometimes the easiest fix
kubectl delete namespace devops-demo
kubectl apply -f k8s/
```

---

## 🔄 Complete Reset Procedure

If everything is broken, start fresh:

```bash
# 1. Delete everything
kubectl delete namespace devops-demo
minikube stop
minikube delete

# 2. Start clean
minikube start --driver=docker --cpus=4 --memory=4096
minikube addons enable ingress

# 3. Build images fresh
docker build -t api-service:local ./api-service
docker build -t web-service:local ./web-service

# 4. Load to Minikube
minikube image load api-service:local
minikube image load web-service:local

# 5. Update manifests
cd k8s
sed -i 's|ghcr.io/.*api-service.*|api-service:local|g' api-deployment.yaml
sed -i 's|ghcr.io/.*web-service.*|web-service:local|g' web-deployment.yaml
sed -i 's|imagePullPolicy: Always|imagePullPolicy: Never|g' *-deployment.yaml
cd ..

# 6. Deploy
kubectl apply -f k8s/

# 7. Wait
kubectl wait --for=condition=available --timeout=300s \
  deployment/api-service -n devops-demo
kubectl wait --for=condition=available --timeout=300s \
  deployment/web-service -n devops-demo

# 8. Configure DNS
echo "$(minikube ip) devops-demo.local" | sudo tee -a /etc/hosts

# 9. Test
curl http://devops-demo.local
open http://devops-demo.local
```

---

## 📞 Getting Help

If issues persist:

1. **Check logs systematically**
   ```bash
   kubectl logs -n devops-demo <pod-name>
   kubectl describe pod -n devops-demo <pod-name>
   kubectl get events -n devops-demo
   ```

2. **Validate YAML syntax**
   ```bash
   kubectl apply --dry-run=client -f k8s/
   ```

3. **Test components individually**
   - Build Docker images locally
   - Run containers with Docker
   - Test services with port-forward
   - Then test ingress

4. **Review documentation**
   - README.md for architecture
   - TESTING.md for test procedures
   - QUICKSTART.md for setup steps

5. **Search error messages**
   - Copy exact error
   - Google: "kubernetes [error message]"
   - Check Kubernetes documentation

Remember: Most issues are configuration mismatches. Double-check labels, ports, and image names!
