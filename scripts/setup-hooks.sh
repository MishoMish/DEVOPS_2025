#!/bin/bash
# ===========================================
# SETUP HOOKS SCRIPT - Git Hook Configuration
# ===========================================
# 
# USE CASE:
# - Configures Git hooks for automated code quality checks
# - Sets up pre-commit and pre-push validation
# - Installs development dependencies
# - One-time setup after repository cloning
#
# WHEN TO USE:
# - Once after cloning the repository
# - When setting up a new development environment
# - After updating hook configurations
# - For team onboarding and development setup
#
# CONFIGURES:
# - Pre-commit hook (ESLint on staged files)
# - Pre-push hook (full CI validation)
# - Git hook path configuration
# - npm dependencies installation
#
# REFERENCED IN:
# - .husky/pre-commit (installed hooks)
# - .husky/pre-push (installed hooks)
# - Development setup documentation
#
# USAGE: ./scripts/setup-hooks.sh
# ===========================================

set -e

echo "🔧 Setting up Git hooks..."
echo ""

# Get the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Check if .husky directory exists
if [ ! -d ".husky" ]; then
  echo "❌ Error: .husky directory not found!"
  exit 1
fi

# Make hooks executable
chmod +x .husky/pre-commit
chmod +x .husky/pre-push

# Configure Git to use the .husky directory for hooks
git config core.hooksPath .husky

echo "✅ Git hooks configured!"
echo ""

# Install npm dependencies for api-service
echo "📦 Installing API service dependencies..."
cd api-service
npm install
cd ..

echo ""
echo "============================================"
echo "✅ Setup complete!"
echo ""
echo "The following hooks are now active:"
echo "  📝 pre-commit  - Lints staged files"
echo "  🚀 pre-push    - Runs lint, tests, and security audit"
echo ""
echo "To disable hooks temporarily, use:"
echo "  git commit --no-verify"
echo "  git push --no-verify"
echo "============================================"
