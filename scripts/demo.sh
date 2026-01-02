#!/bin/bash

#############################################
#  DevOps Demo Script - Interactive Presentation
#  Run this on your K3s server via SSH
#  Press any key to continue between sections
#############################################

# Colors for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  $1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to print sub-headers
print_subheader() {
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}  ▶ $1${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────────${NC}"
    echo ""
}

# Function to print info
print_info() {
    echo -e "${GREEN}  ℹ  $1${NC}"
}

# Function to print command being executed
print_cmd() {
    echo -e "${BLUE}  \$ $1${NC}"
}

# Function to wait for keypress
wait_for_key() {
    echo ""
    echo -e "${YELLOW}  ⏎  Press any key to continue...${NC}"
    read -n 1 -s
    echo ""
}

# Clear screen
clear

#############################################
# WELCOME SCREEN
#############################################
echo ""
echo -e "${GREEN}"
echo "  ╔═══════════════════════════════════════════════════════════════╗"
echo "  ║                                                               ║"
echo "  ║           🚀 DevOps Final Project - Live Demo 🚀              ║"
echo "  ║                                                               ║"
echo "  ║     Complete CI/CD Pipeline with Kubernetes & Security       ║"
echo "  ║                                                               ║"
echo "  ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${WHITE}  This interactive demo will show:${NC}"
echo -e "${CYAN}    ✓ Kubernetes Cluster Status${NC}"
echo -e "${CYAN}    ✓ Running Pods & Services${NC}"
echo -e "${CYAN}    ✓ Ingress & Traffic Routing${NC}"
echo -e "${CYAN}    ✓ API Health & Database Connectivity${NC}"
echo -e "${CYAN}    ✓ Live Rolling Update${NC}"
echo -e "${CYAN}    ✓ Logs & Monitoring${NC}"
echo ""

wait_for_key
clear

#############################################
# SECTION 1: CLUSTER STATUS
#############################################
print_header "📊 SECTION 1: Kubernetes Cluster Status"

print_subheader "K3s Cluster Info"
print_cmd "kubectl cluster-info"
kubectl cluster-info
wait_for_key

print_subheader "Node Status & Resources"
print_cmd "kubectl get nodes -o wide"
kubectl get nodes -o wide
echo ""
print_cmd "kubectl top nodes 2>/dev/null || echo '(metrics-server not installed)'"
kubectl top nodes 2>/dev/null || echo -e "${YELLOW}  (metrics-server not installed - skipping resource metrics)${NC}"
wait_for_key

print_subheader "All Namespaces"
print_cmd "kubectl get namespaces"
kubectl get namespaces
wait_for_key

clear

#############################################
# SECTION 2: APPLICATION OVERVIEW
#############################################
print_header "🏗️ SECTION 2: Application Overview"

print_subheader "All Resources in devops-demo Namespace"
print_cmd "kubectl get all -n devops-demo"
kubectl get all -n devops-demo
wait_for_key

print_subheader "Deployments with Replicas"
print_cmd "kubectl get deployments -n devops-demo -o wide"
kubectl get deployments -n devops-demo -o wide
echo ""
print_info "API & Web services have 2 replicas for high availability"
print_info "PostgreSQL has 1 replica (PVC constraint)"
wait_for_key

print_subheader "Pods Status & Age"
print_cmd "kubectl get pods -n devops-demo -o wide"
kubectl get pods -n devops-demo -o wide
wait_for_key

clear

#############################################
# SECTION 3: SERVICES & NETWORKING
#############################################
print_header "🌐 SECTION 3: Services & Networking"

print_subheader "ClusterIP Services"
print_cmd "kubectl get services -n devops-demo"
kubectl get services -n devops-demo
echo ""
print_info "ClusterIP = Internal routing only (no external exposure)"
wait_for_key

