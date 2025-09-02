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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCO51kLZ62fwnb4
# tQulRGfCkEqNBJVVqjZijh1QsSg2lqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPN2fe+KO/qTLTioAAINORqZ
# MCs3FdT2nsW/ffl9EWGOMA0GCSqGSIb3DQEBAQUABIIBAJLe/z+OfWpLr4xF6v0U
# HX6zHw5EbiFAfuJfB3P1hkBeB1Cx24E4Aw5CU1SjmQyCMH6SSutkcrntJUiISGtW
# kY1BipOZsrxOaR+27kJiRbHB4w9WFmF5qMl3wkCmowIn2L2E/M7uGZ/cIwjsQO64
# X5S4w0Dwh2gQ0P68qfySj3eMpoSWFTimHybgazaAiNzHv74gozVQ/vwFnqtKCzAD
# AsU1e25pl09kF/thYt14nF4fnmG3/uI8KkIr6Vco8d5yCGkvBaCkbBRAjsFRse90
# 0QWldBEfw/jUQ4tOG5TQBRNljZ2q3zoA6UdHP/BUj6hqOXOJpQiOdKcMMEhyZ0aT
# Yjw=
# SIG # End signature block
