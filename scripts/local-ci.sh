#!/bin/bash
# ===========================================
# LOCAL CI SCRIPT - Pre-Push CI Validation
# ===========================================
# 
# USE CASE:
# - Runs complete CI pipeline locally before pushing to remote
# - Mimics GitHub Actions CI workflow for early issue detection
# - Validates code quality, security, and build integrity
# - Prevents CI failures by catching issues locally
#
# WHEN TO USE:
# - Before pushing code to remote repositories
# - During development to validate changes
# - As part of pre-commit/pre-push hooks
# - For local validation without using CI/CD resources
#
# INCLUDES:
# - ESLint code linting
# - Unit test execution
# - Security vulnerability scanning
# - Docker image building
# - Build validation
#
# REFERENCED IN:
# - Development workflow documentation
# - Git hooks for automated validation
# - No direct file references (standalone utility)
#
# USAGE: ./scripts/local-ci.sh
# ===========================================

set -e

echo "Running local CI..."
echo ""

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

FAILED=0
TOTAL_CHECKS=5
PASSED_CHECKS=0

# Helper function to run a check
run_check() {
  local name=$1
  local command=$2
  
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔄 $name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  if eval "$command"; then
    echo "✅ $name - PASSED"
    ((PASSED_CHECKS++))
  else
    echo "❌ $name - FAILED"
    FAILED=1
  fi
  echo ""
}

# 1. Lint Check
cd api-service
run_check "ESLint" "npm run lint"

# 2. Unit Tests
run_check "Unit Tests" "npm test -- --passWithNoTests"

# 3. Security Audit
run_check "Security Audit (npm audit)" "npm audit --audit-level=high"
cd ..

# 4. Docker Build (API)
run_check "Docker Build (API)" "docker build -t devops-demo/api-service:test ./api-service"

# 5. Docker Build (Web)
run_check "Docker Build (Web)" "docker build -t devops-demo/web-service:test ./web-service"

# Summary
echo "============================================"
echo "📊 CI Summary: $PASSED_CHECKS/$TOTAL_CHECKS checks passed"
echo "============================================"

if [ $FAILED -ne 0 ]; then
  echo ""
  echo "❌ Some checks failed. Please fix the issues before pushing."
  echo ""
  exit 1
fi

echo ""
echo "✅ All CI checks passed! Ready to push."
echo ""
echo "Optional: Run the full stack locally with:"
echo "  docker-compose up"
echo ""
