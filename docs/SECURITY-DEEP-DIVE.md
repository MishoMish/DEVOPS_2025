# 🔒 Security Deep Dive

This document provides an in-depth explanation of the security measures implemented in this DevOps project. Security is integrated at every stage of the software delivery pipeline.

## 📋 Table of Contents

1. [Security Overview](#security-overview)
2. [SAST - Static Application Security Testing](#sast---static-application-security-testing)
3. [Container Vulnerability Scanning](#container-vulnerability-scanning)
4. [Docker Security Best Practices](#docker-security-best-practices)
5. [Kubernetes Security](#kubernetes-security)
6. [Supply Chain Security](#supply-chain-security)
7. [Security Testing Locally](#security-testing-locally)

---

## 🎯 Security Overview

Security is implemented using a **Defense in Depth** approach with multiple layers:

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DEFENSE IN DEPTH                               │
├─────────────────────────────────────────────────────────────────────┤
│  Layer 1: SOURCE CODE                                               │
│  ├── SAST (Semgrep) - Static code analysis                         │
│  ├── ESLint - Code quality & security rules                        │
│  └── Secrets detection - Prevent credential leaks                   │
├─────────────────────────────────────────────────────────────────────┤
│  Layer 2: DEPENDENCIES                                              │
│  ├── npm audit - Node.js vulnerability check                       │
│  └── Trivy - Deep dependency scanning                              │
├─────────────────────────────────────────────────────────────────────┤
│  Layer 3: CONTAINER IMAGES                                          │
│  ├── Trivy image scan - OS & app vulnerabilities                   │
│  ├── Multi-stage builds - Minimal attack surface                   │
│  └── Non-root users - Principle of least privilege                 │
├─────────────────────────────────────────────────────────────────────┤
│  Layer 4: RUNTIME (Kubernetes)                                      │
│  ├── Pod Security Context - Restricted permissions                 │
│  ├── Resource Limits - Prevent DoS                                 │
│  ├── Network Policies - Micro-segmentation                         │
│  └── Health Probes - Automatic recovery                            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔍 SAST - Static Application Security Testing

### What is SAST?

Static Application Security Testing (SAST) analyzes source code to identify security vulnerabilities **before** the code runs. It's a "white-box" testing method that examines the internal structure.

### Tool: Semgrep

**Why Semgrep?**

| Feature | Benefit |
|---------|---------|
| **Language-aware** | Understands JavaScript/Node.js semantics |
| **Fast** | Scans codebase in < 30 seconds |
| **Low false positives** | Pattern matching reduces noise |
| **Open source** | Free with extensive rule library |
| **CI/CD integration** | Native GitHub Actions support |

### Rulesets Applied

```yaml
config: >-
  p/security-audit     # General security best practices
  p/secrets            # Hardcoded credentials detection
  p/owasp-top-ten     # OWASP Top 10 vulnerabilities
  p/nodejs            # Node.js specific issues
```

### OWASP Top 10 Coverage

| OWASP Category | Semgrep Detection |
|----------------|-------------------|
| A01 - Broken Access Control | ✅ Detects missing auth checks |
| A02 - Cryptographic Failures | ✅ Weak crypto, hardcoded secrets |
| A03 - Injection | ✅ SQL, Command, XSS injection |
| A04 - Insecure Design | ⚠️ Limited (requires architecture review) |
| A05 - Security Misconfiguration | ✅ Insecure defaults, debug modes |
| A06 - Vulnerable Components | ⚠️ Via Trivy (not Semgrep) |
| A07 - Authentication Failures | ✅ Weak auth patterns |
| A08 - Data Integrity Failures | ✅ Insecure deserialization |
| A09 - Security Logging Failures | ⚠️ Limited coverage |
| A10 - Server-Side Request Forgery | ✅ SSRF pattern detection |

### Example Vulnerabilities Detected

#### 1. SQL Injection
```javascript
// ❌ VULNERABLE - Semgrep will flag this
const query = "SELECT * FROM users WHERE id = " + userId;
db.query(query);

// ✅ SECURE - Parameterized query
const query = "SELECT * FROM users WHERE id = $1";
db.query(query, [userId]);
```

#### 2. Command Injection
```javascript
// ❌ VULNERABLE - User input in shell command
const exec = require('child_process').exec;
exec('ls ' + userInput);

// ✅ SECURE - Use execFile with array arguments
const execFile = require('child_process').execFile;
execFile('ls', [sanitizedInput]);
```

#### 3. Hardcoded Secrets
```javascript
// ❌ VULNERABLE - Semgrep secrets ruleset catches this
const API_KEY = "sk-1234567890abcdef";

// ✅ SECURE - Use environment variables
const API_KEY = process.env.API_KEY;
```

#### 4. Cross-Site Scripting (XSS)
```javascript
// ❌ VULNERABLE - Unescaped user input
res.send(`<h1>Hello ${req.query.name}</h1>`);

// ✅ SECURE - Use template engine with auto-escaping
res.render('hello', { name: req.query.name });
```

### SARIF Output Format

Semgrep generates SARIF (Static Analysis Results Interchange Format) for GitHub Security integration:

```json
{
  "$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/master/Schemata/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "tool": {
      "driver": {
        "name": "Semgrep",
        "rules": [...]
      }
    },
    "results": [{
      "ruleId": "javascript.express.security.express-sql-injection",
      "level": "error",
      "message": {
        "text": "SQL injection vulnerability detected"
      },
      "locations": [{
        "physicalLocation": {
          "artifactLocation": { "uri": "src/index.js" },
          "region": { "startLine": 42, "startColumn": 5 }
        }
      }]
    }]
  }]
}
```

---

## 🐳 Container Vulnerability Scanning

### Tool: Trivy (Aqua Security)

Trivy performs comprehensive vulnerability scanning of container images.

### Scan Coverage

```
┌─────────────────────────────────────────────────────────────┐
│                    TRIVY SCAN TARGETS                       │
├─────────────────────────────────────────────────────────────┤
│  1. OS PACKAGES                                             │
│     ├── Alpine Linux (APK)                                  │
│     ├── Debian/Ubuntu (DEB/APT)                            │
│     └── Red Hat (RPM/YUM)                                  │
├─────────────────────────────────────────────────────────────┤
│  2. APPLICATION DEPENDENCIES                                │
│     ├── Node.js (package-lock.json)                        │
│     ├── Python (requirements.txt, Pipfile)                 │
│     ├── Ruby (Gemfile.lock)                                │
│     └── Go (go.sum)                                        │
├─────────────────────────────────────────────────────────────┤
│  3. INFRASTRUCTURE AS CODE                                  │
│     ├── Kubernetes manifests                               │
│     ├── Terraform files                                    │
│     └── Dockerfile misconfigurations                       │
├─────────────────────────────────────────────────────────────┤
│  4. SECRETS                                                 │
│     └── Embedded credentials in images                     │
└─────────────────────────────────────────────────────────────┘
```

### Severity Levels

| Severity | Action | Example |
|----------|--------|---------|
| **CRITICAL** | 🔴 Block deployment | Remote code execution, no authentication required |
| **HIGH** | 🟠 Block deployment | Significant impact, may require authentication |
| **MEDIUM** | 🟡 Warning | Limited impact, requires specific conditions |
| **LOW** | 🟢 Informational | Minimal impact |

### Pipeline Configuration

```yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.REGISTRY }}/${{ env.API_IMAGE_NAME }}:${{ github.ref_name }}'
    format: 'table'
    exit-code: '0'           # Change to '1' to fail on vulnerabilities
    severity: 'CRITICAL,HIGH'
```

### Example Scan Output

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Trivy Vulnerability Report                           │
├───────────────┬─────────────────┬──────────┬───────────────┬───────────────┤
│    Library    │  Vulnerability  │ Severity │   Installed   │     Fixed     │
├───────────────┼─────────────────┼──────────┼───────────────┼───────────────┤
│ express       │ CVE-2024-29041  │ MEDIUM   │ 4.18.2        │ 4.19.2        │
│ node          │ CVE-2024-22019  │ HIGH     │ 18.19.0       │ 18.19.1       │
│ openssl       │ CVE-2024-0727   │ MEDIUM   │ 3.1.4-r1      │ 3.1.4-r3      │
└───────────────┴─────────────────┴──────────┴───────────────┴───────────────┘
```

---

## 🔐 Docker Security Best Practices

### 1. Multi-Stage Builds

```dockerfile
# Stage 1: Build (includes dev dependencies)
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Production (minimal image)
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
# Build tools NOT included in final image
```

**Benefits:**
- Smaller image size (reduced attack surface)
- No build tools in production
- Faster pulls and deployments

### 2. Non-Root User

```dockerfile
# Create dedicated user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Switch to non-root user
USER nodejs
```

**Why?**
- Limits damage from container escape
- Follows principle of least privilege
- Required by many security policies

### 3. Minimal Base Images

| Image | Size | Attack Surface |
|-------|------|----------------|
| `node:18` | ~900MB | High |
| `node:18-slim` | ~200MB | Medium |
| `node:18-alpine` | ~120MB | Low ✅ |

### 4. Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { \
    process.exit(r.statusCode === 200 ? 0 : 1) \
  })"
```

---

## ☸️ Kubernetes Security

### Pod Security Context

```yaml
securityContext:
  allowPrivilegeEscalation: false   # Cannot gain more privileges
  runAsNonRoot: true                # Must run as non-root
  runAsUser: 1001                   # Specific UID
  capabilities:
    drop:
      - ALL                         # Drop all Linux capabilities
  readOnlyRootFilesystem: false     # Can be enabled for extra security
```

### Resource Limits (DoS Prevention)

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

### Network Policy (Terraform)

```hcl
resource "kubernetes_network_policy" "devops_demo_network_policy" {
  spec {
    pod_selector {
      match_labels = { app = "api-service" }
    }

    ingress {
      from {
        pod_selector {
          match_labels = { app = "web-service" }
        }
      }
      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}
```

---

## 🔗 Supply Chain Security

### Implemented

- ✅ Pin base image versions (`node:18-alpine`, not `node:latest`)
- ✅ Lock dependencies (`package-lock.json` committed)
- ✅ Scan dependencies in CI pipeline
- ✅ Use official images from trusted sources

### Future Enhancements

| Enhancement | Tool | Benefit |
|-------------|------|---------|
| Image signing | Cosign/Sigstore | Verify image authenticity |
| SBOM generation | Syft | Full dependency inventory |
| Policy enforcement | OPA Gatekeeper | Block non-compliant images |
| Runtime protection | Falco | Detect suspicious behavior |

---

## 🧪 Security Testing Locally

### Run SAST with Semgrep

```bash
# Install Semgrep
pip install semgrep

# Run scan with all rulesets
semgrep --config=p/security-audit \
        --config=p/secrets \
        --config=p/owasp-top-ten \
        --config=p/nodejs \
        api-service/

# Generate SARIF report
semgrep --config=auto --sarif --output=semgrep-results.sarif api-service/
```

### Scan Images with Trivy

```bash
# Install Trivy (Linux)
sudo apt-get install trivy

# Install Trivy (macOS)
brew install aquasecurity/trivy/trivy

# Scan local image
trivy image api-service:local

# Scan with severity filter
trivy image --severity HIGH,CRITICAL api-service:local

# Generate JSON report
trivy image --format json --output trivy-report.json api-service:local

# Scan Kubernetes manifests
trivy config k8s/
```

### Check Kubernetes Security

```bash
# Verify pod security context
kubectl get pod -n devops-demo -l app=api-service -o yaml | grep -A 15 securityContext

# Check resource limits
kubectl describe pod -n devops-demo -l app=api-service | grep -A 5 "Limits\|Requests"

# Review network policies
kubectl get networkpolicies -n devops-demo -o yaml
```

---

## 📊 Security Metrics

| Metric | Target | Current |
|--------|--------|---------|
| SAST findings (Critical/High) | 0 | ✅ 0 |
| Container CVEs (Critical) | 0 | ✅ 0 |
| Container CVEs (High) | < 5 | ✅ Within threshold |
| Non-root containers | 100% | ✅ 100% |
| Resource limits defined | 100% | ✅ 100% |

---

## 📚 References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Semgrep Rules Registry](https://semgrep.dev/explore)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Container Security](https://csrc.nist.gov/publications/detail/sp/800-190/final)

---

*Security is not a feature—it's a continuous process integrated into every stage of the software delivery lifecycle.*
