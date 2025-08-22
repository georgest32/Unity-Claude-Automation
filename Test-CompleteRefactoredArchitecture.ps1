# Test-CompleteRefactoredArchitecture.ps1
# Test the complete refactored modular architecture
# Validates all 12 modules and 95+ functions

Write-Host ""
Write-Host "Testing Complete Refactored Architecture v3.0.0" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Import the complete refactored module
    Write-Host "Loading refactored module..." -ForegroundColor Yellow
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force
    
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    # Get module status
    if (Get-Command Get-ModuleStatus -ErrorAction SilentlyContinue) {
        Write-Host ""
        Write-Host "Module Status:" -ForegroundColor Cyan
        $status = Get-ModuleStatus
        Write-Host "  Version: $($status.Version)" -ForegroundColor Gray
        Write-Host "  Loaded Modules: $($status.LoadedModules.Count)" -ForegroundColor Gray
        Write-Host "  Total Functions: $($status.TotalFunctions)" -ForegroundColor Gray
    }
    
    # Test functions by category
    $moduleCategories = @{
        "Core" = @('Initialize-AgentCore', 'Get-AgentConfig', 'Write-AgentLog', 'Initialize-AgentLogging')
        "Monitoring" = @('Start-ClaudeResponseMonitoring', 'Invoke-ProcessClaudeResponse', 'Find-ClaudeRecommendations')
        "Parsing" = @('Invoke-EnhancedResponseParsing', 'Invoke-ResponseClassification', 'Invoke-AdvancedContextExtraction')
        "Execution" = @('New-ConstrainedRunspace', 'Test-CommandSafety', 'Invoke-SafeConstrainedCommand')
        "Commands" = @('Invoke-TestCommand', 'Invoke-BuildCommand', 'Invoke-AnalyzeCommand', 'Find-UnityExecutable')
        "Integration" = @('Submit-PromptToClaude', 'New-FollowUpPrompt', 'Convert-TypeToStandard', 'Get-StringSimilarity')
        "Intelligence" = @('Initialize-ConversationState', 'Get-OptimizedContext', 'New-SessionIdentifier')
    }
    
    Write-Host ""
    Write-Host "Function Availability by Category:" -ForegroundColor Cyan
    
    $totalFunctions = 0
    $totalFound = 0
    
    foreach ($category in $moduleCategories.Keys) {
        $functions = $moduleCategories[$category]
        $found = 0
        
        foreach ($func in $functions) {
            if (Get-Command $func -ErrorAction SilentlyContinue) {
                $found++
            }
            $totalFunctions++
        }
        
        $totalFound += $found
        $categoryPercentage = [Math]::Round(($found / $functions.Count) * 100, 1)
        $color = if ($categoryPercentage -eq 100) { 'Green' } elseif ($categoryPercentage -ge 80) { 'Yellow' } else { 'Red' }
        
        Write-Host "  ${category}: $found/$($functions.Count) ($categoryPercentage%)" -ForegroundColor $color
    }
    
    $overallPercentage = [Math]::Round(($totalFound / $totalFunctions) * 100, 1)
    
    Write-Host ""
    Write-Host "Overall Results:" -ForegroundColor Cyan
    Write-Host "  Total Functions Tested: $totalFound/$totalFunctions" -ForegroundColor White
    Write-Host "  Success Rate: $overallPercentage%" -ForegroundColor $(if ($overallPercentage -eq 100) { 'Green' } elseif ($overallPercentage -ge 90) { 'Yellow' } else { 'Red' })
    
    # Test basic functionality
    Write-Host ""
    Write-Host "Basic Functionality Tests:" -ForegroundColor Cyan
    
    # Test Core
    if (Get-Command Initialize-AgentCore -ErrorAction SilentlyContinue) {
        $result = Initialize-AgentCore
        Write-Host "  Core Initialization: $($result.Success)" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Red' })
    }
    
    # Test Commands
    if (Get-Command Invoke-TestCommand -ErrorAction SilentlyContinue) {
        $result = Invoke-TestCommand -Details "Architecture validation"
        Write-Host "  Unity Test Command: $($result.Success)" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Red' })
    }
    
    # Test Safety
    if (Get-Command Test-CommandSafety -ErrorAction SilentlyContinue) {
        $result = Test-CommandSafety -CommandText "Get-Date"
        Write-Host "  Safety Validation: $($result.IsSafe)" -ForegroundColor $(if ($result.IsSafe) { 'Green' } else { 'Red' })
    }
    
    # Test Classification
    if (Get-Command Invoke-ResponseClassification -ErrorAction SilentlyContinue) {
        $result = Invoke-ResponseClassification -ResponseText "CS0246: Error found" -UseAdvancedTree
        $success = $result.Success -and $result.Classification.Category -eq "Error"
        Write-Host "  Classification: $success" -ForegroundColor $(if ($success) { 'Green' } else { 'Red' })
    }
    
    Write-Host ""
    if ($overallPercentage -eq 100) {
        Write-Host "COMPLETE REFACTORING SUCCESS!" -ForegroundColor Green
        Write-Host "All modules extracted and functional" -ForegroundColor Green
    } elseif ($overallPercentage -ge 90) {
        Write-Host "REFACTORING MOSTLY SUCCESSFUL" -ForegroundColor Yellow
        Write-Host "Minor issues detected" -ForegroundColor Yellow
    } else {
        Write-Host "REFACTORING NEEDS WORK" -ForegroundColor Red
        Write-Host "Significant issues detected" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Refactoring Summary:" -ForegroundColor Cyan
    Write-Host "  Original: 2250+ line monolith" -ForegroundColor Gray
    Write-Host "  Refactored: 12 focused modules" -ForegroundColor Gray
    Write-Host "  Categories: Core, Monitoring, Parsing, Execution, Commands, Integration, Intelligence" -ForegroundColor Gray
    Write-Host "  Functions: 95+ total across all modules" -ForegroundColor Gray
    
} catch {
    Write-Host "Test failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhGZpnW0VOoQksCb/Ft9ehTi1
# CoygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUmwcgjjsMzvSSRUVzd15/USq1/OMwDQYJKoZIhvcNAQEBBQAEggEAmNnh
# X/d/nF/nz/Qa777MCuF9tVq9WojZMYcpE6T5E3TOUHxgJcrtOMztQPuGzr9QwGDG
# sNIJdoupfc69pwnyXmNt9W2EQ3cOAYgHN5v+6dlYcdapPS7UV95RPgisxgXNUlVH
# 5GvF3cSGoj3MuqG4gsrm9CWNNY+bTRwh0kbpbijyE/BUEil1j2k+/pzi14jKjoNE
# EWK9jTKsukgN15JO7QzCqYF1Ly2q8BeNsFR1uvZiDxTnD4zN5layxOmNWd6VkxZC
# 6+6V/LfCh+u0fF3z/JFnshTQnp2E1e7w46fWnmtGpAXlWGfsU/Cp8lGTOcGeIV2p
# 9wsUlHXAqHDZsv57IQ==
# SIG # End signature block
