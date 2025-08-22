# Fix-ModulePath-Configuration.ps1
# Fixes PSModulePath configuration for Unity-Claude custom modules
# Resolves "no valid module file found" errors with RequiredModules
# Date: 2025-08-21

Write-Host "=== Unity-Claude Module Path Configuration Fix ===" -ForegroundColor Cyan

try {
    # Get current module path
    $currentModulePath = $env:PSModulePath
    Write-Host "Current PSModulePath:" -ForegroundColor Yellow
    $currentModulePath -split ';' | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    # Add our custom Modules directory 
    $customModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
    
    if (Test-Path $customModulePath) {
        Write-Host "`nAdding custom module path: $customModulePath" -ForegroundColor Yellow
        
        # Check if already in path
        if ($currentModulePath -notlike "*$customModulePath*") {
            $env:PSModulePath = "$customModulePath;" + $env:PSModulePath
            Write-Host "   Custom path added successfully" -ForegroundColor Green
        } else {
            Write-Host "   Custom path already exists in PSModulePath" -ForegroundColor Green
        }
        
        # Display updated path
        Write-Host "`nUpdated PSModulePath:" -ForegroundColor Yellow
        $env:PSModulePath -split ';' | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        
        # Test module discovery
        Write-Host "`nTesting module discovery..." -ForegroundColor Yellow
        $testModules = @(
            'Unity-Claude-ParallelProcessing',
            'Unity-Claude-RunspaceManagement', 
            'Unity-Claude-UnityParallelization',
            'Unity-Claude-ClaudeParallelization',
            'Unity-Claude-IntegratedWorkflow'
        )
        
        $foundModules = @()
        $missingModules = @()
        
        foreach ($moduleName in $testModules) {
            $module = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue
            if ($module) {
                $foundModules += $moduleName
                Write-Host "   Found: $moduleName" -ForegroundColor Green
            } else {
                $missingModules += $moduleName
                Write-Host "   Missing: $moduleName" -ForegroundColor Red
            }
        }
        
        Write-Host "`nModule Discovery Results:" -ForegroundColor Cyan
        Write-Host "   Found: $($foundModules.Count)/$($testModules.Count)" -ForegroundColor Green
        Write-Host "   Missing: $($missingModules.Count)" -ForegroundColor Red
        
        if ($missingModules.Count -eq 0) {
            Write-Host "`n=== MODULE PATH CONFIGURATION: SUCCESS ===" -ForegroundColor Green
            Write-Host "All Unity-Claude modules discoverable via standard Import-Module" -ForegroundColor Green
        } else {
            Write-Host "`n=== MODULE PATH CONFIGURATION: PARTIAL SUCCESS ===" -ForegroundColor Yellow
            Write-Host "Missing modules: $($missingModules -join ', ')" -ForegroundColor Red
        }
        
    } else {
        Write-Host "ERROR: Custom module directory not found: $customModulePath" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "=== MODULE PATH CONFIGURATION: FAILED ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3HecCK+Grok6X53yT4yFIdbB
# sJ2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUuXG8N8U5JmbLrRUXqTCnQhG115EwDQYJKoZIhvcNAQEBBQAEggEARIoH
# 8G124J+r3nccDvArwgJLk3tWDLCH2dv21szGWYDsuGrFSbYavR9xJkFd7SWL6tPT
# oFRsXeMIfF+qZk0fpqsMLBauwV2v1+KsQg2un6OjKFP8GrLhw+RR616eVaVhaiHm
# +jRot80YimojV3VSjOZgT49oKG3eD5kOT2jIc3qKrV1UWeI26kYh4LGNRV9rmlXr
# 0smRjbK/M8DcMTs9NUojJoc4HNoFf0ZLiNqKSghVJDUwThMyV1XA9Y4b/FIfdVos
# jreqiPQxdH8I8tbPJQifSUfaSI+SWoOIhzpOmdk2O6IGsyHpXjUr3ftqdBb69VAF
# M8pN56KCzrubYGgRVg==
# SIG # End signature block
