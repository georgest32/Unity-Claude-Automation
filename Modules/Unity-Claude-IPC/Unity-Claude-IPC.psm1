# Unity-Claude-IPC.psm1
# Inter-Process Communication module for Unity-Claude automation

# Import required module
Import-Module Unity-Claude-Core -ErrorAction Stop

# Module-scoped variables
$script:PipeServer = $null
$script:ClaudeConfig = @{
    Model = 'sonnet-3.5'
    Executable = 'claude'
    Timeout = 3600
    MaxTokens = 200000
}

#region Claude Communication

function Test-ClaudeAvailable {
    [CmdletBinding()]
    param(
        [string]$ClaudeExe = $script:ClaudeConfig.Executable
    )
    
    try {
        $result = & $ClaudeExe --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Claude CLI available: $result" -Level 'DEBUG'
            return $true
        }
    } catch {
        Write-Log "Claude CLI not found or not accessible: $_" -Level 'WARN'
    }
    
    return $false
}

function Invoke-ClaudeAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorContext,
        
        [ValidateSet('Continue','Fix','Explain','Triage','Plan','Review','Debugging','Custom')]
        [string]$PromptType = 'Continue',
        
        [string]$AdditionalInstructions = '',
        [string]$Model = $script:ClaudeConfig.Model,
        [int]$TimeoutSeconds = $script:ClaudeConfig.Timeout
    )
    
    Write-Log "Starting Claude analysis with prompt type: $PromptType" -Level 'INFO'
    
    # Build the full prompt
    $prompt = Build-ClaudePrompt -ErrorContext $ErrorContext `
                                -PromptType $PromptType `
                                -AdditionalInstructions $AdditionalInstructions
    
    # Send to Claude and get response
    $response = Send-ClaudePrompt -Prompt $prompt `
                                  -Model $Model `
                                  -TimeoutSeconds $TimeoutSeconds
    
    if ($response.Success) {
        Write-Log "Claude analysis completed successfully" -Level 'OK'
        return $response
    } else {
        Write-Log "Claude analysis failed: $($response.Error)" -Level 'ERROR'
        return $response
    }
}

function Send-ClaudePrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        
        [string]$Model = $script:ClaudeConfig.Model,
        [string]$ClaudeExe = $script:ClaudeConfig.Executable,
        [int]$TimeoutSeconds = $script:ClaudeConfig.Timeout
    )
    
    $tempPromptFile = [System.IO.Path]::GetTempFileName()
    $tempResponseFile = [System.IO.Path]::GetTempFileName()
    
    try {
        # Write prompt to temp file
        Set-Content -Path $tempPromptFile -Value $Prompt -Encoding UTF8
        
        # Build Claude command
        $claudeArgs = @(
            '--model', $Model,
            '--max-tokens', '8192',
            '--temperature', '0.3'
        )
        
        # Start Claude process
        $processInfo = @{
            FilePath = $ClaudeExe
            ArgumentList = $claudeArgs
            RedirectStandardInput = $tempPromptFile
            RedirectStandardOutput = $tempResponseFile
            RedirectStandardError = 'NUL'
            NoNewWindow = $true
            PassThru = $true
        }
        
        Write-Log "Sending prompt to Claude (model: $Model)" -Level 'DEBUG'
        $process = Start-Process @processInfo
        
        $finished = $process.WaitForExit($TimeoutSeconds * 1000)
        
        if (-not $finished) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            throw "Claude response timeout after ${TimeoutSeconds}s"
        }
        
        if ($process.ExitCode -ne 0) {
            throw "Claude returned exit code: $($process.ExitCode)"
        }
        
        # Read response
        $response = Get-Content -Path $tempResponseFile -Raw -Encoding UTF8
        
        return @{
            Success = $true
            Response = $response
            Model = $Model
            Timestamp = Get-Date
        }
        
    } catch {
        return @{
            Success = $false
            Error = $_.ToString()
            Model = $Model
            Timestamp = Get-Date
        }
    } finally {
        # Cleanup temp files
        Remove-Item -Path $tempPromptFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempResponseFile -Force -ErrorAction SilentlyContinue
    }
}

function Build-ClaudePrompt {
    [CmdletBinding()]
    param(
        [string]$ErrorContext,
        [string]$PromptType,
        [string]$AdditionalInstructions
    )
    
    $boilerplate = Get-PromptBoilerplate -Type $PromptType
    
    $prompt = @"
$boilerplate

=== CURRENT UNITY COMPILATION ERRORS ===
$ErrorContext

=== ADDITIONAL INSTRUCTIONS ===
$AdditionalInstructions

Please analyze the compilation errors above and provide:
1. Root cause analysis
2. Specific fixes with file paths and code changes
3. Verification steps

Format your response with clear file paths and code blocks.
"@
    
    return $prompt
}

