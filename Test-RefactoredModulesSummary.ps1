#Requires -Version 5.1
<#
.SYNOPSIS
    Quick summary test of all refactored modules
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  REFACTORED MODULES STATUS SUMMARY    " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$modules = @(
    @{ Name = "Unity-Claude-CPG"; Path = "Unity-Claude-CPG" }
    @{ Name = "Unity-Claude-MasterOrchestrator"; Path = "Unity-Claude-MasterOrchestrator" }
    @{ Name = "SafeCommandExecution"; Path = "SafeCommandExecution" }
    @{ Name = "Unity-Claude-UnityParallelization"; Path = "Unity-Claude-UnityParallelization" }
    @{ Name = "Unity-Claude-IntegratedWorkflow"; Path = "Unity-Claude-IntegratedWorkflow" }
    @{ Name = "Unity-Claude-Learning"; Path = "Unity-Claude-Learning" }
    @{ Name = "Unity-Claude-RunspaceManagement"; Path = "Unity-Claude-RunspaceManagement" }
    @{ Name = "Unity-Claude-PredictiveAnalysis"; Path = "Unity-Claude-PredictiveAnalysis" }
    @{ Name = "Unity-Claude-ObsolescenceDetection"; Path = "Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection" }
    @{ Name = "Unity-Claude-AutonomousStateTracker-Enhanced"; Path = "Unity-Claude-AutonomousStateTracker-Enhanced" }
    @{ Name = "IntelligentPromptEngine"; Path = "Unity-Claude-AutonomousAgent\IntelligentPromptEngine" }
    @{ Name = "Unity-Claude-DocumentationAutomation"; Path = "Unity-Claude-DocumentationAutomation" }
    @{ Name = "Unity-Claude-CLIOrchestrator"; Path = "Unity-Claude-CLIOrchestrator" }
    @{ Name = "Unity-Claude-ScalabilityEnhancements"; Path = "Unity-Claude-ScalabilityEnhancements" }
    @{ Name = "DecisionEngine"; Path = "Unity-Claude-CLIOrchestrator\Core\DecisionEngine" }
    @{ Name = "DecisionEngine-Bayesian"; Path = "Unity-Claude-CLIOrchestrator\Core\DecisionEngine-Bayesian" }
    @{ Name = "Unity-Claude-HITL"; Path = "Unity-Claude-HITL" }
    @{ Name = "Unity-Claude-ParallelProcessor"; Path = "Unity-Claude-ParallelProcessor" }
    @{ Name = "Unity-Claude-PerformanceOptimizer"; Path = "Unity-Claude-PerformanceOptimizer" }
    @{ Name = "Unity-Claude-DecisionEngine"; Path = "Unity-Claude-DecisionEngine" }
)

$results = @{
    Pass = 0
    Fail = 0
    Skip = 0
    Details = @()
}

foreach ($module in $modules) {
    $status = "Unknown"
    $error = $null
    
    # Clean up any existing module
    Get-Module $module.Name -All | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Build manifest path
    $manifestPath = Join-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules" "$($module.Path)\$($module.Name).psd1"
    
    if (Test-Path $manifestPath) {
        try {
            # Try to import the module
            $null = Import-Module $manifestPath -Force -ErrorAction Stop 2>&1
            $status = "PASS"
            $results.Pass++
            Write-Host "[✓] $($module.Name)" -ForegroundColor Green
        } catch {
            $status = "FAIL"
            $error = $_.Exception.Message
            $results.Fail++
            Write-Host "[✗] $($module.Name)" -ForegroundColor Red
            Write-Host "    Error: $($error -split "`n" | Select-Object -First 1)" -ForegroundColor DarkRed
        }
    } else {
        $status = "SKIP"
        $error = "Manifest not found"
        $results.Skip++
        Write-Host "[−] $($module.Name) (no manifest)" -ForegroundColor Yellow
    }
    
    $results.Details += @{
        Module = $module.Name
        Path = $module.Path
        Status = $status
        Error = $error
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           SUMMARY                      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$total = $modules.Count
$successRate = if ($total -gt 0) { [math]::Round(($results.Pass / $total) * 100, 1) } else { 0 }

Write-Host "`nTotal Modules: $total"
Write-Host "Passed: " -NoNewline
Write-Host "$($results.Pass)" -ForegroundColor Green
Write-Host "Failed: " -NoNewline
if ($results.Fail -gt 0) {
    Write-Host "$($results.Fail)" -ForegroundColor Red
} else {
    Write-Host "$($results.Fail)" -ForegroundColor Green
}
Write-Host "Skipped: " -NoNewline
Write-Host "$($results.Skip)" -ForegroundColor Yellow

Write-Host "`nSuccess Rate: " -NoNewline
if ($successRate -ge 80) {
    Write-Host "$successRate%" -ForegroundColor Green
} elseif ($successRate -ge 60) {
    Write-Host "$successRate%" -ForegroundColor Yellow
} else {
    Write-Host "$successRate%" -ForegroundColor Red
}

# Show failed modules for quick reference
if ($results.Fail -gt 0) {
    Write-Host "`nFailed Modules:" -ForegroundColor Red
    $results.Details | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Module)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan

# Return success if majority pass
return ($results.Pass -ge ($total * 0.8))
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB7Edlgw7ncnRTi
# mmlacKwetQsrLL6CKhGDoycrvI53UaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAaeCYn/CH8cwUAzPQu7S9c4
# KSYQlQaPmihzBA/HtrAYMA0GCSqGSIb3DQEBAQUABIIBAFcATUHmZgeXMFOEVQiE
# mKu0uwV/QEJ9JDwm3FEJYWtN4YunBTzuLThEMK9qvZAff/lhaw/+JjOW1awuZ0KX
# CyxaprNZwMMc6U0XtcOLXLapeeg7oEVU9RKX9NpwmlTtRURBwj0BQ4x0pENwtA+R
# iix1Z/OItQFlg+XW2iaVeCG1vqpfhl81fPL6zpXpRH830ZGt8qMeee/rbsaJzywu
# PpOn2WcsJs4oAv9Ji6M/1+No2SDMnKP6xujdBrispIhNiZkSwW3pUFaEAF1eU8/d
# FcBB0EnLV/dsxarB8EAkA8aYhYQ+9ZAttPVnn+Wa0+cdGNDRbvivg8bOmG/R1vgW
# HVY=
# SIG # End signature block