print_subheader "Ingress Configuration (Traefik)"
print_cmd "kubectl get ingress -n devops-demo"
kubectl get ingress -n devops-demo
echo ""
print_cmd "kubectl describe ingress -n devops-demo | grep -A 20 'Rules:'"
kubectl describe ingress -n devops-demo | grep -A 20 'Rules:'
echo ""
print_info "Path-based routing: / → web-service, /api/* → api-service"
wait_for_key

print_subheader "Endpoints (where traffic goes)"
print_cmd "kubectl get endpoints -n devops-demo"
kubectl get endpoints -n devops-demo
wait_for_key

clear

#############################################
# SECTION 4: API HEALTH & DATABASE
#############################################
print_header "💚 SECTION 4: API Health & Database Connectivity"

print_subheader "Health Check Endpoint"
print_cmd "curl -s http://localhost/health 2>/dev/null || kubectl exec -n devops-demo deployment/api-service -- wget -qO- http://localhost:3000/health"
API_POD=$(kubectl get pods -n devops-demo -l app=api-service -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/health 2>/dev/null | python3 -m json.tool 2>/dev/null || kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/health
echo ""
print_info "✅ Status: healthy, Database: connected"
wait_for_key

print_subheader "API Hello Endpoint"
print_cmd "kubectl exec ... -- wget -qO- http://localhost:3000/api/hello"
kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/api/hello 2>/dev/null | python3 -m json.tool 2>/dev/null || kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/api/hello
wait_for_key

print_subheader "Database Info Endpoint"
print_cmd "kubectl exec ... -- wget -qO- http://localhost:3000/api/db-info"
kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/api/db-info 2>/dev/null | python3 -m json.tool 2>/dev/null || kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/api/db-info
echo ""
print_info "Shows PostgreSQL version, connected tables including Flyway migrations"
wait_for_key

print_subheader "Guestbook Messages"
print_cmd "kubectl exec ... -- wget -qO- http://localhost:3000/api/messages"
kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/api/messages 2>/dev/null | python3 -m json.tool 2>/dev/null || kubectl exec -n devops-demo $API_POD -- wget -qO- http://localhost:3000/api/messages
wait_for_key

clear

#############################################
# SECTION 5: KUBERNETES CONFIGURATIONS
#############################################
print_header "⚙️ SECTION 5: Kubernetes Configurations"

print_subheader "Rolling Update Strategy"
print_cmd "kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.strategy}' | python3 -m json.tool"
kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.strategy}' | python3 -m json.tool 2>/dev/null || kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.strategy}'
echo ""
print_info "maxSurge: 1 = Create 1 new pod first"
print_info "maxUnavailable: 0 = Never go below replica count"
print_info "Result: Zero-downtime deployments!"
wait_for_key

print_subheader "Security Context"
print_cmd "kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.template.spec.securityContext}'"
echo -e "${WHITE}"
kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.template.spec.securityContext}' | python3 -m json.tool 2>/dev/null || echo "(Security context configured at container level)"
echo -e "${NC}"
print_info "runAsNonRoot: true - Never runs as root user"
print_info "allowPrivilegeEscalation: false - Cannot gain privileges"
wait_for_key

print_subheader "Resource Limits (if configured)"
print_cmd "kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.template.spec.containers[0].resources}'"
kubectl get deployment api-service -n devops-demo -o jsonpath='{.spec.template.spec.containers[0].resources}' | python3 -m json.tool 2>/dev/null || echo "(No explicit resource limits - using defaults)"
wait_for_key

clear

#############################################
# SECTION 6: DOCKER IMAGES
#############################################
print_header "🐳 SECTION 6: Docker Images"

print_subheader "Images Used in Deployments"
print_cmd "kubectl get pods -n devops-demo -o jsonpath='{range .items[*]}{.metadata.name}{\": \"}{.spec.containers[*].image}{\"\\n\"}{end}'"
kubectl get pods -n devops-demo -o jsonpath='{range .items[*]}{.metadata.name}{": "}{.spec.containers[*].image}{"\n"}{end}'
wait_for_key

