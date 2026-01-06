# 🎓 Ръководство за Представяне на Изпита

## ⏱️ Времева Рамка: 12-15 минути

| Секция | Време | Описание |
|--------|-------|----------|
| High-Level Overview | 3-4 мин | Обща архитектура и DevOps концепция |
| Low-Level Design | 4-5 мин | Конкретни технологии и имплементация |
| Deep Dive (SAST) | 3-4 мин | Задълбочен анализ на Security Scanning |
| Бъдещи Подобрения | 1-2 мин | Какво бихме добавили |
| Въпроси | 2-3 мин | Резерв за дискусия |

---

# 📊 ЧАСТ 1: HIGH-LEVEL SOLUTION DESIGN (3-4 мин)

## Какво Представлява Проектът?

> "Това е **пълна DevOps автоматизация** за уеб приложение с микросървисна архитектура, която демонстрира целия жизнен цикъл на софтуерната доставка - от commit до production deployment."

### Архитектура на Високо Ниво

```
┌─────────────────────────────────────────────────────────────────┐
│                         DEVELOPER                                │
│                            │                                     │
│                      git push/PR                                 │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    GITHUB REPOSITORY                        │ │
│  │  • Source Code (API + Web)                                  │ │
│  │  • Infrastructure as Code (Terraform, K8s manifests)        │ │
│  │  • Database Migrations (Flyway SQL)                         │ │
│  │  • CI/CD Pipeline (.github/workflows/)                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                            │                                     │
│                     GitHub Actions                               │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    CI/CD PIPELINE                           │ │
│  │  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐      │ │
│  │  │Test │→ │SAST │→ │Build│→ │Scan │→ │Deploy│→ │E2E  │      │ │
│  │  │Lint │  │     │  │     │  │Trivy│  │ K8s  │  │Tests│      │ │
│  │  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘      │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                            │                                     │
│                     kubectl apply                                │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   KUBERNETES (K3s)                          │ │
│  │                                                              │ │
│  │   ┌─────────┐    ┌─────────┐    ┌─────────────┐            │ │
│  │   │   Web   │    │   API   │    │  PostgreSQL │            │ │
│  │   │ (Nginx) │    │(Node.js)│    │   + Flyway  │            │ │
│  │   │ x2 pods │    │ x2 pods │    │   x1 pod    │            │ │
│  │   └────┬────┘    └────┬────┘    └──────┬──────┘            │ │
│  │        │              │                │                    │ │
│  │        └──────┬───────┴────────────────┘                    │ │
│  │               │                                              │ │
│  │        ┌──────┴──────┐                                       │ │
│  │        │   Traefik   │  ← Ingress Controller                │ │
│  │        │   Ingress   │                                       │ │
│  │        └─────────────┘                                       │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                            │                                     │
│                      http://VM-IP                                │
│                            ▼                                     │
│                         USERS                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Основни Компоненти

| Компонент | Технология | Роля |
|-----------|------------|------|
| **Frontend** | Nginx + HTML/JS | Статично уеб съдържание, Guestbook UI |
| **Backend** | Node.js/Express | REST API, бизнес логика |
| **Database** | PostgreSQL 15 | Персистентно съхранение на данни |
| **Orchestration** | K3s (Kubernetes) | Контейнер оркестрация, scaling |
| **CI/CD** | GitHub Actions | Автоматизация на целия pipeline |

### DevOps Принципи в Проекта

1. **Everything as Code** - Инфраструктура, конфигурация, pipeline - всичко е в Git
2. **Automation** - От commit до production без ръчна намеса
3. **Shift-Left Security** - Сигурността се проверява рано в процеса
4. **Continuous Improvement** - Версионирани миграции, rolling updates

---

# 🔧 ЧАСТ 2: LOW-LEVEL DESIGN - 12-те Теми (4-5 мин)

## 📌 Тема 1: Phases of SDLC (Фази на Жизнения Цикъл)

**Какво е?** Software Development Life Cycle - структурираният процес за разработка на софтуер.

**Моята имплементация:**
```
Plan → Code → Build → Test → Deploy → Operate → Monitor
  │      │       │      │       │         │         │
  │      │       │      │       │         │         └─ (Future: Prometheus)
  │      │       │      │       │         └─ K8s с health probes
  │      │       │      │       └─ Auto-deploy към K3s
  │      │       │      └─ Jest + ESLint + SAST + Trivy
  │      │       └─ Docker multi-stage builds
  │      └─ Feature branches, PR templates
  └─ GitHub Issues с templates
