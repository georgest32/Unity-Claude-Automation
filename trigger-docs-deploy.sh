#!/bin/bash
# Trigger documentation deployment

echo "Triggering documentation deployment..."

# Option 1: Make a small change to trigger the workflow
echo "" >> docs/index.md
git add docs/index.md
git commit -m "docs: Trigger initial documentation deployment"
git push origin main

echo "Deployment triggered! Check GitHub Actions tab for progress."
echo "Documentation will be available at:"
echo "https://georgest32.github.io/Unity-Claude-Automation/"