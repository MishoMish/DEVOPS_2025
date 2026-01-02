# 🎓 DevOps Финален Проект - Техническа Документация

## 📋 Обзор на Проекта

Този проект представлява **пълна DevOps автоматизация**, демонстрираща целия жизнен цикъл на софтуерната доставка. Решението покрива **всички 12 теми от курса** с задълбочен анализ на Security Scanning.

---

## 🏗️ Архитектура на Решението

### Компоненти на Приложението

| Компонент | Технология | Описание |
|-----------|------------|----------|
| **API Service** | Node.js/Express + PostgreSQL | REST API endpoints, visitor tracking, guestbook |
| **Web Service** | Nginx | Статично HTML съдържание, JavaScript frontend |
| **Database** | PostgreSQL 15 | Persistent storage с PVC, Flyway миграции |

### REST API Endpoints

| Endpoint | Метод | Описание |
|----------|-------|----------|
| `/api/hello` | GET | Поздравително съобщение с брояч на посетители |
| `/api/stats` | GET | Статистика за посетителите |
| `/api/messages` | GET/POST | Guestbook съобщения |
| `/api/db-info` | GET | Информация за базата данни |
| `/health` | GET | Health check endpoint |

### Kubernetes Инфраструктура

| Ресурс | Конфигурация |
|--------|--------------|
| **Namespace** | `devops-demo` |
| **API Replicas** | 2 (high availability) |
| **Web Replicas** | 2 (high availability) |
| **DB Replicas** | 1 (PVC constraint) |
| **Ingress Controller** | Traefik (вграден в K3s) |
| **Routing** | Path-based: `/` → web, `/api/*` → api |

---

## 🔄 CI/CD Pipeline

### Структура на Pipeline-а (8 Jobs)

#### CI Фаза (при всеки push/PR)

| Job | Инструмент | Предназначение |
|-----|------------|----------------|
| **Test & Lint** | ESLint | Качество на JavaScript кода, синтактични грешки, консистентен стил |
| | Jest | Unit тестове с покритие (coverage) |
| | npm audit | Сканиране за уязвимости в зависимостите |
| **SAST Security** | Semgrep | Статичен анализ на кода за сигурност |
| | OWASP Top 10 | Критични security patterns |
| **Validate Migrations** | Flyway | Валидиране на SQL миграции преди deploy |

#### Build Фаза

| Job | Инструмент | Предназначение |
|-----|------------|----------------|
| **Build Images** | Docker | Multi-stage builds, push към GHCR |
| **Scan Images** | Trivy | Сканиране за уязвимости (CRITICAL/HIGH) |

#### CD Фаза (само main branch)

| Job | Инструмент | Предназначение |
|-----|------------|----------------|
| **Deploy to K8s** | kubectl | Rolling updates, zero downtime |
| | Flyway | Database миграции |
| **E2E Tests** | curl/wget | Health checks, API валидация |
| **Notification** | GitHub Actions | Deployment summary |

### Избор на Инструменти

| Инструмент | Алтернатива | Защо избрахме този? |
|------------|-------------|---------------------|
| **ESLint** | JSHint, Standard | Индустриален стандарт, конфигурируем, хваща 85% от грешките |
| **Jest** | Mocha, Jasmine | Създаден от Facebook, zero-config, вградени assertions |
| **Semgrep** | SonarQube, CodeQL | По-бърз, semantic analysis, по-малко false positives, безплатен |
| **Flyway** | Liquibase | SQL-базиран, version-based миграции, по-прост |
| **Trivy** | Clair, Snyk | Пълно сканиране (OS + app), бърз, актуална CVE база |

### Path-Based Filtering (Оптимизация)

Pipeline-ът използва **интелигентно детектиране на промени**:

| Компонент | Условие за Изпълнение |
|-----------|----------------------|
| API Service | Само при промени в `api-service/**` |
| Web Service | Само при промени в `web-service/**` |
| Database | Само при промени в `db/**` |
| K8s Manifests | Само при промени в `k8s/**` |

**Ползи**: По-бързи deployments, икономия на ресурси, прецизни обновления.

---

## 🔒 Security Deep Dive

### SAST със Semgrep

**Защо Semgrep?**
- Разбира семантиката на кода (не само regex)
- Нисък false-positive rate
- Бързо изпълнение (< 30 секунди)
- Обширна библиотека от правила

**Приложени Rulesets:**
1. `p/security-audit` - Общи security best practices
2. `p/secrets` - Детекция на hardcoded credentials
3. `p/owasp-top-ten` - Injection, XSS, SSRF и др.
4. `p/nodejs` - Node.js специфични уязвимости

**Примерни Детекции:**
- SQL injection чрез string concatenation
- Command injection през child_process
- Hardcoded API ключове или пароли
- Несигурни криптографски алгоритми
- Path traversal уязвимости

### Container Scanning с Trivy

**Защо Trivy?**
- Comprehensive (OS packages + app dependencies)
- Бърз (< 1 минута на image)
- Точен (постоянно обновявана CVE база)
- Open source (Aqua Security)

**Обхват на Сканиране:**
- Operating System Packages (Alpine CVEs)
- Application Dependencies (npm packages)
- Configuration issues

**Severity Filtering:**
- CRITICAL → Прекратява pipeline
- HIGH → Прекратява pipeline
- MEDIUM/LOW → Само логване

### Defense in Depth (Многопластова Защита)

