#!/bin/bash
# Bash wrapper to run PowerShell tests
echo "Running Static Analysis Tests with PowerShell 7..."
pwsh -ExecutionPolicy Bypass -File "$(dirname "$0")/Test-StaticAnalysisIntegration-Final.ps1" "$@"