```

**Къде в кода:** Целият `.github/workflows/ci.yaml` - 8 jobs покриващи всички фази.

---

## 📌 Тема 2: Collaborate (Сътрудничество)

**Какво е?** Практики за екипна работа и код преглед.

**Моята имплементация:**

| Файл | Предназначение |
|------|----------------|
| `.github/CODEOWNERS` | Автоматично assign-ва reviewers за всеки файл |
| `.github/PULL_REQUEST_TEMPLATE.md` | Структуриран PR формат с checklist |
| `.github/ISSUE_TEMPLATE/bug_report.md` | Шаблон за докладване на бъгове |
| `.github/ISSUE_TEMPLATE/feature_request.md` | Шаблон за нови функционалности |

**Пример от CODEOWNERS:**
```
*                       @mishomish      # Default owner за всичко
/k8s/                   @mishomish      # Kubernetes manifests
/terraform/             @mishomish      # Infrastructure
/api-service/           @mishomish      # Backend код
```

**Ползи:** При PR към protected branch, автоматично се изисква review.

---

## 📌 Тема 3: Source Control (Контрол на Версиите)

**Какво е?** Система за проследяване на промените в кода.

**Моята имплементация:**

| Елемент | Описание |
|---------|----------|
| **Git** | Distributed version control |
| `.gitignore` | Изключва node_modules, .env, coverage/ |
| `.pre-commit-config.yaml` | Pre-commit hooks за качество |
| `.husky/` | Git hooks за локална валидация |

**Структура на репото:**
```
DEVOPS/
├── api-service/          # Backend микросървис
├── web-service/          # Frontend микросървис
├── db/migrations/        # Database версиониране
├── k8s/                  # Kubernetes манифести
├── terraform/            # Infrastructure as Code
├── .github/              # CI/CD и collaboration
└── docs/                 # Документация
```

---

## 📌 Тема 4: Branching Strategies (Стратегии за Клонове)

**Какво е?** Подход за организиране на Git клонове.

**Моята имплементация: GitHub Flow**

```
main ─────●────────●────────●────────●─────→ Production
          │        ▲        │        ▲
          │        │        │        │
feature/  └──●──●──┘        │        │
new-api                     │        │
                            │        │