| Слой | Инструмент | Какво Защитава |
|------|------------|----------------|
| 1. Source Code | Semgrep SAST | Уязвимости в кода |
| 2. Dependencies | npm audit + Trivy | CVEs в библиотеки |
| 3. Container | Trivy image scan | OS и runtime уязвимости |
| 4. Runtime | K8s security contexts | Runtime изолация |

---

## ☸️ Kubernetes Конфигурация

### Rolling Update Strategy

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1          # Създава 1 нов pod първо
    maxUnavailable: 0    # Никога под replica count
```

**Ефект**: Zero-downtime deployments

### Health Probes

| Probe | Предназначение |
|-------|----------------|
| **livenessProbe** | Рестартира pod ако е unhealthy |
| **readinessProbe** | Премахва от LB ако не е ready |

### Security Context

```yaml
securityContext:
  runAsNonRoot: true           # Никога като root
  runAsUser: 1001              # Специфичен non-root user
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]                # Drop всички Linux capabilities
```

### Traefik Ingress

| Характеристика | Описание |
|----------------|----------|
| **Тип** | Path-based routing |
| **Entry Point** | VM-IP:80 |
| **Routing Rules** | `/` → web-service, `/api/*` → api-service |
| **Load Balancing** | Автоматично между replicas |

---

## 🐳 Docker Best Practices

### Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime
FROM node:18-alpine
COPY --from=builder /app/node_modules ./node_modules
```

**Ползи**: По-малки images, по-добър layer caching

### Security Measures

- **Non-root user**: `USER nodejs`
- **Health check**: Вграден HEALTHCHECK
- **Alpine base**: Минимална attack surface

---

## 🗄️ Database Management

### Flyway Миграции

| Файл | Описание |
|------|----------|
| `V1__create_visitors_table.sql` | Таблици за visitors и stats |
| `V2__add_messages_table.sql` | Guestbook messages таблица |

**Ползи на Flyway:**
- Version-controlled schema changes
- Rollback capability
- SQL-based (познат синтаксис)
- Интеграция с CI/CD
- Enterprise-grade

### PostgreSQL в Kubernetes

- **Persistent Volume Claim**: Данните оцеляват рестарти
- **Secrets**: Credentials от GitHub Secrets
- **Health Checks**: `pg_isready` команда

---

## 🏗️ Infrastructure as Code

### Terraform Ресурси

| Ресурс | Предназначение |
|--------|----------------|
| Namespace | `devops-demo` изолация |
| Resource Quotas | Лимити за CPU/Memory |
| Network Policies | Ограничаване на трафик |

---

## 📈 Бъдещи Подобрения

### Краткосрочни

| Подобрение | Полза |
|------------|-------|
| GitOps с ArgoCD | Declarative CD, automatic drift detection |
| Helm Charts | Package application за по-лесно разпространение |
| Monitoring Stack | Prometheus + Grafana за observability |

### Дългосрочни

| Подобрение | Полза |
|------------|-------|
| Service Mesh (Istio) | mTLS, traffic management, circuit breakers |
| Multi-Environment | Dev → Staging → Production |
| Advanced Security | Image signing (Cosign), runtime security (Falco) |
| HPA | Auto-scale базирано на натоварване |

---

## 📊 Покритие на 12-те Теми

| # | Тема | Имплементация |
|---|------|---------------|
| 1 | Phases of SDLC | Пълна автоматизация на lifecycle |
| 2 | Collaborate | PR templates, CODEOWNERS, issue templates |
| 3 | Source Control | Git с .gitignore, branch protection |
| 4 | Branching Strategies | GitHub Flow (feature/bugfix/hotfix) |
| 5 | Building Pipelines | GitHub Actions (8 jobs) |
| 6 | Continuous Integration | Tests, lint, SAST, build, migrations |
| 7 | Continuous Delivery | Auto-deploy към K3s |
| 8 | Security | **DEEP DIVE** - SAST + Trivy + K8s contexts |
| 9 | Docker | Multi-stage builds, non-root, health checks |
| 10 | Kubernetes | K3s, Deployments, Services, Ingress, rolling updates |
| 11 | Infrastructure as Code | Terraform за namespace, quotas, policies |
| 12 | Database Changes | PostgreSQL + Flyway миграции |

---

## ❓ Очаквани Въпроси и Отговори

### Защо Semgrep вместо SonarQube?

Semgrep е по-бърз, по-лек, има по-ниско ниво на false-positives и се интегрира лесно с GitHub Actions. SonarQube е добър за enterprise, но добавя сложност за този проект.

### Как се управляват secrets?

Kubernetes Secrets, създадени от GitHub Secrets по време на deployment. За production бих добавил HashiCorp Vault или External Secrets Operator.

### Как се правят rollbacks?

Kubernetes ги управлява автоматично:
- Health check failures задействат автоматичен rollback
- Ръчно: `kubectl rollout undo deployment/api-service`
- Всички images са tagged, позволявайки rollback към всяка версия

### Защо K3s вместо пълен Kubernetes?

K3s е лек, production-ready и перфектен за single-node/edge deployments. Включва Traefik ingress по подразбиране, намалявайки сложността на setup-а.

---

## 🎯 Заключение

Този проект демонстрира **пълен, production-ready DevOps pipeline** покриващ:

- ✅ Всички 12 теми от курса
- ✅ Автоматизирано тестване и quality checks
- ✅ Многопластово security сканиране (SAST + Trivy)
- ✅ Database миграции с Flyway
- ✅ Контейнеризирани microservices
- ✅ Kubernetes оркестрация със zero-downtime deployments
- ✅ Infrastructure as Code с Terraform
