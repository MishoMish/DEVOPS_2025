#!/bin/bash
# Test GitHub Actions workflow locally using act

echo "🧪 Testing GitHub Actions workflow locally..."
echo ""
echo "Available test options:"
echo "1. Test just the build-images job (recommended)"
echo "2. Test scan-images job (requires images built first)"
echo "3. Test test-api job"
echo "4. List all jobs"
echo "5. Run full workflow (may take a long time)"
echo ""

read -p "Choose option (1-5): " choice

case $choice in
  1)
    echo "🔨 Running build-images job..."
    act -j build-images --secret GITHUB_TOKEN=$GITHUB_TOKEN
    ;;
  2)
    echo "🔍 Running scan-images job..."
    act -j scan-images --secret GITHUB_TOKEN=$GITHUB_TOKEN
    ;;
  3)
    echo "🧪 Running test-api job..."
    act -j test-api
    ;;
  4)
    echo "📋 Listing all jobs..."
    act -l
    ;;
  5)
    echo "🚀 Running full workflow..."
    echo "⚠️  Note: Deploy job will be skipped (requires Kubernetes access)"
    act --secret GITHUB_TOKEN=$GITHUB_TOKEN
    ;;
  *)
    echo "❌ Invalid option"
    exit 1
    ;;
esac

echo ""
echo "✅ Test complete!"