bugfix/                     └──●──●──┘
fix-db
```

| Тип Branch | Naming | Предназначение |
|------------|--------|----------------|
| `main` | Protected | Production-ready код |
| `feature/*` | `feature/add-messages` | Нови функционалности |
| `bugfix/*` | `bugfix/fix-db-connection` | Поправки на бъгове |
| `hotfix/*` | `hotfix/security-patch` | Критични поправки |

feature|feat|fix|bugfix|hotfix|chore|docs|refactor|test|style|perf|ci

**Pipeline triggers в `ci.yaml`:**
```yaml
on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master]
```

---

## 📌 Тема 5: Building Pipelines (Изграждане на Pipelines)

**Какво е?** Автоматизирана последователност от стъпки за build и deploy.

**Моята имплементация: 8 GitHub Actions Jobs**

```
┌─────────────────┐
│ detect-changes  │ ← Интелигентно детектиране
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│test-  │ │lint-  │
│api    │ │web    │
└───┬───┘ └───┬───┘
    │         │
    └────┬────┘
         ▼
    ┌─────────┐
    │sast-scan│ ← Semgrep Security
    └────┬────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌─────────────────┐
│build- │ │validate-        │
│images │ │migrations       │
└───┬───┘ └─────────────────┘
    │
    ▼
┌───────────┐
│scan-images│ ← Trivy CVE scan
└─────┬─────┘
      │
      ▼
┌─────────────────┐
│deploy-kubernetes│ ← Rolling update
└────────┬────────┘
         │
         ▼
┌─────────┐
│e2e-tests│ ← Health validation
└────┬────┘
     │
     ▼
┌────────┐
│ notify │ ← Deployment summary
└────────┘
```

**Path-based filtering (оптимизация):**
```yaml
- name: Detect file changes
  uses: dorny/paths-filter@v3
  with:
    filters: |
      api:
        - 'api-service/**'
      web:
        - 'web-service/**'
      db:
        - 'db/**'
```
→ Ако променим само `web-service/`, API тестовете се пропускат!

---

## 📌 Тема 6: Continuous Integration (Непрекъсната Интеграция)

**Какво е?** Автоматично тестване и валидиране при всеки commit.

**Моята имплементация:**

| Инструмент | Предназначение | Файл |
|------------|----------------|------|
| **ESLint** | JavaScript код стил и грешки | `api-service/.eslintrc.js` |
| **Jest** | Unit тестове с coverage | `api-service/tests/` |
| **npm audit** | Dependency vulnerabilities | Вграден |
| **Semgrep** | SAST security scan | Pipeline job |
| **Flyway** | SQL migration валидация | `db/migrations/` |

**Jest тестове:**
```javascript
// api-service/tests/health.test.js
test('GET /health returns 200 and healthy status', async () => {
  const response = await request(app).get('/health');
  expect(response.status).toBe(200);
  expect(response.body.status).toBe('healthy');
});
```

**CI Резултат:** Ако тест или lint fail-не → PR не може да се merge.

---

## 📌 Тема 7: Continuous Delivery (Непрекъсната Доставка)

**Какво е?** Автоматичен deploy към production при успешен CI.

**Моята имплементация:**

```yaml
deploy-kubernetes:
  runs-on: [self-hosted, k8s]
  if: github.ref == 'refs/heads/main'  # Само main branch
  environment:
    name: production
    url: http://devops-demo.local
```

**Deployment Flow:**
1. Build Docker image с уникален SHA tag
2. Import в K3s containerd
3. Apply Kubernetes manifests
4. Run Flyway migrations
5. Rolling update на deployments
6. E2E health validation

**Zero-Downtime Deployment:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # Добави 1 нов pod
    maxUnavailable: 0  # Никога под 2 replicas
```

---

## 📌 Тема 8: Security (Сигурност) ⭐ DEEP DIVE

**Какво е?** Защита на кода, контейнерите и runtime средата.

**Моята имплементация: Defense in Depth**

| Слой | Инструмент | Какво Защитава |
|------|------------|----------------|
| 1. Source Code | Semgrep SAST | Уязвимости в логиката |
| 2. Dependencies | npm audit | CVEs в библиотеки |
| 3. Container | Trivy | OS и runtime уязвимости |
| 4. Runtime | K8s Security Contexts | Изолация при изпълнение |

**K8s Security Context:**
```yaml
securityContext:
  runAsNonRoot: true           # Никога като root
  runAsUser: 1001              # Специфичен user
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]                # Премахни всички capabilities
```

👉 **Виж ЧАСТ 3 за детайлен Deep Dive на SAST**

---

## 📌 Тема 9: Docker (Контейнеризация)

**Какво е?** Пакетиране на приложения в изолирани контейнери.

**Моята имплементация:**

**Multi-stage build (api-service/Dockerfile):**
```dockerfile
# Stage 1: Build - включва dev dependencies
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime - само production код
FROM node:18-alpine
COPY --from=builder /app/node_modules ./node_modules
COPY src ./src

# Security: Non-root user
USER nodejs

# Health check вграден в image
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node -e "require('http').get('http://localhost:3000/health'...)"
```

**Ползи:**
- По-малък image size (само production dependencies)
- По-добър layer caching
- Non-root = по-сигурен container

---

## 📌 Тема 10: Kubernetes (Оркестрация)

**Какво е?** Платформа за автоматизирано управление на контейнери.

**Моята имплементация: K3s**

| Ресурс | Файл | Описание |
|--------|------|----------|
| Namespace | `k8s/namespace.yaml` | Изолация `devops-demo` |
| Deployments | `k8s/api-deployment.yaml` | 2 replicas с health probes |
| Services | `k8s/api-service.yaml` | ClusterIP load balancing |
| Ingress | `k8s/ingress.yaml` | Traefik path-based routing |
| Secrets | `k8s/postgres-secret.yaml` | DB credentials |
| PVC | В postgres deployment | Persistent storage |

**Health Probes:**
```yaml
livenessProbe:       # Рестартирай ако е мъртъв
  httpGet:
    path: /health
    port: 3000
  periodSeconds: 10

readinessProbe:      # Премахни от LB ако не е ready
  httpGet:
    path: /health
    port: 3000
  periodSeconds: 5
```

**Ingress Routing:**
```
http://VM-IP/        → web-service (Nginx)
http://VM-IP/api/*   → api-service (Node.js)
```

---

## 📌 Тема 11: Infrastructure as Code (IaC)

**Какво е?** Управление на инфраструктура чрез код вместо ръчна конфигурация.

**Моята имплементация: Terraform + K8s Manifests**

**terraform/main.tf:**
```hcl
# Създаване на Kubernetes namespace
resource "kubernetes_namespace" "devops_demo" {
  metadata {
    name = var.namespace
    labels = {
      environment = "production"
      managed-by  = "terraform"
    }
  }
}

# Resource Quotas - лимитиране на ресурси
resource "kubernetes_resource_quota" "demo_quota" {
  metadata {
    name      = "demo-quota"
    namespace = kubernetes_namespace.devops_demo.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
    }
  }
}
```

**Ползи:**
- Версионирана инфраструктура
- Reproducible environments
- `terraform plan` показва промените преди apply

---

## 📌 Тема 12: Database Changes (Промени в Базата)

**Какво е?** Версионирано управление на database schema.

**Моята имплементация: Flyway**

**db/migrations/V1__create_visitors_table.sql:**
```sql
CREATE TABLE IF NOT EXISTS visitors (
    id SERIAL PRIMARY KEY,
    ip_address VARCHAR(45),
    user_agent TEXT,
    path VARCHAR(255),
    visited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_visitors_visited_at ON visitors(visited_at);
```

**db/migrations/V2__add_messages_table.sql:**
```sql
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    author VARCHAR(100),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

**Flyway в Kubernetes (k8s/flyway-job.yaml):**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: flyway-migrate
spec:
  template:
    spec:
      containers:
        - name: flyway
          image: flyway/flyway:10-alpine
          args:
            - migrate
          env:
            - name: FLYWAY_URL
              value: "jdbc:postgresql://postgres:5432/devopsdb"
```

**Процес:**
1. CI валидира миграциите (syntax, naming)
2. CD изпълнява миграциите преди app deployment
3. Flyway записва версията в `flyway_schema_history` таблица
4. Само нови миграции се изпълняват

---

# 🔬 ЧАСТ 3: DEEP DIVE - SAST със Semgrep (3-4 мин)

## Какво е SAST?

**Static Application Security Testing** - анализ на сорс кода БЕЗ да се изпълнява. Търси уязвимости в логиката, patterns които водят до security проблеми.

## Защо Semgrep?

| Характеристика | Semgrep | Алтернативи (SonarQube, CodeQL) |
|----------------|---------|----------------------------------|
| **Скорост** | < 30 секунди | 2-5 минути |
| **Setup** | Zero config | Сложна конфигурация |
| **False Positives** | 10-15% | 30-50% |
| **Как работи** | Semantic AST анализ | Regex / тежък анализ |
| **Цена** | Безплатен (OSS) | Платен / ограничен |

## Моята Конфигурация

```yaml
- name: Run Semgrep SAST Scan
  uses: returntocorp/semgrep-action@v1
  with:
    config: >-
      p/security-audit     # Общи security best practices
      p/secrets            # Hardcoded credentials
      p/owasp-top-ten      # OWASP Top 10 уязвимости
      p/nodejs             # Node.js специфични проблеми
```

## Какво Открива Всеки Ruleset?

### 1. `p/security-audit`
```javascript
// ❌ ОТКРИВА: Слаб хеширащ алгоритъм
const hash = crypto.createHash('md5').update(password);

// ✅ ПРЕПОРЪЧВА:
const hash = crypto.createHash('sha256').update(password);
```

### 2. `p/secrets`
```javascript
// ❌ ОТКРИВА: Hardcoded credentials
const DB_PASSWORD = "devops123";
const API_KEY = "sk_test_EXAMPLE_KEY_HERE";

// ✅ МОЯТА ИМПЛЕМЕНТАЦИЯ:
const DB_PASSWORD = process.env.DB_PASSWORD;
```

### 3. `p/owasp-top-ten`

**A03: SQL Injection**
```javascript
// ❌ ОТКРИВА: String concatenation в SQL
const query = "SELECT * FROM users WHERE id = '" + id + "'";

// ✅ МОЯТА ИМПЛЕМЕНТАЦИЯ: Parameterized queries
const query = 'SELECT * FROM users WHERE id = $1';
await pool.query(query, [id]);
```

**A01: Broken Access Control**
```javascript
// ❌ ОТКРИВА: Липсваща авторизация
app.delete('/api/messages/:id', async (req, res) => {
  await db.query('DELETE FROM messages WHERE id = $1', [req.params.id]);
});
```

### 4. `p/nodejs`

**Command Injection:**
```javascript
// ❌ ОТКРИВА: User input в shell команда
const { exec } = require('child_process');
exec(`ping ${req.query.host}`);

// ✅ ПРАВИЛНО:
const { execFile } = require('child_process');
execFile('ping', ['-c', '1', validatedHost]);
```

**Path Traversal:**
```javascript
// ❌ ОТКРИВА: Directory traversal
res.sendFile(`./uploads/${req.params.filename}`);
// Атака: ../../../../etc/passwd

// ✅ ПРАВИЛНО:
const safePath = path.normalize(filename).replace(/^(\.\.(\/|\\|$))+/, '');
```

## Как се Интегрира в Pipeline-а?

```
git push
    │
    ▼
┌─────────────────┐
│   test-api      │  ← Първо: Работи ли кодът?
│   lint-web      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   sast-scan     │  ← После: Сигурен ли е кодът?
│   (Semgrep)     │
└────────┬────────┘
         │
    Ако PASS
         │
         ▼
┌─────────────────┐
│  build-images   │
└─────────────────┘
```

## Defense in Depth Model

```
┌─────────────────────────────────────────────────────────┐
│                     SOURCE CODE                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │              Semgrep SAST                       │   │
│   │   • Injection attacks                           │   │
│   │   • Hardcoded secrets                           │   │
│   │   • Insecure crypto                             │   │
│   └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                    DEPENDENCIES                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │              npm audit                          │   │
│   │   • Known CVEs в npm packages                   │   │
│   └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                    CONTAINER IMAGE                      │
│   ┌─────────────────────────────────────────────────┐   │
│   │              Trivy Scanner                      │   │
│   │   • OS package CVEs (Alpine)                    │   │
│   │   • Application CVEs                            │   │
│   └─────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────┤
│                      RUNTIME                            │
│   ┌─────────────────────────────────────────────────┐   │
│   │          Kubernetes Security Contexts           │   │
│   │   • Non-root user                               │   │
│   │   • Dropped capabilities                        │   │
│   │   • No privilege escalation                     │   │
│   └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Защо Този Подход е Важен?

1. **Shift-Left** - Хващаме проблеми ПРЕДИ да стигнат до production
2. **Автоматизация** - Всеки commit се сканира, няма пропуски
3. **Бърз Feedback** - Developer разбира за проблема веднага
4. **Compliance** - OWASP Top 10 покритие за security стандарти

---

# 🚀 ЧАСТ 4: БЪДЕЩИ ПОДОБРЕНИЯ (1-2 мин)

## Краткосрочни (Лесни за добавяне)

| Подобрение | Защо? |
|------------|-------|
| **GitOps с ArgoCD** | Декларативен CD, автоматичен drift detection |
| **Helm Charts** | По-лесно пакетиране и versioning на приложението |
| **Prometheus + Grafana** | Мониторинг и alerting |

## Дългосрочни (По-сложни)

| Подобрение | Защо? |
|------------|-------|
| **Service Mesh (Istio)** | mTLS между сървиси, traffic management |
| **Multi-Environment** | Dev → Staging → Production pipeline |
| **HPA (Horizontal Pod Autoscaler)** | Auto-scale при високо натоварване |
| **Image Signing (Cosign)** | Гарантирано произход на images |
| **Secret Management (Vault)** | External secrets, rotation |

## Production Readiness Gaps

```
Текущо                          Идеално Production
────────                        ──────────────────
K3s (single node)        →      Multi-node cluster с HA
Manual secrets           →      HashiCorp Vault
Няма monitoring          →      Prometheus + Grafana + Alertmanager
Един environment         →      Dev/Staging/Prod namespaces
```

---

# ❓ ОЧАКВАНИ ВЪПРОСИ

### "Защо Semgrep вместо SonarQube?"
> Semgrep е по-бърз, по-лесен за setup, има по-ниско ниво на false-positives и semantic анализ вместо regex. SonarQube е добър за enterprise, но добавя излишна сложност.

### "Как се управляват secrets?"
> Kubernetes Secrets, създадени от GitHub Secrets по време на deployment. За production бих добавил HashiCorp Vault.

### "Как работят rollbacks?"
> `kubectl rollout undo deployment/api-service` - Kubernetes пази историята на deployments. Health check failures автоматично trigger-ват rollback.

### "Защо K3s?"
> Лек, production-ready Kubernetes за edge/single-node. Включва Traefik ingress по подразбиране. Перфектен за демо и малки environments.

### "Какво става ако Semgrep намери vulnerability?"
> В момента `continue-on-error: true` - не блокира deploy-а, но се логва. За production бих го направил blocking.

---

# ✅ DEMO CHECKLIST

## Преди Изпита

- [ ] K3s cluster работи: `kubectl get nodes`
- [ ] Приложението е deployed: `kubectl get pods -n devops-demo`
- [ ] GitHub repo е отворен с последен успешен pipeline
- [ ] Терминал готов за демо команди

## Demo Commands

```bash
# Покажи running pods
kubectl get pods -n devops-demo -o wide

# Покажи deployments
kubectl get deployments -n devops-demo

# Покажи ingress routing
kubectl get ingress -n devops-demo

# Покажи rollout history
kubectl rollout history deployment/api-service -n devops-demo

# Test API
curl http://localhost/api/hello
curl http://localhost/health
```

## Ако Питат за Live Demo

```bash
# Направи малка промяна
echo "// Demo change $(date)" >> api-service/src/index.js

# Commit и push
git add . && git commit -m "Demo: trigger pipeline" && git push

# Покажи pipeline в GitHub Actions
```

---

**Успех на изпита! 🎓**
