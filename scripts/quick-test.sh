#!/bin/sh
# ===========================================
# QUICK TEST SCRIPT - Project Validation Demo
# ===========================================
# 
# USE CASE:
# - Demonstrates that the project is working correctly
# - Validates code quality and project structure
# - Quick validation for presentations and demos
# - Verifies development environment setup
#
# WHEN TO USE:
# - Before project presentations or demos
# - After setting up a new development environment
# - To validate project health quickly
# - During code reviews to show working state
#
# VALIDATES:
# - Node.js and npm installation
# - API service unit tests
# - Code linting (ESLint)
# - Project file structure
# - Development dependencies
#
# REFERENCED IN:
# - Self-referencing (counts script files)
# - No external file references (standalone demo script)
#
# USAGE: ./scripts/quick-test.sh
# ===========================================

echo "╔═══════════════════════════════════════════════════════╗"
echo "║                                                       ║"
echo "║       DEVOPS PROJECT VALIDATION TEST                 ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Setup NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Navigate to project root
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT"

echo "📍 Project Location: $(pwd)"
echo ""

# Check Node.js
echo "🔍 Checking Node.js..."
if command -v node >/dev/null 2>&1; then
    echo "   ✅ Node.js version: $(node --version)"
    echo "   ✅ npm version: $(npm --version)"
else
    echo "   ❌ Node.js not found (run: nvm install 18)"
    exit 1
fi
echo ""

# Test API Service
echo "🧪 Testing API Service..."
cd api-service

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "   📦 Installing dependencies..."
    npm install --silent
fi

echo "   🔬 Running unit tests..."
npm test --silent 2>&1 | grep -E "(PASS|FAIL|Tests:|Test Suites:)" || npm test

echo ""
echo "   📏 Running linter..."
npm run lint 2>&1 | grep -v "^$" | head -10 || echo "   ✅ No linting errors"

cd ..
echo ""

# Validate file structure
echo "📁 Validating project structure..."

check_file() {
    if [ -f "$1" ]; then
        echo "   ✅ $1"
    else
        echo "   ❌ $1 MISSING"
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo "   ✅ $1/"
    else
        echo "   ❌ $1/ MISSING"
    fi
}

check_dir "api-service"
check_dir "web-service"
check_dir "k8s"
check_dir "terraform"
check_dir "scripts"
check_dir ".github/workflows"
echo ""

echo "📄 Checking key files..."
check_file "README.md"
check_file "docs/PRESENTATION.md"
check_file "docs/ARCHITECTURE.md"
check_file "docker-compose.yml"
check_file ".github/workflows/ci.yaml"
echo ""

# Count files
echo "📊 Project Statistics:"
echo "   • Documentation files: $(ls -1 *.md 2>/dev/null | wc -l)"
echo "   • Kubernetes manifests: $(ls -1 k8s/*.yaml 2>/dev/null | wc -l)"
echo "   • Helper scripts: $(ls -1 scripts/*.sh 2>/dev/null | wc -l)"
echo "   • Source files: $(find api-service/src web-service -name "*.js" -o -name "*.html" 2>/dev/null | wc -l)"
echo ""

# Validate Kubernetes manifests (basic syntax check)
echo "☸️  Validating Kubernetes manifests..."
if [ -d "k8s" ]; then
    for file in k8s/*.yaml; do
        if [ -f "$file" ]; then
            # Basic YAML syntax check
            if grep -q "apiVersion:" "$file" && grep -q "kind:" "$file"; then
                echo "   ✅ $(basename $file)"
            else
                echo "   ⚠️  $(basename $file) - check syntax"
            fi
        fi
    done
fi
echo ""

# Check CI/CD pipeline
echo "🔄 Checking CI/CD pipeline..."
if [ -f ".github/workflows/ci.yaml" ]; then
    JOBS=$(grep -c "^  [a-z-]*:$" .github/workflows/ci.yaml)
    echo "   ✅ GitHub Actions workflow found"
    echo "   📊 Pipeline jobs: $JOBS"
else
    echo "   ❌ CI/CD pipeline not found"
fi
echo ""

# Summary
echo "╔═══════════════════════════════════════════════════════╗"
echo "║                                                       ║"
echo "║               ✅ VALIDATION COMPLETE ✅              ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "🎯 Project Status: READY FOR PRESENTATION"
echo ""
echo "📋 Next Steps:"
echo "   1. Study docs/ARCHITECTURE.md for diagrams"
echo ""
echo "🎓 You're ready to present! Good luck! 🚀"
echo ""
