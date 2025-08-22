# CLAUDE_CRITICAL_DIRECTIVE.ps1
# Critical directive template that ensures Claude always provides parseable responses

function Get-CriticalDirective {
    return @"

==================================================
🔴 CRITICAL DIRECTIVE - MANDATORY RESPONSE FORMAT 🔴
==================================================

YOU MUST ALWAYS END YOUR RESPONSE WITH ONE OF THESE EXACT FORMATS:

[RECOMMENDATION: CONTINUE] - If you need more information or want to continue analysis
[RECOMMENDATION: TEST <TestName>] - If a specific test should be run
[RECOMMENDATION: FIX <FileName>] - If a specific file needs fixing
[RECOMMENDATION: COMPILE] - If Unity compilation should be triggered
[RECOMMENDATION: RESTART <ModuleName>] - If a module needs restarting
[RECOMMENDATION: COMPLETE] - If the task is fully complete
[RECOMMENDATION: ERROR <Description>] - If there's an error that needs handling

CRITICAL: Your ENTIRE response will be automatically captured and processed by an autonomous agent.
The agent will parse your [RECOMMENDATION: XXX] tag and take appropriate action.

THIS IS NON-NEGOTIABLE. EVERY RESPONSE MUST END WITH A [RECOMMENDATION: XXX] TAG.

==================================================
"@
}

function Format-AutonomousPrompt {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserPrompt,
        
        [string]$Context = "",
        
        [switch]$IncludeBoilerplate
    )
    
    $criticalDirective = Get-CriticalDirective
    
    $fullPrompt = @"
$UserPrompt

$Context

$criticalDirective

REMEMBER: You MUST end your response with a [RECOMMENDATION: XXX] tag for the autonomous system to process your response correctly.
"@

    if ($IncludeBoilerplate) {
        # Include full boilerplate from CLAUDE_PROMPT_DIRECTIVES.txt
        $boilerplatePath = "C:\UnityProjects\Sound-and-Shoal\CLAUDE_PROMPT_DIRECTIVES.txt"
        if (Test-Path $boilerplatePath) {
            $boilerplate = Get-Content $boilerplatePath -Raw
            $fullPrompt = @"
$boilerplate

CURRENT TASK:
$UserPrompt

$Context

$criticalDirective
"@
        }
    }
    
    return $fullPrompt
}

# Example usage function
function Submit-AutonomousPrompt {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Context = ""
    )
    
    Write-Host "=== PREPARING AUTONOMOUS PROMPT ===" -ForegroundColor Cyan
    
    # Format the prompt with critical directive
    $formattedPrompt = Format-AutonomousPrompt -UserPrompt $Prompt -Context $Context
    
    Write-Host "FORMATTED PROMPT:" -ForegroundColor Yellow
    Write-Host $formattedPrompt -ForegroundColor Gray
    
    # Save the prompt for reference
    $promptFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\prompt_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $formattedPrompt | Set-Content $promptFile -Encoding UTF8
    
    Write-Host "`nPrompt saved to: $promptFile" -ForegroundColor Green
    
    # Load CLISubmission module if needed
    $cliModule = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLISubmission.psm1"
    if (Test-Path $cliModule) {
        Import-Module $cliModule -Force
    }
    
    # Submit the prompt
    if (Get-Command Submit-PromptToClaude -ErrorAction SilentlyContinue) {
        Write-Host "`nSubmitting to Claude..." -ForegroundColor Yellow
        $result = Submit-PromptToClaude -Prompt $formattedPrompt
        
        if ($result.Success) {
            Write-Host "✓ Prompt submitted successfully" -ForegroundColor Green
            Write-Host "The autonomous agent will detect Claude's response when it includes [RECOMMENDATION: XXX]" -ForegroundColor Cyan
        } else {
            Write-Host "✗ Failed to submit prompt: $($result.Error)" -ForegroundColor Red
        }
        
        return $result
    } else {
        Write-Host "Submit-PromptToClaude function not available!" -ForegroundColor Red
        return @{ Success = $false; Error = "Function not available" }
    }
}

# Test the critical directive
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "=== CLAUDE CRITICAL DIRECTIVE SYSTEM ===" -ForegroundColor Magenta
    Write-Host "This ensures Claude ALWAYS provides parseable recommendations" -ForegroundColor Cyan
    
    Write-Host "`nExample prompt with critical directive:" -ForegroundColor Yellow
    $example = Format-AutonomousPrompt -UserPrompt "Analyze the current Unity compilation errors and suggest fixes" -Context "There are 5 compilation errors in the SymbolicMemory module"
    
    Write-Host $example -ForegroundColor Gray
    
    Write-Host "`nTo use this system:" -ForegroundColor Green
    Write-Host "1. Call Submit-AutonomousPrompt with your prompt" -ForegroundColor White
    Write-Host "2. Claude will respond with a [RECOMMENDATION: XXX] tag at the end" -ForegroundColor White
    Write-Host "3. The autonomous agent will parse and execute the recommendation" -ForegroundColor White
    
    Export-ModuleMember -Function Get-CriticalDirective, Format-AutonomousPrompt, Submit-AutonomousPrompt
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvBHKS+wxRnHZG/6Ex/18l9CN
# K92gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU9JmhrjBeUbf5HAgjxNL5Jk/Fkt4wDQYJKoZIhvcNAQEBBQAEggEADmGR
# 9OcHTVtYWuHDbweRVIVFmnw7H7/0fwQbhbopVK31e9/RKdh8KbCfYHcn2D5tjIrl
# YFiU0UcGWRaR8mHI+2Nr2T4eycQ0XL292J/PTpHyi7LrI2i3TZlvBL3IR3Ke32Z8
# 6zOVTrvDm/xTmnhDCtMIQx8MKel3ePGquz8YboAVf4gKkHUqHm+ObHoOMEae6dT8
# QyUXtMJpeeKGsmOWoRo6Ixh01uUP2xpLc4G1ew1VGRvGz6cBqRdXgEu8ZO7reexd
# Cr5DCfBJ1fmOgyr7I20SmWQTSjtNESdeqCq0yd9E5GA8q7/PYs+pgfkc+q7Ul0uM
# etdOr96Yed+qb9KpFw==
# SIG # End signature block
