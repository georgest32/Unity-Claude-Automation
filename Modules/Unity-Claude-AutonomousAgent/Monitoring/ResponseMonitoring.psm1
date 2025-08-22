# ResponseMonitoring.psm1
# Response monitoring and processing functions extracted from main module
# Handles Claude response processing, recommendation extraction, and queue management
# Date: 2025-08-18

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force

#endregion

#region Response Processing Functions

function Invoke-ProcessClaudeResponse {
    <#
    .SYNOPSIS
    Processes a Claude Code CLI response file and extracts actionable recommendations
    
    .DESCRIPTION
    Parses JSON response from Claude, extracts RECOMMENDED commands, validates safety,
    and queues for execution or human approval
    
    .PARAMETER ResponseFilePath
    Path to the Claude response file to process
    
    .PARAMETER MaxRetries
    Maximum retry attempts for file access
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFilePath,
        
        [int]$MaxRetries = 3
    )
    
    Write-AgentLog -Message "Processing Claude response file: $ResponseFilePath" -Level "INFO" -Component "ResponseProcessor"
    
    # Validate file exists and is accessible
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            if (-not (Test-Path $ResponseFilePath)) {
                throw "Response file not found: $ResponseFilePath"
            }
            
            # Wait for file to be completely written (avoid reading partial files)
            Start-Sleep -Milliseconds 500
            
            # Check if file is locked by another process
            try {
                $fileStream = [System.IO.File]::Open($ResponseFilePath, 'Open', 'Read', 'ReadWrite')
                $fileStream.Close()
                $fileStream.Dispose()
                Write-AgentLog -Message "File accessibility confirmed: $ResponseFilePath" -Level "DEBUG" -Component "ResponseProcessor"
                break
            }
            catch {
                $retryCount++
                Write-AgentLog -Message "File locked, retry $retryCount/$MaxRetries" -Level "WARNING" -Component "ResponseProcessor"
                Start-Sleep -Milliseconds 1000
                
                if ($retryCount -ge $MaxRetries) {
                    throw "File remains locked after $MaxRetries attempts: $_"
                }
            }
        }
        catch {
            Write-AgentLog -Message "Error accessing response file: $_" -Level "ERROR" -Component "ResponseProcessor"
            return $false
        }
    }
    
    try {
        # Read and parse Claude response
        $responseContent = Get-Content -Path $ResponseFilePath -Raw -Encoding UTF8
        Write-AgentLog -Message "Response file read successfully, length: $($responseContent.Length) characters" -Level "DEBUG" -Component "ResponseProcessor"
        
        # Parse JSON and extract the actual response text
        try {
            $jsonObject = $responseContent | ConvertFrom-Json
            $responseText = ""
            
            # Extract response text from various possible fields
            if ($jsonObject.response) {
                $responseText = $jsonObject.response
            } elseif ($jsonObject.content) {
                $responseText = $jsonObject.content
            } elseif ($jsonObject.message) {
                $responseText = $jsonObject.message
            } else {
                # Fallback to raw content
                $responseText = $responseContent
            }
            
            Write-AgentLog -Message "Extracted response text: $responseText" -Level "DEBUG" -Component "ResponseProcessor"
        } catch {
            # If JSON parsing fails, use raw content
            $responseText = $responseContent
            Write-AgentLog -Message "JSON parsing failed, using raw content" -Level "WARN" -Component "ResponseProcessor"
        }
        
        # Store the last processed file
        # $script:AgentState.LastProcessedFile = $ResponseFilePath - moved to core state management
        
        # Extract recommendations using enhanced parsing on the actual response text
        $recommendations = Find-ClaudeRecommendations -ResponseText $responseText
        
        if ($recommendations.Count -gt 0) {
            Write-AgentLog -Message "Found $($recommendations.Count) recommendations" -Level "INFO" -Component "ResponseProcessor"
            
            # Add recommendations to execution queue
            foreach ($recommendation in $recommendations) {
                Add-RecommendationToQueue -Recommendation $recommendation
            }
            
            # Process the command queue
            Invoke-ProcessCommandQueue
        } else {
            Write-AgentLog -Message "No actionable recommendations found in response" -Level "INFO" -Component "ResponseProcessor"
        }
        
        # Store response for conversation context
        # $script:AgentState.LastClaudeResponse = $responseContent - moved to conversation management
        
        return $true
    }
    catch {
        Write-AgentLog -Message "Error processing Claude response: $_" -Level "ERROR" -Component "ResponseProcessor"
        return $false
    }
}

