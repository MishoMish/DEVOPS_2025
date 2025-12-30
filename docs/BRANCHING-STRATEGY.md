# Branching Strategy

This project follows **GitHub Flow** branching strategy, which is ideal for continuous deployment.

## 🌳 Branch Types

### Main Branch (`main`)
- **Protected branch** - requires PR review
- Always deployable
- Represents production-ready code
- Triggers deployment to Kubernetes

### Feature Branches (`feature/*`)
- Created from `main`
- Format: `feature/<issue-number>-<short-description>`
- Example: `feature/42-add-user-authentication`

### Bugfix Branches (`bugfix/*`)
- Created from `main`
- Format: `bugfix/<issue-number>-<short-description>`
- Example: `bugfix/55-fix-health-endpoint`

### Hotfix Branches (`hotfix/*`)
- For urgent production fixes
- Format: `hotfix/<issue-number>-<short-description>`
- Example: `hotfix/99-critical-security-patch`

## 📋 Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│                          GitHub Flow                              │
└──────────────────────────────────────────────────────────────────┘

   main ──────●───────────●───────────●───────────●──────── main
              │           ↑           ↑           ↑
              │           │           │           │
              └──●──●──●──┘           │           │
                feature/1-api         │           │
                                      │           │
                         └──●──●──────┘           │
                           bugfix/2-fix           │
                                                  │
                                    └──●──────────┘
                                      hotfix/3-urgent
```

## 🔄 Development Process

1. **Create Issue**
   - Document the feature/bug
   - Assign labels and milestone

2. **Create Branch**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/123-add-new-endpoint
   ```

3. **Develop & Commit**
   ```bash
   git add .
   git commit -m "feat: add new endpoint for user data"
   ```

4. **Push & Create PR**
   ```bash
   git push origin feature/123-add-new-endpoint
   # Create PR via GitHub UI or CLI
   gh pr create --title "Add new endpoint" --body "Fixes #123"
   ```

5. **CI Pipeline Runs**
   - Tests execute
   - Linting checks
   - SAST security scan
   - Docker image build
   - Container vulnerability scan

6. **Code Review**
   - Reviewer approves or requests changes
   - CODEOWNERS automatically requested

7. **Merge to Main**
   - Squash and merge preferred
   - Auto-deploys to Kubernetes

## ✅ Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Code style (formatting, semicolons) |
| `refactor` | Code change that neither fixes nor adds |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system or dependencies |
| `ci` | CI/CD configuration |
| `chore` | Other changes |

### Examples

```bash
feat(api): add user authentication endpoint
fix(k8s): correct health probe timeout
docs(readme): update deployment instructions
ci(github): add code coverage reporting
```

## 🛡️ Branch Protection Rules

Recommended settings for `main` branch:

- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
  - `test-api` (Tests & Lint)
  - `sast-scan` (Security Scan)
- ✅ Require conversation resolution before merging
- ✅ Require linear history (squash merge)
- ✅ Include administrators in restrictions
- ✅ Restrict who can push to matching branches

## 📊 Pipeline Triggers

| Branch Pattern | CI | CD (Deploy) |
|---------------|-----|-------------|
| `main` | ✅ | ✅ |
| `develop` | ✅ | ❌ |
| `feature/*` | ✅ (via PR) | ❌ |
| `bugfix/*` | ✅ (via PR) | ❌ |
| `hotfix/*` | ✅ (via PR) | ❌ |

---

*This branching strategy ensures code quality and enables rapid, safe deployments.*
