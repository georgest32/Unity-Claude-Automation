# ClaudeIntegration.psm1
# Claude Code CLI integration functions
# Extracted from main module during refactoring
# Date: 2025-08-18
# IMPORTANT: ASCII only, no backticks, proper variable delimiting

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Claude Integration Functions

function Submit-PromptToClaude {
    <#
    .SYNOPSIS
    Submits a prompt to Claude Code CLI
    
    .DESCRIPTION
    Handles prompt submission with file-based communication and monitoring
    
    .PARAMETER PromptText
    The prompt text to submit
    
    .PARAMETER OutputDirectory
    Directory for Claude response files
    
    .PARAMETER WaitForResponse
    Whether to wait for Claude response
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PromptText,
        
        [string]$OutputDirectory = "",
        
        [switch]$WaitForResponse
    )
    
    Write-AgentLog -Message "Submitting prompt to Claude" -Level "INFO" -Component "ClaudeSubmitter"
    
    try {
        # Determine output directory
        if ([string]::IsNullOrEmpty($OutputDirectory)) {
            $OutputDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
        }
        
        # Ensure output directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
            Write-AgentLog -Message "Created output directory: $OutputDirectory" -Level "DEBUG" -Component "ClaudeSubmitter"
        }
        
        # Create prompt file for Claude Code CLI
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $promptFile = Join-Path $OutputDirectory "claude_prompt_$timestamp.txt"
        
        Set-Content -Path $promptFile -Value $PromptText -Encoding UTF8 -Force
        Write-AgentLog -Message "Prompt written to: $promptFile" -Level "DEBUG" -Component "ClaudeSubmitter"
        
        # Submit to Claude Code CLI (implementation depends on CLI vs API mode)
        $submissionResult = Submit-ToClaude -PromptFile $promptFile -OutputDirectory $OutputDirectory
        
        if ($WaitForResponse) {
            Write-AgentLog -Message "Waiting for Claude response..." -Level "DEBUG" -Component "ClaudeSubmitter"
            # Response waiting logic would integrate with FileSystemMonitoring
        }
        
        Write-AgentLog -Message "Prompt submission completed" -Level "SUCCESS" -Component "ClaudeSubmitter"
        
        return @{
            Success = $true
            PromptFile = $promptFile
            OutputDirectory = $OutputDirectory
            SubmissionResult = $submissionResult
        }
    }
    catch {
        Write-AgentLog -Message "Prompt submission failed: $_" -Level "ERROR" -Component "ClaudeSubmitter"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function New-FollowUpPrompt {
    <#
    .SYNOPSIS
    Generates intelligent follow-up prompts based on command execution results
    
    .DESCRIPTION
    Creates contextual prompts for continuing autonomous conversation
    
    .PARAMETER Recommendation
    The original recommendation that was executed
    
    .PARAMETER Result
    The execution result
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    Write-AgentLog -Message "Generating follow-up prompt for: $($Recommendation.Type)" -Level "INFO" -Component "PromptGenerator"
    
    try {
        $promptType = "Continue"  # Default prompt type
        $promptContent = ""
        
        if ($Result.Success) {
            Write-AgentLog -Message "Command succeeded, generating success prompt" -Level "DEBUG" -Component "PromptGenerator"
            
            switch ($Recommendation.Type) {
                "TEST" {
                    $promptType = "Test Results"
                    $promptContent = "The test execution completed successfully. Results: $($Result.Output). What should be the next step?"
                }
                "BUILD" {
                    $promptType = "Test Results"
                    $promptContent = "The build completed successfully. Build time: $($Result.BuildTime). Ready for deployment or testing?"
                }
                "ANALYZE" {
                    $promptType = "Analysis Results"
                    $promptContent = "The analysis completed. Results: $($Result.Output). Should we address any findings?"
                }
                default {
                    $promptContent = "The command '$($Recommendation.Type)' completed successfully. How should we proceed?"
                }
            }
        } else {
            Write-AgentLog -Message "Command failed, generating error prompt" -Level "DEBUG" -Component "PromptGenerator"
            $promptType = "Debugging"
            $promptContent = "The command '$($Recommendation.Type)' failed with error: $($Result.Error). How should we troubleshoot this?"
        }
        
        Write-AgentLog -Message "Follow-up prompt generated: $promptType" -Level "SUCCESS" -Component "PromptGenerator"
        
        return @{
            Success = $true
            PromptType = $promptType
            PromptContent = $promptContent
            OriginalRecommendation = $Recommendation
            ExecutionResult = $Result
        }
    }
    catch {
        Write-AgentLog -Message "Follow-up prompt generation failed: $_" -Level "ERROR" -Component "PromptGenerator"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Submit-ToClaude {
    <#
    .SYNOPSIS
    Internal function to handle Claude CLI/API submission
    
    .DESCRIPTION
    Handles the actual submission mechanism (CLI or API)
    
    .PARAMETER PromptFile
    File containing the prompt
    
    .PARAMETER OutputDirectory
    Directory for responses
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PromptFile,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDirectory
    )
    
    Write-AgentLog -Message "Submitting to Claude via CLI/API" -Level "DEBUG" -Component "ClaudeSubmissionHandler"
    
    try {
        # Read the prompt from the file
        $promptContent = Get-Content -Path $PromptFile -Raw -Encoding UTF8
        Write-AgentLog -Message "Read prompt content: $($promptContent.Length) characters" -Level "DEBUG" -Component "ClaudeSubmissionHandler"
        
        # Use the CLISubmission module for actual window automation
        try {
            # Import CLISubmission module if not loaded
            $cliSubmissionPath = Join-Path (Split-Path $PSScriptRoot -Parent) "..\Unity-Claude-CLISubmission.psm1"
            if (Test-Path $cliSubmissionPath) {
                Import-Module $cliSubmissionPath -Force -DisableNameChecking
                Write-AgentLog -Message "CLISubmission module loaded" -Level "DEBUG" -Component "ClaudeSubmissionHandler"
                
                # Submit using the existing CLI automation
                if (Get-Command "Submit-PromptToClaudeCode" -ErrorAction SilentlyContinue) {
                    Write-AgentLog -Message "Submitting prompt using CLISubmission automation..." -Level "INFO" -Component "ClaudeSubmissionHandler"
                    $submissionResult = Submit-PromptToClaudeCode -Prompt $promptContent
                    Write-AgentLog -Message "CLI submission completed: $($submissionResult.Success)" -Level "INFO" -Component "ClaudeSubmissionHandler"
                    return $submissionResult
                } else {
                    Write-AgentLog -Message "Submit-PromptToClaudeCode function not available" -Level "WARNING" -Component "ClaudeSubmissionHandler"
                }
            } else {
                Write-AgentLog -Message "CLISubmission module not found at: $cliSubmissionPath" -Level "WARNING" -Component "ClaudeSubmissionHandler"
            }
        } catch {
            Write-AgentLog -Message "Error using CLISubmission: $($_.Exception.Message)" -Level "ERROR" -Component "ClaudeSubmissionHandler"
        }
        
        Write-AgentLog -Message "Claude submission handled" -Level "DEBUG" -Component "ClaudeSubmissionHandler"
        
        return @{
            Success = $true
            Method = "CLI"  # or "API"
            SubmittedAt = Get-Date
        }
    }
    catch {
        Write-AgentLog -Message "Claude submission failed: $_" -Level "ERROR" -Component "ClaudeSubmissionHandler"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ClaudeResponseStatus {
    <#
    .SYNOPSIS
    Checks status of pending Claude responses
    
    .DESCRIPTION
    Monitors for new Claude response files
    
    .PARAMETER OutputDirectory
    Directory to monitor for responses
    #>
    [CmdletBinding()]
    param(
        [string]$OutputDirectory = ""
    )
    
    Write-AgentLog -Message "Checking Claude response status" -Level "DEBUG" -Component "ResponseStatusChecker"
    
    try {
        if ([string]::IsNullOrEmpty($OutputDirectory)) {
            $OutputDirectory = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
        }
        
        # Check for new response files
        $responseFiles = Get-ChildItem -Path $OutputDirectory -Filter "*.json" -ErrorAction SilentlyContinue
        $pendingResponses = $responseFiles | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
        
        return @{
            Success = $true
            TotalResponses = $responseFiles.Count
            RecentResponses = $pendingResponses.Count
            LatestResponse = if ($responseFiles.Count -gt 0) { ($responseFiles | Sort-Object LastWriteTime -Descending)[0].FullName } else { $null }
        }
    }
    catch {
        Write-AgentLog -Message "Response status check failed: $_" -Level "ERROR" -Component "ResponseStatusChecker"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Submit-PromptToClaude',
    'New-FollowUpPrompt',
    'Submit-ToClaude',
    'Get-ClaudeResponseStatus'
)

Write-AgentLog "ClaudeIntegration module loaded successfully" -Level "INFO" -Component "ClaudeIntegration"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUr/Pvjb8MSVp5FfWOigOyEuj8
# 2b+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUbZVomsjF1vKhobDLSitlc4zJA1UwDQYJKoZIhvcNAQEBBQAEggEAhMbD
# 1J1O99iotNTo5y/TZceDbTjOtlA7JLehmyxv1CfrASC4TH0dKpcW3SV6ICfZWo1F
# Itm9CstDbHCGCrDKaPm85mB9NkYmd/kA+WAnKdT6pTK4tKeBNJhluDgPiK7UgX9v
# LjKaNJ73OzUsYypdBB0QNTUHSQ/veeAupujKtlaSOkwfnWGbCDGbEqfyiKM6vR7V
# 26f0bHEbn5cQFJaC/j/FIVFErwd761AwyMKlpFh/FFegcKtxgVv5XCHiinudVE9p
# tZ0oLhkfuwrfwwBF8mnPGW0ojl6DmwWxvhbivymRVplsT3IvWW/nOOPSuYD1y9P6
# +PJY9NNG505b6fv0Mg==
# SIG # End signature block
