function Submit-ErrorToClaude {
    <#
    .SYNOPSIS
    Submits error context to Claude for analysis and fix generation
    
    .DESCRIPTION
    Formats error context and file content for Claude, submits for analysis,
    and extracts the suggested fix from Claude's response
    
    .PARAMETER Context
    Hashtable containing error context, file content, and environment info
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    Write-FixEngineLog -Message "Submitting error to Claude for analysis" -Level "DEBUG"
    
    $result = @{
        Success = $false
        Response = ""
        ExtractedFix = ""
        Error = ""
        ExecutionTime = 0
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Format error context for Claude
        $prompt = Format-ClaudePrompt -Context $Context
        
        Write-FixEngineLog -Message "Formatted prompt for Claude (length: $($prompt.Length) chars)" -Level "DEBUG"
        
        # Submit to Claude using existing automation infrastructure
        $claudeResponse = Invoke-ClaudeSubmission -Prompt $prompt
        
        if ($claudeResponse.Success) {
            $result.Response = $claudeResponse.Response
            
            # Extract the fix from Claude's response
            $extractedFix = Extract-FixFromResponse -Response $claudeResponse.Response
            $result.ExtractedFix = $extractedFix
            $result.Success = ($extractedFix -ne "")
            
            if ($result.Success) {
                Write-FixEngineLog -Message "Successfully extracted fix from Claude response" -Level "INFO"
            } else {
                $result.Error = "Could not extract actionable fix from Claude's response"
                Write-FixEngineLog -Message $result.Error -Level "WARN"
            }
        } else {
            $result.Error = $claudeResponse.Error
            Write-FixEngineLog -Message "Claude submission failed: $($result.Error)" -Level "ERROR"
        }
    }
    catch {
        $result.Error = "Exception in Claude submission: $_"
        Write-FixEngineLog -Message $result.Error -Level "ERROR"
    }
    finally {
        $stopwatch.Stop()
        $result.ExecutionTime = $stopwatch.ElapsedMilliseconds
    }
    
    return $result
}