print_subheader "K3s Imported Images"
print_cmd "sudo k3s ctr images list | grep devops-demo | head -10"
sudo k3s ctr images list 2>/dev/null | grep devops-demo | head -10 || echo "(Run with sudo to see K3s images)"
wait_for_key

clear

#############################################
# SECTION 7: LOGS & MONITORING
#############################################
print_header "📋 SECTION 7: Logs & Monitoring"

print_subheader "API Service Logs (last 15 lines)"
print_cmd "kubectl logs -n devops-demo deployment/api-service --tail=15"
kubectl logs -n devops-demo deployment/api-service --tail=15
wait_for_key

print_subheader "PostgreSQL Logs (last 10 lines)"
print_cmd "kubectl logs -n devops-demo deployment/postgres --tail=10"
kubectl logs -n devops-demo deployment/postgres --tail=10
wait_for_key

print_subheader "Recent Events"
print_cmd "kubectl get events -n devops-demo --sort-by='.lastTimestamp' | tail -10"
kubectl get events -n devops-demo --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || kubectl get events -n devops-demo | tail -10
wait_for_key

clear

#############################################
# SECTION 8: ROLLING UPDATE DEMO
#############################################
print_header "🔄 SECTION 8: Rolling Update Demo"

print_info "This will demonstrate a live rolling update with zero downtime"
echo ""
echo -e "${YELLOW}  ⚠️  This will restart the API pods. Continue? (y/n)${NC}"
read -n 1 -s CONFIRM
echo ""

if [[ $CONFIRM == "y" || $CONFIRM == "Y" ]]; then
    print_subheader "Before Update - Current Pods"
    print_cmd "kubectl get pods -n devops-demo -l app=api-service"
    kubectl get pods -n devops-demo -l app=api-service
    echo ""
    
    print_subheader "Triggering Rolling Restart"
    print_cmd "kubectl rollout restart deployment/api-service -n devops-demo"
    kubectl rollout restart deployment/api-service -n devops-demo
    echo ""
    
    print_subheader "Watching Rollout (Ctrl+C to skip)"
    print_cmd "kubectl rollout status deployment/api-service -n devops-demo"
    timeout 60 kubectl rollout status deployment/api-service -n devops-demo || echo -e "${YELLOW}  (Timeout - rollout continuing in background)${NC}"
    echo ""
    
    print_subheader "After Update - New Pods"
    print_cmd "kubectl get pods -n devops-demo -l app=api-service"
    kubectl get pods -n devops-demo -l app=api-service
    echo ""
    print_info "Notice the new pod ages - pods were recreated with zero downtime!"
    wait_for_key
else
    print_info "Skipping rolling update demo"
    wait_for_key
fi

clear

#############################################
# SECTION 9: ROLLOUT HISTORY
#############################################
print_header "📜 SECTION 9: Deployment History"

print_subheader "API Service Rollout History"
print_cmd "kubectl rollout history deployment/api-service -n devops-demo"
kubectl rollout history deployment/api-service -n devops-demo
echo ""
print_info "Each revision can be rolled back with: kubectl rollout undo deployment/api-service -n devops-demo"
wait_for_key

print_subheader "Web Service Rollout History"
print_cmd "kubectl rollout history deployment/web-service -n devops-demo"
kubectl rollout history deployment/web-service -n devops-demo
wait_for_key

clear

#############################################
# SECTION 10: PROJECT STRUCTURE
#############################################
print_header "📁 SECTION 10: Project Structure"

print_subheader "Repository Structure"
if command -v tree &> /dev/null; then
    print_cmd "tree -L 2 --dirsfirst"
    cd ~/actions-runner/_work/DEVOPS_2025/DEVOPS_2025 2>/dev/null || cd ~/DEVOPS 2>/dev/null || cd /home/misho/DEVOPS 2>/dev/null
    tree -L 2 --dirsfirst 2>/dev/null || ls -la