#endregion

#region Named Pipes for Bidirectional Communication

function Start-BidirectionalPipe {
    [CmdletBinding()]
    param(
        [string]$PipeName = 'Unity-Claude-Bridge',
        [scriptblock]$MessageHandler
    )
    
    Write-Log "Starting bidirectional named pipe: $PipeName" -Level 'INFO'
    
    try {
        # Create named pipe server
        $pipeSecurity = New-Object System.IO.Pipes.PipeSecurity
        $pipeAccessRule = New-Object System.IO.Pipes.PipeAccessRule(
            "Everyone",
            [System.IO.Pipes.PipeAccessRights]::ReadWrite,
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $pipeSecurity.AddAccessRule($pipeAccessRule)
        
        $script:PipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
            $PipeName,
            [System.IO.Pipes.PipeDirection]::InOut,
            1,
            [System.IO.Pipes.PipeTransmissionMode]::Message,
            [System.IO.Pipes.PipeOptions]::Asynchronous,
            4096,
            4096,
            $pipeSecurity
        )
        
        Write-Log "Named pipe created, waiting for connection..." -Level 'DEBUG'
        
        # Start async wait for connection
        $asyncResult = $script:PipeServer.BeginWaitForConnection($null, $null)
        
        # Return pipe info
        return @{
            Success = $true
            PipeName = $PipeName
            PipeServer = $script:PipeServer
            AsyncResult = $asyncResult
        }
        
    } catch {
        Write-Log "Failed to create named pipe: $_" -Level 'ERROR'
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Receive-ClaudeResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.Pipes.NamedPipeServerStream]$PipeServer
    )
    
    if ($PipeServer.IsConnected) {
        try {
            $reader = New-Object System.IO.StreamReader($PipeServer)
            $message = $reader.ReadLine()
            
            if ($message -match '^CLAUDE_QUESTION:(.+)') {
                return @{
                    Type = 'Question'
                    Content = $matches[1]
                    Timestamp = Get-Date
                }
            } elseif ($message -match '^CLAUDE_RESPONSE:(.+)') {
                return @{
                    Type = 'Response'
                    Content = $matches[1]
                    Timestamp = Get-Date
                }
            } else {
                return @{
                    Type = 'Unknown'
                    Content = $message
                    Timestamp = Get-Date
                }
            }
        } catch {
            Write-Log "Error receiving from pipe: $_" -Level 'ERROR'
            return $null
        }
    }
    
    return $null
}

#endregion

#region Log Processing

function Split-ConsoleLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,
        
        [string]$OutputDirectory,
        [int]$MaxLinesPerFile = 500,
        [int]$MaxFileSizeKB = 100
    )
    
    if (-not (Test-Path $LogPath)) {
        Write-Log "Console log not found: $LogPath" -Level 'WARN'
        return @()
    }
    
    Write-Log "Splitting console log: $LogPath" -Level 'INFO'
    
    # Create output directory
    if (-not $OutputDirectory) {
        $OutputDirectory = Join-Path (Split-Path $LogPath -Parent) 'ConsoleLogs_Split'
    }
    New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
    
    # Clear existing split files
    Get-ChildItem -Path $OutputDirectory -Filter "ConsoleLogs_Part*.txt" | Remove-Item -Force
    
    $content = Get-Content -Path $LogPath
    $totalLines = $content.Count
    $currentPart = 1
    $currentLines = @()
    $outputFiles = @()
    
    for ($i = 0; $i -lt $totalLines; $i++) {
        $currentLines += $content[$i]
        
        # Check if we should create a new file
        $shouldSplit = ($currentLines.Count -ge $MaxLinesPerFile) -or `
                       (($currentLines -join "`n").Length -gt ($MaxFileSizeKB * 1024))
        
        if ($shouldSplit -or ($i -eq $totalLines - 1)) {
            $partFile = Join-Path $OutputDirectory ("ConsoleLogs_Part{0:D3}.txt" -f $currentPart)
            Set-Content -Path $partFile -Value $currentLines
            $outputFiles += $partFile
            
            Write-Log "Created part $currentPart with $($currentLines.Count) lines" -Level 'DEBUG'
            
            $currentPart++
            $currentLines = @()
        }
    }
    
    # Create index file
    $indexPath = Join-Path $OutputDirectory '_INDEX.txt'
    $indexContent = @"
