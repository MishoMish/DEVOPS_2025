# DevOps Final Project - Architecture Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           User Browser                              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ HTTP Request
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Kubernetes Ingress Controller                   │
│                         (Nginx Ingress)                             │
│                                                                     │
│  Routes:                                                            │
│    /          → web-service:80                                     │
│    /api/*     → api-service:3000                                   │
└──────────────┬────────────────────────────────┬─────────────────────┘
               │                                │
               │                                │
      ┌────────▼────────┐              ┌───────▼────────┐
      │  Web Service    │              │  API Service   │
      │  ClusterIP      │              │  ClusterIP     │
      │  Port: 80       │──────────────▶  Port: 3000    │
      └────────┬────────┘   Proxy       └───────┬────────┘
               │            /api/*              │
               │                                │
      ┌────────▼────────┐              ┌───────▼────────┐
      │  Web Deployment │              │ API Deployment │
      │   (Nginx)       │              │   (Node.js)    │
      │   Replicas: 2   │              │   Replicas: 2  │
      │                 │              │                │
      │  ┌───────────┐  │              │  ┌──────────┐  │
      │  │   Pod 1   │  │              │  │  Pod 1   │  │
      │  │           │  │              │  │          │  │
      │  │  Nginx    │  │              │  │ Express  │  │
      │  │  + HTML   │  │              │  │ + pg     │  │
      │  └───────────┘  │              │  └─────┬────┘  │
      │                 │              │        │       │
      │  ┌───────────┐  │              │  ┌─────▼────┐  │
      │  │   Pod 2   │  │              │  │  Pod 2   │  │
      │  │           │  │              │  │          │  │
      │  │  Nginx    │  │              │  │ Express  │  │
      │  │  + HTML   │  │              │  │ + pg     │  │
      │  └───────────┘  │              │  └─────┬────┘  │
      └─────────────────┘              └────────┼───────┘
                                                │
                                                ▼
                                       ┌────────────────┐
                                       │   PostgreSQL   │
                                       │   Service      │
                                       │   Port: 5432   │
                                       └───────┬────────┘
                                               │
                                       ┌───────▼────────┐
                                       │   PostgreSQL   │
                                       │   Deployment   │
                                       │   Replicas: 1  │
                                       │                │
                                       │  ┌──────────┐  │
                                       │  │  Pod     │  │
                                       │  │          │  │
                                       │  │ Postgres │  │
                                       │  │   15     │  │
                                       │  └────┬─────┘  │
                                       │       │        │
                                       │  ┌────▼─────┐  │
                                       │  │   PVC    │  │
                                       │  │  1Gi     │  │
                                       │  └──────────┘  │
                                       └────────────────┘
```

## Database Migration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │   Validate   │    │   Test &     │    │    SAST      │
  │  Migrations  │    │   Lint       │    │    Scan      │
  │  (Flyway)    │    │   (Jest)     │    │  (Semgrep)   │
  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
                             ▼
                      ┌──────────────┐
                      │    Build     │
                      │   Images     │
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │   Deploy DB  │
                      │  (PostgreSQL)│
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │   Flyway     │
                      │   Migrate    │
                      │   (K8s Job)  │
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │   Deploy     │
                      │   API + Web  │
                      └──────┬───────┘
                             │
                             ▼
                      ┌──────────────┐
                      │   E2E Tests  │
                      └──────────────┘
```

## CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer                               │
│                    git push / PR created                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions Triggered                     │
└─────────────────────────────────────────────────────────────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
     ┌──────────┐     ┌──────────┐    ┌──────────┐
     │   Lint   │     │   Test   │    │   SAST   │
     │ (ESLint) │     │  (Jest)  │    │(Semgrep) │
     └────┬─────┘     └────┬─────┘    └────┬─────┘
          │                │               │
          └────────────────┼───────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │Build Docker │
                    │   Images    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │Scan Images  │
                    │  (Trivy)    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Push to    │
                    │    GHCR     │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Deploy    │
                    │    to K8s   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Verify    │
                    │  Rollout    │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Notify    │
                    │   Status    │
                    └─────────────┘
```

## Security Scanning Integration

```
┌────────────────────────────────────────────────────────────┐
│                      Source Code                           │
└─────────────────────┬──────────────────────────────────────┘
                      │
                      ▼
               ┌──────────────┐
               │     SAST     │
               │   (Semgrep)  │
               └──────┬───────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Scan for:            │
          │  • SQL Injection      │
          │  • XSS                │
          │  • Hardcoded secrets  │
          │  • Insecure crypto    │
          │  • Command injection  │
          └───────┬───────────────┘
                  │
                  ▼
          ┌───────────────┐
          │ Generate      │
          │ SARIF Report  │
          └───────┬───────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │  GitHub Security Tab        │
    │  • Code Scanning Alerts     │
    │  • Severity Classification  │
    │  • Remediation Guidance     │
    └─────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│                    Docker Images                           │
└─────────────────────┬──────────────────────────────────────┘
                      │
                      ▼
               ┌──────────────┐
               │   Container  │
               │   Scanning   │
               │   (Trivy)    │
               └──────┬───────┘
                      │
                      ▼
          ┌───────────────────────┐
          │  Scan for:            │
          │  • OS vulnerabilities │
          │  • Library CVEs       │
          │  • Outdated packages  │
          │  • Misconfigurations  │
          └───────┬───────────────┘
                  │
                  ▼
          ┌───────────────┐
          │ Filter        │
          │ CRITICAL/HIGH │
          └───────┬───────┘
                  │
                  ▼
    ┌─────────────────────────────┐
    │  Security Reports           │
    │  • SARIF to GitHub          │
    │  • JSON artifacts           │
    │  • Fail build if critical   │
    └─────────────────────────────┘
```

## Kubernetes Rolling Update Process

```
Initial State:
┌─────────────────────────────────────────┐
│         API Deployment v1.0             │
├─────────────────────────────────────────┤
│  ┌─────┐  ┌─────┐                      │
│  │ Pod │  │ Pod │                      │
│  │ v1  │  │ v1  │                      │
│  └─────┘  └─────┘                      │
└─────────────────────────────────────────┘

Step 1: Create new pod
┌─────────────────────────────────────────┐
│         API Deployment                  │
├─────────────────────────────────────────┤
│  ┌─────┐  ┌─────┐  ┌─────┐             │
│  │ Pod │  │ Pod │  │ Pod │ ← New       │
│  │ v1  │  │ v1  │  │ v2  │   (Creating)│
│  └─────┘  └─────┘  └─────┘             │
└─────────────────────────────────────────┘

Step 2: Wait for readiness
┌─────────────────────────────────────────┐
│         API Deployment                  │
├─────────────────────────────────────────┤
│  ┌─────┐  ┌─────┐  ┌─────┐             │
│  │ Pod │  │ Pod │  │ Pod │ ✓ Ready     │
│  │ v1  │  │ v1  │  │ v2  │             │
│  └─────┘  └─────┘  └─────┘             │
└─────────────────────────────────────────┘

Step 3: Terminate old pod
┌─────────────────────────────────────────┐
│         API Deployment                  │
├─────────────────────────────────────────┤
│           ┌─────┐  ┌─────┐             │
│           │ Pod │  │ Pod │             │
│           │ v1  │  │ v2  │             │
│           └─────┘  └─────┘             │
└─────────────────────────────────────────┘

Step 4: Create second new pod
┌─────────────────────────────────────────┐
│         API Deployment                  │
├─────────────────────────────────────────┤
│           ┌─────┐  ┌─────┐  ┌─────┐    │
│           │ Pod │  │ Pod │  │ Pod │ ←New│
│           │ v1  │  │ v2  │  │ v2  │    │
│           └─────┘  └─────┘  └─────┘    │
└─────────────────────────────────────────┘

Step 5: Complete
┌─────────────────────────────────────────┐
│         API Deployment v2.0             │
├─────────────────────────────────────────┤
│                ┌─────┐  ┌─────┐         │
│                │ Pod │  │ Pod │         │
│                │ v2  │  │ v2  │         │
│                └─────┘  └─────┘         │
└─────────────────────────────────────────┘

Zero downtime! Always 2 pods available.
```

## Network Flow

```
External Request
       │
       ▼
┌──────────────┐
│   Ingress    │ devops-demo.local
└──────┬───────┘
       │
       │ Path: /
       ├─────────────────┐
       │                 │
       │ Path: /api/*    │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│Web Service  │   │ API Service │
│ClusterIP    │   │ ClusterIP   │
└──────┬──────┘   └──────┬──────┘
       │                 │
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│ Web Pods    │   │  API Pods   │
│ (Nginx)     │───▶ (Express)   │
└─────────────┘   └─────────────┘
  Proxy /api/*
  to API service
```

## Project Structure Tree

```
devops-demo/
├── .github/
│   └── workflows/
│       └── ci.yaml                 # GitHub Actions pipeline
├── api-service/
│   ├── src/
│   │   └── index.js               # Express server
│   ├── tests/
│   │   └── health.test.js         # Jest tests
│   ├── .dockerignore
│   ├── .eslintrc.json
│   ├── Dockerfile
│   ├── jest.config.js
│   └── package.json
├── web-service/
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── index.html
│   └── nginx.conf
├── k8s/
│   ├── namespace.yaml
│   ├── api-deployment.yaml
│   ├── api-service.yaml
│   ├── web-deployment.yaml
│   ├── web-service.yaml
│   └── ingress.yaml
├── terraform/
│   ├── .gitignore
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── scripts/
│   ├── setup.sh
│   ├── deploy.sh
│   ├── cleanup.sh
│   └── test.sh
├── .gitignore
├── ARCHITECTURE.md                 # This file
├── QUICKSTART.md
└── README.md
```
