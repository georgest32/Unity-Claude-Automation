#region PromptSubmissionEngine Component
<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator - Prompt Submission Engine Component
    
.DESCRIPTION
    Handles secure and reliable prompt submission to Claude Code CLI using
    TypeKeys technology with input locking and validation.
    
.COMPONENT
    Part of Unity-Claude-CLIOrchestrator refactored architecture
    
.FUNCTIONS
    - Submit-ToClaudeViaTypeKeys: Main prompt submission function with safety measures
    - Execute-TestScript: Executes test scripts with result collection
#>
#endregion

function Submit-ToClaudeViaTypeKeys {
    <#
    .SYNOPSIS
        Submits prompt to Claude via TypeKeys with input locking and safety measures
        
    .DESCRIPTION
        Provides secure prompt submission with user abort capability, window validation,
        and input blocking to prevent interference during submission
        
    .PARAMETER PromptText
        The text prompt to submit to Claude
        
    .OUTPUTS
        Boolean - True if submission was successful, False otherwise
        
    .EXAMPLE
        $success = Submit-ToClaudeViaTypeKeys -PromptText "Analyze this code"
    #>
    [CmdletBinding()]
    param([string]$PromptText)
    
    Write-Host ""
    Write-Host "[SUBMISSION] Preparing to submit to Claude Code CLI..." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C within 3 seconds to abort submission..." -ForegroundColor Yellow
    
    # Abort window - give user chance to cancel
    for ($i = 3; $i -gt 0; $i--) {
        Write-Host "  Starting in $i seconds... (Ctrl+C to abort)" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    try {
        # Find Claude window
        $claudeWindow = Find-ClaudeWindow
        
        if (-not $claudeWindow) {
            Write-Host "  Failed to find Claude Code CLI window!" -ForegroundColor Red
            return $false
        }
        
        # Switch to Claude window
        Write-Host "  Switching to Claude window..." -ForegroundColor Gray
        $switched = Switch-ToWindow -WindowHandle $claudeWindow
        
        if (-not $switched) {
            Write-Host "  Failed to switch to Claude window!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "  Window switch successful, preparing text submission..." -ForegroundColor Green
        
        # Save current cursor position
        $originalPos = [WindowAPI+POINT]::new()
        [WindowAPI]::GetCursorPos([ref]$originalPos) | Out-Null
        
        try {
            # Block mouse and keyboard input to prevent interference
            Write-Host "  Blocking input during submission..." -ForegroundColor Gray
            [WindowAPI]::BlockInput($true) | Out-Null
            
            # Additional safety - capture input to Claude window
            [WindowAPI]::SetCapture($claudeWindow) | Out-Null
            
            # Short delay to ensure window focus is stable
            Start-Sleep -Milliseconds 500
            
            # Clear any existing content (Ctrl+A, Delete)
            Write-Host "  Clearing existing content..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("^a")
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.SendKeys]::SendWait("{DELETE}")
            Start-Sleep -Milliseconds 200
            
            # Split prompt into chunks to handle long text reliably
            $maxChunkSize = 500
            $chunks = @()
            for ($i = 0; $i -lt $PromptText.Length; $i += $maxChunkSize) {
                $chunkEnd = [Math]::Min($i + $maxChunkSize - 1, $PromptText.Length - 1)
                $chunks += $PromptText.Substring($i, $chunkEnd - $i + 1)
            }
            
            Write-Host "  Typing prompt text ($($chunks.Count) chunks)..." -ForegroundColor Gray
            
            # Type each chunk with small delays
            for ($i = 0; $i -lt $chunks.Count; $i++) {
                $chunk = $chunks[$i]
                
                # Escape special characters for SendKeys
                $chunk = $chunk.Replace("{", "{{").Replace("}", "}}")
                $chunk = $chunk.Replace("+", "{{+}}").Replace("^", "{{^}}")
                $chunk = $chunk.Replace("%", "{{%}}").Replace("~", "{{~}}")
                $chunk = $chunk.Replace("(", "{{(}}").Replace(")", "{{)}}")
                $chunk = $chunk.Replace("[", "{{[}}").Replace("]", "{{]}}")
                
                # Type the chunk
                [System.Windows.Forms.SendKeys]::SendWait($chunk)
                
                # Small delay between chunks
                if ($i -lt ($chunks.Count - 1)) {
                    Start-Sleep -Milliseconds 50
                }
                
                # Progress indicator for long texts
                if ($chunks.Count -gt 3) {
                    Write-Host "    Chunk $($i + 1)/$($chunks.Count) complete" -ForegroundColor DarkGray
                }
            }
            
            # Submit the prompt (Enter key)
            Write-Host "  Submitting prompt..." -ForegroundColor Gray
            Start-Sleep -Milliseconds 500
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            
            Write-Host "  Prompt submitted successfully!" -ForegroundColor Green
            return $true
            
        } finally {
            # Always restore input even if something goes wrong
            Write-Host "  Restoring input controls..." -ForegroundColor Gray
            
            try {
                [WindowAPI]::ReleaseCapture() | Out-Null
                [WindowAPI]::BlockInput($false) | Out-Null
                
                # Restore cursor position
                [WindowAPI]::SetCursorPos($originalPos.X, $originalPos.Y) | Out-Null
                
            } catch {
                Write-Host "    Warning: Could not fully restore input state: $_" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "  ERROR in prompt submission: $_" -ForegroundColor Red
        
        # Emergency input restoration
        try {
            [WindowAPI]::ReleaseCapture() | Out-Null
            [WindowAPI]::BlockInput($false) | Out-Null
        } catch {
            Write-Host "    CRITICAL: Could not restore input! Manual intervention may be required." -ForegroundColor Red
        }
        
        return $false
    }
}

function Execute-TestScript {
    <#
    .SYNOPSIS
        Executes a test script and collects results
        
    .DESCRIPTION
        Runs PowerShell test scripts with proper error handling and result collection.
        Supports various test frameworks and provides detailed execution metrics.
        
    .PARAMETER ScriptPath
        Path to the test script to execute
        
    .PARAMETER Arguments
        Optional arguments to pass to the test script
        
    .PARAMETER WorkingDirectory
        Working directory for script execution (defaults to current directory)
        
    .PARAMETER TimeoutMinutes
        Timeout in minutes for script execution (default: 10)
        
    .OUTPUTS
        PSCustomObject with execution results including success status, output, and metrics
        
    .EXAMPLE
        $result = Execute-TestScript -ScriptPath ".\Test-Module.ps1" -Arguments "-Verbose"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [string]$Arguments = "",
        [string]$WorkingDirectory = (Get-Location).Path,
        [int]$TimeoutMinutes = 10
    )
    
    $executionStart = Get-Date
    
    Write-Host "Executing test script: $ScriptPath" -ForegroundColor Cyan
    if ($Arguments) {
        Write-Host "  Arguments: $Arguments" -ForegroundColor Gray
    }
    Write-Host "  Working Directory: $WorkingDirectory" -ForegroundColor Gray
    Write-Host "  Timeout: $TimeoutMinutes minutes" -ForegroundColor Gray
    
    try {
        # Validate script exists
        if (-not (Test-Path $ScriptPath)) {
            throw "Test script not found: $ScriptPath"
        }
        
        # Create job for timeout support
        $jobScriptBlock = {
            param($ScriptPath, $Arguments, $WorkingDirectory)
            
            Set-Location $WorkingDirectory
            
            $pinfo = New-Object System.Diagnostics.ProcessStartInfo
            $pinfo.FileName = "powershell.exe"
            $pinfo.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`" $Arguments"
            $pinfo.UseShellExecute = $false
            $pinfo.RedirectStandardOutput = $true
            $pinfo.RedirectStandardError = $true
            $pinfo.CreateNoWindow = $true
            $pinfo.WorkingDirectory = $WorkingDirectory
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $pinfo
            
            $process.Start() | Out-Null
            
            $stdout = $process.StandardOutput.ReadToEnd()
            $stderr = $process.StandardError.ReadToEnd()
            
            $process.WaitForExit()
            
            return @{
                ExitCode = $process.ExitCode
                StandardOutput = $stdout
                StandardError = $stderr
            }
        }
        
        # Start job with timeout
        $job = Start-Job -ScriptBlock $jobScriptBlock -ArgumentList $ScriptPath, $Arguments, $WorkingDirectory
        
        # Wait for completion with timeout
        $completed = $job | Wait-Job -Timeout ($TimeoutMinutes * 60)
        
        if ($completed) {
            $result = Receive-Job -Job $job
            Remove-Job -Job $job -Force
            
            $executionTime = ((Get-Date) - $executionStart).TotalMilliseconds
            
            $success = ($result.ExitCode -eq 0)
            
            Write-Host "  Test execution completed" -ForegroundColor $(if ($success) { 'Green' } else { 'Yellow' })
            Write-Host "  Exit Code: $($result.ExitCode)" -ForegroundColor Gray
            Write-Host "  Execution Time: $([math]::Round($executionTime, 2))ms" -ForegroundColor Gray
            
            if ($result.StandardError -and $result.StandardError.Trim()) {
                Write-Host "  Errors detected:" -ForegroundColor Yellow
                $result.StandardError.Split("`n") | ForEach-Object {
                    if ($_.Trim()) {
                        Write-Host "    $_" -ForegroundColor Red
                    }
                }
            }
            
            return [PSCustomObject]@{
                Success = $success
                ExitCode = $result.ExitCode
                StandardOutput = $result.StandardOutput
                StandardError = $result.StandardError
                ExecutionTimeMs = $executionTime
                ScriptPath = $ScriptPath
                Arguments = $Arguments
                Timestamp = $executionStart
                TimeoutOccurred = $false
            }
            
        } else {
            # Timeout occurred
            Remove-Job -Job $job -Force
            
            Write-Host "  Test execution TIMED OUT after $TimeoutMinutes minutes!" -ForegroundColor Red
            
            return [PSCustomObject]@{
                Success = $false
                ExitCode = -1
                StandardOutput = ""
                StandardError = "Test execution timed out after $TimeoutMinutes minutes"
                ExecutionTimeMs = ($TimeoutMinutes * 60 * 1000)
                ScriptPath = $ScriptPath
                Arguments = $Arguments
                Timestamp = $executionStart
                TimeoutOccurred = $true
            }
        }
        
    } catch {
        $executionTime = ((Get-Date) - $executionStart).TotalMilliseconds
        
        Write-Host "  Test execution FAILED: $_" -ForegroundColor Red
        
        return [PSCustomObject]@{
            Success = $false
            ExitCode = -2
            StandardOutput = ""
            StandardError = $_.Exception.Message
            ExecutionTimeMs = $executionTime
            ScriptPath = $ScriptPath
            Arguments = $Arguments
            Timestamp = $executionStart
            TimeoutOccurred = $false
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Submit-ToClaudeViaTypeKeys',
    'Execute-TestScript'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYdhVK8h3C78fU
# VT1F87fsziSELmO03RrkWU2dDZgsXaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINeoP/vXERN5cLiRLyOPbWh0
# 7U3CI+lHSrZWp4uW42adMA0GCSqGSIb3DQEBAQUABIIBAHF/KoSPWiU1AFVHyGbW
# SlV7mqJEvs/cEgM+lFSniuh3dm9Z5WAZvW2jYXeKs3zQP3gu6A3B2ALVpkpC5W8W
# o98F9U2wQRQHMXTRGgkT9eUvzxFCzBpHtaJ6Oq6M2sG7Uwc+Uf6kqeGd1ww3yWUi
# DwNwx0A81zKNpwORbIBuXV4/iEqiwkKfXgoSQDc5Fpg3xKom+3tspG5FiQuPxlot
# L4029hhaC3rFYtVArdBeCk2tP+xLgY/tZ6hxwmXwFmaQ8478tEKLSOFgrBEn5/VV
# rAYP6FDs7jd58XYeWnjo300/UF+nAGxyzxXKQiuQ95kdz5pczUdtFmpptfK9nZ5H
# zEM=
# SIG # End signature block