Console Log Split Index
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Total Parts: $($outputFiles.Count)
Total Lines: $totalLines

Files:
$($outputFiles | ForEach-Object { "- $(Split-Path $_ -Leaf)" } | Out-String)
"@
    Set-Content -Path $indexPath -Value $indexContent
    
    Write-Log "Split into $($outputFiles.Count) parts" -Level 'OK'
    return $outputFiles
}

function Format-ErrorContext {
    [CmdletBinding()]
    param(
        [string]$ConsolePath,
        [string]$EditorLogPath,
        [int]$ContextLines = 10
    )
    
    $errorContext = @()
    
    # Extract errors from console
    if (Test-Path $ConsolePath) {
        $consoleContent = Get-Content -Path $ConsolePath
        $errorLines = @()
        
        for ($i = 0; $i -lt $consoleContent.Count; $i++) {
            if ($consoleContent[$i] -match 'error CS\d+|Exception') {
                $startLine = [Math]::Max(0, $i - $ContextLines)
                $endLine = [Math]::Min($consoleContent.Count - 1, $i + $ContextLines)
                $errorLines += $consoleContent[$startLine..$endLine]
                $errorLines += "---"
            }
        }
        
        if ($errorLines.Count -gt 0) {
            $errorContext += "=== Console Errors ==="
            $errorContext += $errorLines
        }
    }
    
    # Extract errors from Editor log
    if (Test-Path $EditorLogPath) {
        $editorTail = Get-FileTailAsString -Path $EditorLogPath -Tail 1000
        if ($editorTail -match 'error CS\d+|Exception') {
            $errorContext += "=== Editor Log Errors ==="
            $errorContext += $editorTail
        }
    }
    
    return ($errorContext -join "`n")
}

function Get-PromptBoilerplate {
    [CmdletBinding()]
    param(
        [string]$Type = 'Continue',
        [string]$BoilerplatePath
    )
    
    $defaultBoilerplate = @"
You are assisting with Unity compilation error resolution.
Project: Unity 2021.1.14f1, .NET Standard 2.0
Focus on providing specific, actionable fixes for compilation errors.
"@
    
    # Try to load custom boilerplate
    if ($BoilerplatePath -and (Test-Path $BoilerplatePath)) {
        try {
            $customBoilerplate = Get-Content -Path $BoilerplatePath -Raw
            return $customBoilerplate
        } catch {
            Write-Log "Failed to load boilerplate from: $BoilerplatePath" -Level 'WARN'
        }
    }
    
    # Add prompt-type specific instructions
    switch ($Type) {
        'Debugging' {
            $defaultBoilerplate += "`n`nDEBUGGING MODE: Provide detailed analysis with root cause investigation."
        }
        'Fix' {
            $defaultBoilerplate += "`n`nFIX MODE: Focus on immediate fixes for the errors shown."
        }
        'Review' {
            $defaultBoilerplate += "`n`nREVIEW MODE: Multiple attempts have failed. Consider alternative approaches."
        }
        'Plan' {
            $defaultBoilerplate += "`n`nPLAN MODE: Create a structured plan to resolve all issues."
        }
    }
    
    return $defaultBoilerplate
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Invoke-ClaudeAnalysis',
    'Start-BidirectionalPipe',
    'Send-ClaudePrompt',
    'Receive-ClaudeResponse',
    'Split-ConsoleLog',
    'Format-ErrorContext',
    'Get-PromptBoilerplate',
    'Test-ClaudeAvailable'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUluNRiFknWMlKdL/pS1Jx8Ki2
# H0agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUn7qmuFceXT0C9RRladU3i1fa6BEwDQYJKoZIhvcNAQEBBQAEggEAl00e
# rhrzOC+Wdu6DNTUEDDg677avyxLxyNBS3fzrAGmAZLMyzThGBTIm0XGV48gjx+Ro
# YZHGzXEWhWsfOEQsqBdE7zYvB9Riv7nLMz1u2dwyiKoHBkbyRczktfA2nEfunpFm
# 6+uFgpiMgUAgjW0ZaaGXlod0iD8PPQuAEeOcSUgbQNRrGpFOkTRO2bPLQxz5u7eC
# hoH3l6oiuKafqcJ9aOZiLPOmhussVK2FNMPXERf3rO++hSJrsAzgGOy1kWlmL93t
# jhQ4Lqg8mLBBR9xciGkSR0Ip2uFrHhA4p7WAYuCFUvPPOQoKDH4ByoN4VqP43QwT
# qvEH7o5GQh6/gBReKw==
# SIG # End signature block