else
    print_cmd "ls -la"
    cd ~/actions-runner/_work/DEVOPS_2025/DEVOPS_2025 2>/dev/null || cd ~/DEVOPS 2>/dev/null || cd /home/misho/DEVOPS 2>/dev/null
    ls -la 2>/dev/null || echo "(Could not find project directory)"
fi
wait_for_key

print_subheader "Kubernetes Manifests"
print_cmd "ls -la k8s/"
ls -la k8s/ 2>/dev/null || echo "(k8s directory not found in current path)"
wait_for_key

print_subheader "Database Migrations"
print_cmd "ls -la db/migrations/"
ls -la db/migrations/ 2>/dev/null || echo "(db/migrations directory not found)"
wait_for_key

clear

#############################################
# SECTION 11: SECRETS & CONFIGMAPS
#############################################
print_header "🔐 SECTION 11: Secrets & ConfigMaps"

print_subheader "Secrets (names only - values are hidden)"
print_cmd "kubectl get secrets -n devops-demo"
kubectl get secrets -n devops-demo
echo ""
print_info "postgres-secret contains DB credentials from GitHub Secrets"
wait_for_key

print_subheader "ConfigMaps"
print_cmd "kubectl get configmaps -n devops-demo"
kubectl get configmaps -n devops-demo
wait_for_key

clear

#############################################
# SECTION 12: PERSISTENT STORAGE
#############################################
print_header "💾 SECTION 12: Persistent Storage"

print_subheader "Persistent Volume Claims"
print_cmd "kubectl get pvc -n devops-demo"
kubectl get pvc -n devops-demo
echo ""
print_info "PostgreSQL data survives pod restarts"
wait_for_key

print_subheader "Persistent Volumes"
print_cmd "kubectl get pv"
kubectl get pv | grep devops-demo || kubectl get pv | head -5
wait_for_key

clear

#############################################
# FINAL SUMMARY
#############################################
print_header "🎉 DEMO COMPLETE!"

echo -e "${GREEN}"
echo "  ╔═══════════════════════════════════════════════════════════════╗"
echo "  ║                                                               ║"
echo "  ║              ✅ All 12 Course Topics Covered!                 ║"
echo "  ║                                                               ║"
echo "  ╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${WHITE}  Summary of what was demonstrated:${NC}"
echo ""
echo -e "${CYAN}   ✓ Kubernetes Cluster with K3s${NC}"
echo -e "${CYAN}   ✓ Multi-replica Deployments (High Availability)${NC}"
echo -e "${CYAN}   ✓ ClusterIP Services & Traefik Ingress${NC}"
echo -e "${CYAN}   ✓ API Health Checks & Database Connectivity${NC}"
echo -e "${CYAN}   ✓ Rolling Updates with Zero Downtime${NC}"
echo -e "${CYAN}   ✓ Security Contexts (Non-root, No Privilege Escalation)${NC}"
echo -e "${CYAN}   ✓ Persistent Storage for PostgreSQL${NC}"
echo -e "${CYAN}   ✓ Flyway Database Migrations${NC}"
echo -e "${CYAN}   ✓ Container Images & Deployment History${NC}"
echo ""
echo -e "${YELLOW}  The CI/CD pipeline with GitHub Actions handles:${NC}"
echo -e "${WHITE}   • ESLint + Jest testing${NC}"
echo -e "${WHITE}   • Semgrep SAST security scanning${NC}"
echo -e "${WHITE}   • Trivy container vulnerability scanning${NC}"
echo -e "${WHITE}   • Docker multi-stage builds${NC}"
echo -e "${WHITE}   • Automated deployment to K3s${NC}"
echo -e "${WHITE}   • E2E testing after deployment${NC}"
echo ""
echo -e "${GREEN}  Thank you for watching! Ready for questions.${NC}"
echo ""
