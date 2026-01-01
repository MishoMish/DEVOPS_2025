#!/bin/bash
# ===========================================
# Local CI - Run All CI Checks Locally
# ===========================================
# This script mimics what the GitHub Actions CI pipeline does,
# allowing you to catch issues before pushing.
#
# Usage: ./scripts/local-ci.sh
# ===========================================

set -e

echo "============================================"
echo "🏗️  Running Local CI Pipeline"
echo "============================================"
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