function Format-ClaudePrompt {
    <#
    .SYNOPSIS
    Formats error context into an optimal prompt for Claude
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    $prompt = @"
I need help fixing a Unity C# compilation error. Please analyze the error and provide a specific fix.

**Error Details:**
- File: $($Context.FilePath)
- Error Message: $($Context.ErrorMessage)
- Line Number: $($Context.LineNumber)
- Unity Version: $($Context.UnityVersion)

**File Content:**
``````csharp
$($Context.FileContent)
``````

**Additional Context:**
- Project uses Unity $($Context.UnityVersion) with .NET Standard 2.0
- File is located in: $($Context.RelativeFilePath)
- Project structure context: $($Context.ProjectContext)

**Request:**
Please provide:
1. A brief analysis of what's causing the error
2. The exact fix needed (code changes, using statements, etc.)
3. The corrected version of the problematic section

Format your response with clear sections so I can extract the fix programmatically.
Use ```csharp code blocks for any code you provide.
"@

    return $prompt
}

function Invoke-ClaudeSubmission {
    <#
    .SYNOPSIS
    Submits prompt to Claude using existing automation infrastructure
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )
    
    Write-FixEngineLog -Message "Invoking Claude submission" -Level "DEBUG"
    
    try {
        # Save prompt to file for submission
        $promptPath = Join-Path $env:TEMP "claude_fix_prompt_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Set-Content -Path $promptPath -Value $Prompt -Encoding UTF8
        
        # Check if we have API or CLI automation available
        $apiScript = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\API-Integration\Submit-ErrorsToClaude-API.ps1"
        $cliScript = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\CLI-Automation\Submit-ErrorsToClaude-Final.ps1"
        
        if (Test-Path $apiScript) {
            Write-FixEngineLog -Message "Using API integration for Claude submission" -Level "DEBUG"
            
            # Use API integration (preferred)
            $response = & $apiScript -CustomPromptPath $promptPath -NoErrorExport
            
            if ($response -and $response.Length -gt 0) {
                return @{
                    Success = $true
                    Response = $response
                    Method = "API"
                }
            }
        }
        
        if (Test-Path $cliScript) {
            Write-FixEngineLog -Message "Using CLI integration for Claude submission" -Level "DEBUG"
            
            # Fall back to CLI integration
            $response = & $cliScript -CustomPromptPath $promptPath
            
            if ($response -and $response.Length -gt 0) {
                return @{
                    Success = $true
                    Response = $response
                    Method = "CLI"
                }
            }
        }
        
        # If no automation available, save prompt for manual submission
        Write-FixEngineLog -Message "No Claude automation available. Saving prompt for manual submission." -Level "WARN"
        $manualPromptPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\claude_fix_prompt_manual.txt"
        Copy-Item -Path $promptPath -Destination $manualPromptPath -Force
        
        return @{
            Success = $false
            Error = "No Claude automation available. Prompt saved to: $manualPromptPath"
            Method = "Manual"
        }
    }
    catch {
        Write-FixEngineLog -Message "Claude submission failed: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = "Claude submission exception: $_"
        }
    }
    finally {
        # Clean up temporary prompt file
        if (Test-Path $promptPath) {
            Remove-Item $promptPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Extract-FixFromResponse {
    <#
    .SYNOPSIS
    Extracts actionable fix code from Claude's response
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Response
    )
    
    Write-FixEngineLog -Message "Extracting fix from Claude response" -Level "DEBUG"
    
    # Look for code blocks in Claude's response
    $codeBlockPattern = '```(?:csharp|cs|c#)?\s*\n(.*?)\n```'
    $matches = [regex]::Matches($Response, $codeBlockPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    if ($matches.Count -gt 0) {
        # Take the largest code block (likely the complete fix)
        $largestCodeBlock = ""
        foreach ($match in $matches) {
            $codeContent = $match.Groups[1].Value.Trim()
            if ($codeContent.Length -gt $largestCodeBlock.Length) {
                $largestCodeBlock = $codeContent
            }
        }
        
        if ($largestCodeBlock.Length -gt 0) {
            Write-FixEngineLog -Message "Extracted code block with $($largestCodeBlock.Length) characters" -Level "DEBUG"
            return $largestCodeBlock
        }
    }
    
    # If no code blocks found, look for using statements or simple fixes
    $usingPattern = 'using\s+[\w\.]+;'
    $usingMatches = [regex]::Matches($Response, $usingPattern)
    
    if ($usingMatches.Count -gt 0) {
        $usingStatements = $usingMatches | ForEach-Object { $_.Value } | Sort-Object -Unique
        $fix = $usingStatements -join "`n"
        Write-FixEngineLog -Message "Extracted using statements: $($usingStatements.Count)" -Level "DEBUG"
        return $fix
    }
    
    Write-FixEngineLog -Message "Could not extract actionable fix from Claude response" -Level "WARN"
    return ""
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2muDwDTuOc7GGTikf6htCMIo
# 4T+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUU+wEm3rurrm08vyPsMImjoIIh3UwDQYJKoZIhvcNAQEBBQAEggEAp+wx
# Wmob3ZckbxDCT0SNntDwaMsjVy0qtYkJHE+IWbv+HB6mvBx+o4DFtl7MlSCnyDdQ
# x15nF8TxcqPS2UaIGaq55/8RBvreH9qUOFll4VfMlVYLUMhxuBfx3egNgiYwNCp/
# zji5GkdSMNdQB02oNPkUS8mWDwRUNzXQCxETUbqx8fOn2rOCWSOTafUWUaXppz+N
# eEysJ2vW+Uy6ZrClQ6yUeqhmmVt4UHPgMHSRWFtApGV35uOfpwLU83j1oqeC9wfU
# Oo2pe4RaKoKJpSDHvWCjL0OMq0pNRU/9SrSPqvAGHvSn1lnBItMKfMEnNNWa6SCB
# L963tdMBICQzl1Uv8w==
# SIG # End signature block
