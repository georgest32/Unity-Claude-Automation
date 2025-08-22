# Demo-SecurityValidation.ps1
# Demonstrates the security validation features of the Bootstrap Orchestrator

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Validation Demonstration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Import the SystemStatus module
Write-Host "`nImporting SystemStatus module..." -ForegroundColor Gray
Import-Module "$PSScriptRoot\Modules\Unity-Claude-SystemStatus" -Force

# Test 1: Validate a secure manifest
Write-Host "`n[TEST 1] Validating a SECURE manifest" -ForegroundColor Yellow
$secureManifest = @{
    Name = "SecureSubsystem"
    Version = "1.0.0"
    StartScript = ".\Start-Subsystem.ps1"
    Dependencies = @("SystemStatus")
    MutexName = "Local\SecureSubsystem"
    MaxMemoryMB = 256
    MaxCpuPercent = 25
}

$result = Test-ManifestSecurity -Manifest $secureManifest
Write-Host "Result: " -NoNewline
if ($result.IsSecure) {
    Write-Host "SECURE" -ForegroundColor Green
} else {
    Write-Host "INSECURE" -ForegroundColor Red
}
Write-Host "Security Issues: $($result.SecurityIssues.Count)"
Write-Host "Recommendations: $($result.Recommendations.Count)"
if ($result.Recommendations) {
    $result.Recommendations | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

# Test 2: Validate an insecure manifest with path traversal
Write-Host "`n[TEST 2] Validating an INSECURE manifest (path traversal)" -ForegroundColor Yellow
$insecureManifest1 = @{
    Name = "InsecurePathTraversal"
    StartScript = "..\..\Windows\System32\evil.ps1"
}

$result = Test-ManifestSecurity -Manifest $insecureManifest1 -StrictMode
Write-Host "Result: " -NoNewline
if ($result.IsSecure) {
    Write-Host "SECURE" -ForegroundColor Green
} else {
    Write-Host "INSECURE" -ForegroundColor Red
}
Write-Host "Security Issues: $($result.SecurityIssues.Count)"
if ($result.SecurityIssues) {
    $result.SecurityIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

# Test 3: Validate manifest with command injection
Write-Host "`n[TEST 3] Validating an INSECURE manifest (command injection)" -ForegroundColor Yellow
$insecureManifest2 = @{
    Name = "InsecureCommandInjection"
    StartCommand = 'Invoke-Expression $userInput'
    HealthCheckCommand = '$(malicious-command)'
}

$result = Test-ManifestSecurity -Manifest $insecureManifest2
Write-Host "Result: " -NoNewline
if ($result.IsSecure) {
    Write-Host "SECURE" -ForegroundColor Green
} else {
    Write-Host "INSECURE" -ForegroundColor Red
}
Write-Host "Security Issues: $($result.SecurityIssues.Count)"
if ($result.SecurityIssues) {
    $result.SecurityIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

# Test 4: Test secure mutex creation
Write-Host "`n[TEST 4] Creating a SECURE mutex" -ForegroundColor Yellow
try {
    $mutexResult = New-SecureMutex -MutexName "DemoSecureMutex" -StrictSecurity
    Write-Host "Mutex created successfully!" -ForegroundColor Green
    Write-Host "  Name: $($mutexResult.Name)"
    Write-Host "  IsGlobal: $($mutexResult.IsGlobal)"
    Write-Host "  IsLocal: $($mutexResult.IsLocal)"
    Write-Host "  StrictSecurity: $($mutexResult.StrictSecurity)"
    Write-Host "  Owner: $($mutexResult.Owner)"
    
    # Test the mutex security
    Write-Host "`n[TEST 5] Testing mutex security" -ForegroundColor Yellow
    $securityTest = Test-MutexSecurity -Mutex $mutexResult.Mutex
    Write-Host "Mutex Security: " -NoNewline
    if ($securityTest.IsSecure) {
        Write-Host "SECURE" -ForegroundColor Green
    } else {
        Write-Host "INSECURE" -ForegroundColor Red
        $securityTest.Issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    # Clean up
    $mutexResult.Mutex.Dispose()
} catch {
    Write-Host "Error creating mutex: $_" -ForegroundColor Red
}

# Test 6: Validate resource limits
Write-Host "`n[TEST 6] Validating resource limits" -ForegroundColor Yellow
$manifestWithBadLimits = @{
    Name = "BadResourceLimits"
    MaxMemoryMB = 99999
    MaxCpuPercent = 150
}

$result = Test-ManifestSecurity -Manifest $manifestWithBadLimits
Write-Host "Result: " -NoNewline
if ($result.IsSecure) {
    Write-Host "SECURE" -ForegroundColor Green
} else {
    Write-Host "INSECURE" -ForegroundColor Red
}
Write-Host "Security Issues: $($result.SecurityIssues.Count)"
if ($result.SecurityIssues) {
    $result.SecurityIssues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
Write-Host "Recommendations: $($result.Recommendations.Count)"
if ($result.Recommendations) {
    $result.Recommendations | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Validation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The security functions are now available:" -ForegroundColor Green
Write-Host "  - Test-ManifestSecurity: Validates manifest security" -ForegroundColor Gray
Write-Host "  - New-SecureMutex: Creates mutex with secure permissions" -ForegroundColor Gray
Write-Host "  - Test-MutexSecurity: Tests mutex security configuration" -ForegroundColor Gray
Write-Host ""
Write-Host "Use 'Get-Help Test-ManifestSecurity -Full' for detailed documentation" -ForegroundColor Cyan