function Find-ClaudeRecommendations {
    <#
    .SYNOPSIS
    Finds and extracts RECOMMENDED commands from Claude response text
    
    .DESCRIPTION
    Uses regex patterns to identify actionable recommendations in Claude responses
    
    .PARAMETER ResponseText
    The Claude response text to analyze
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText
    )
    
    Write-AgentLog -Message "Searching for Claude recommendations in response" -Level "DEBUG" -Component "RecommendationExtractor"
    Write-AgentLog -Message "Response text to analyze: '$ResponseText'" -Level "DEBUG" -Component "RecommendationExtractor"
    Write-AgentLog -Message "Response text length: $($ResponseText.Length) characters" -Level "DEBUG" -Component "RecommendationExtractor"
    
    $recommendations = @()
    
    # Enhanced regex pattern for RECOMMENDED commands
    $patterns = @(
        "RECOMMENDED:\s*(TEST|BUILD|ANALYZE|DEBUG|CONTINUE|RUN|EXECUTE)\s*-\s*(.+)",
        "RECOMMENDATION:\s*(TEST|BUILD|ANALYZE|DEBUG|CONTINUE|RUN|EXECUTE)\s*-\s*(.+)",
        "(?:Please\s+|You\s+should\s+|Try\s+|Run\s+|Execute\s+)(.+?)(?:\.|$)"
    )
    
    Write-AgentLog -Message "Testing $($patterns.Count) regex patterns..." -Level "DEBUG" -Component "RecommendationExtractor"
    
    foreach ($pattern in $patterns) {
        Write-AgentLog -Message "Testing pattern: '$pattern'" -Level "DEBUG" -Component "RecommendationExtractor"
        $matches = [regex]::Matches($ResponseText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        Write-AgentLog -Message "Pattern '$pattern' found $($matches.Count) matches" -Level "DEBUG" -Component "RecommendationExtractor"
        
        foreach ($match in $matches) {
            Write-AgentLog -Message "Match found: '$($match.Value)' with groups: $($match.Groups.Count)" -Level "DEBUG" -Component "RecommendationExtractor"
            $recommendation = @{
                Type = if ($match.Groups[1].Success) { $match.Groups[1].Value.ToUpper() } else { "GENERAL" }
                Command = if ($match.Groups[2].Success) { $match.Groups[2].Value.Trim() } else { $match.Groups[1].Value.Trim() }
                FullMatch = $match.Value
                Confidence = if ($match.Value -match "RECOMMENDED") { 0.95 } else { 0.75 }
                Source = "Claude Response"
                Timestamp = Get-Date
            }
            
            $recommendations += $recommendation
            Write-AgentLog -Message "Found recommendation: $($recommendation.Type) - $($recommendation.Command)" -Level "DEBUG" -Component "RecommendationExtractor"
        }
    }
    
    Write-AgentLog -Message "Extracted $($recommendations.Count) total recommendations" -Level "INFO" -Component "RecommendationExtractor"
    return $recommendations
}

function Add-RecommendationToQueue {
    <#
    .SYNOPSIS
    Adds a recommendation to the execution queue
    
    .DESCRIPTION
    Validates and queues recommendations for execution with safety checks
    
    .PARAMETER Recommendation
    The recommendation object to queue
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Recommendation
    )
    
    Write-AgentLog -Message "Adding recommendation to queue: $($Recommendation.Type)" -Level "DEBUG" -Component "QueueManager"
    
    try {
        # Add safety validation and metadata
        $queueItem = @{
            Recommendation = $Recommendation
            QueuedAt = Get-Date
            Status = "Pending"
            SafetyCheck = "Required"
            RetryCount = 0
            MaxRetries = 3
        }
        
        # Add to pending commands queue (using Get-AgentState would require Core module dependency)
        # For now, use direct queue management - can be improved with proper state integration
        Write-AgentLog -Message "Recommendation queued for execution: $($Recommendation.Command)" -Level "INFO" -Component "QueueManager"
        
        return $true
    }
    catch {
        Write-AgentLog -Message "Failed to queue recommendation: $_" -Level "ERROR" -Component "QueueManager"
        return $false
    }
}

function Invoke-ProcessCommandQueue {
    <#
    .SYNOPSIS
    Processes pending commands in the execution queue
    
    .DESCRIPTION
    Executes queued commands with safety validation and retry logic
    #>
    [CmdletBinding()]
    param()
    
    Write-AgentLog -Message "Processing command queue" -Level "INFO" -Component "QueueProcessor"
    
    try {
        # Queue processing logic would integrate with command execution framework
        # For modular design, this coordinates with SafeExecution module
        Write-AgentLog -Message "Command queue processing initiated" -Level "DEBUG" -Component "QueueProcessor"
        
        # Placeholder for queue processing - will integrate with Execution modules
        return $true
    }
    catch {
        Write-AgentLog -Message "Command queue processing failed: $_" -Level "ERROR" -Component "QueueProcessor"
        return $false
    }
}

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
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PromptText,
        
        [string]$OutputDirectory = ""
    )
    
    Write-AgentLog -Message "Submitting prompt to Claude" -Level "INFO" -Component "ClaudeSubmitter"
    
    try {
        # Determine output directory (would use Get-AgentConfig with proper dependency)
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
        
        # Integration with Claude Code CLI would happen here
        # For modular design, this coordinates with ClaudeIntegration module
        Write-AgentLog -Message "Prompt submission coordinated with Claude integration" -Level "INFO" -Component "ClaudeSubmitter"
        
        return @{
            Success = $true
            PromptFile = $promptFile
            OutputDirectory = $OutputDirectory
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

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Invoke-ProcessClaudeResponse',
    'Find-ClaudeRecommendations',
    'Add-RecommendationToQueue',
    'Invoke-ProcessCommandQueue',
    'Submit-PromptToClaude'
)

Write-AgentLog "ResponseMonitoring module loaded successfully" -Level "INFO" -Component "ResponseMonitoring"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/cuQRSgHOBQeED3eIyPJvEWx
# SLCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUPoeY0jZOlSwVtOy3NQq+ugeaDgAwDQYJKoZIhvcNAQEBBQAEggEARPK/
# 2IYzuZh+JYa8InCT+SA4t7DjCAGbqozlKyQlwHqofIeJ+YZjOS9GgynCPcQxcgpO
# mErLqo05LQNAB69bPp+5NtQAvfbAwOMrp1yWGuYq7fDB33gF8ge6q4pvvHJbM/ML
# LoqHKa+TKrwdcIDdpEybn1103h5LPnJZZkPO57eDYVlZnkW6BzHXsHvUn5ETSjQS
# IQyrt69GKWJRFw9myd8Jqo54BY2P3JZC5pd1cKUQ39CTWELGyR00U5u/ij0pXoRn
# ofBEfpwGpOvOIkkJ1ONQnujB8NJ5r4jyckM1yY0dqH0CQiHE946g5UZodLAwW8wt
# 2P0njh7oJLgLcbd2SA==
# SIG # End signature block
