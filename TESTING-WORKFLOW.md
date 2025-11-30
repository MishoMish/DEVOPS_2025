# Testing Your CI/CD Workflow

## Understanding the Workflow Issue

Your workflow has a deployment job that tries to deploy to Kubernetes, but:
- It only runs on push to `main` branch → **FIXED**: Now runs on `main` OR `master`
- GitHub Actions runners can't reach your local Minikube cluster
- The workflow needs proper secrets configured

## Option 1: Test Locally with `act` ✅ (Recommended)

Test individual jobs locally without pushing to GitHub:

```bash
# Make the script executable (already done)
chmod +x test-workflow.sh

# Run the test script
./test-workflow.sh
```

### What you can test:
- ✅ **test-api**: Runs linting and tests (works locally)
- ✅ **build-images**: Builds Docker images (works locally but won't push without credentials)
- ⚠️ **scan-images**: Scans images with Trivy (requires images to be pushed)
- ❌ **deploy-kubernetes**: Won't work (needs cloud Kubernetes or proper secrets)

### Quick test commands:

```bash
# List all jobs in the workflow
act -l

# Test the API unit tests
act -j test-api

# Test building images (dry run, won't actually push)
act -j build-images --dry-run
```

## Option 2: Test on GitHub Actions ✅

Push to GitHub and let the real workflow run:

```bash
# Commit and push your changes
git add .
git commit -m "Fix workflow for master branch and lowercase image names"
git push origin master
```

Then go to: https://github.com/MishoMish/DEVOPS_2025/actions

### What will happen:
- ✅ **test-api**: Will run and test your API service
- ✅ **sast-scan**: Will run security scanning
- ✅ **build-images**: Will build and push images to ghcr.io/mishomish/*
- ✅ **scan-images**: Will scan the pushed images with Trivy (should work now!)
- ❌ **deploy-kubernetes**: Will fail (needs `KUBE_CONFIG` secret)

## Option 3: Make Deployment Work 🔧

To make the Kubernetes deployment actually work from GitHub Actions:

### A. Use a Cloud Kubernetes Cluster (Recommended)

Use a cloud provider that GitHub Actions can reach:
- DigitalOcean Kubernetes (cheapest, ~$12/month)
- AWS EKS
- Google GKE
- Azure AKS

### B. Configure Secrets for Deployment

If you have a cloud cluster:

1. Get your kubeconfig:
   ```bash
   cat ~/.kube/config | base64
   ```

2. Add to GitHub Secrets:
   - Go to: https://github.com/MishoMish/DEVOPS_2025/settings/secrets/actions
   - Create secret `KUBE_CONFIG` with the base64 value

### C. Skip Deployment (for testing)

If you just want to test CI without deployment:

```yaml
# In .github/workflows/ci.yaml, change the deploy job condition to:
if: false  # Never run deployment
```

## Option 4: Test Everything Except Deployment 🎯

The **simplest way** to see it working:

```bash
# 1. Push to GitHub
git push origin master

# 2. Watch it run (it will succeed up to deployment):
#    - ✅ Test API
#    - ✅ SAST Scan
#    - ✅ Build Images
#    - ✅ Scan Images (this is what we fixed!)
#    - ⏭️  Deploy (skipped/failed - that's OK for now)
```

Visit: https://github.com/MishoMish/DEVOPS_2025/actions

## What We Fixed Today

1. ✅ **Lowercase image names**: Changed from `MishoMish` to `mishomish`
   - Trivy can now parse the image names correctly
   
2. ✅ **Master branch support**: Deploy job now runs on both `main` and `master`

3. ✅ **Proper image references**: Using environment variables instead of matrix values

## Quick Reference

```bash
# Test locally with act
./test-workflow.sh

# Push and test on GitHub
git push origin master

# View workflow runs
open https://github.com/MishoMish/DEVOPS_2025/actions

# Check if images were pushed
open https://github.com/MishoMish?tab=packages
```

## Expected Results

When you push to GitHub, you should see:
- ✅ All CI jobs pass (test, scan, build)
- ✅ Images pushed to GitHub Container Registry
- ✅ Trivy scan completes (no more parse errors!)
- ⚠️ Deployment may fail (needs cluster access - that's expected)

The main goal (fixing the Trivy error) is complete! 🎉
