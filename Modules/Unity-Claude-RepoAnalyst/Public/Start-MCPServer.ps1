function Start-MCPServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ripgrep', 'filesystem', 'git', 'ctags')]
        [string]$ServerType,
        
        [Parameter()]
        [hashtable]$AdditionalArgs = @{},
        
        [Parameter()]
        [string]$LogPath = "$PSScriptRoot\..\..\..\.ai\mcp\logs"
    )
    
    begin {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path $LogPath "$ServerType-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
        
        # Ensure log directory exists
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        
        Write-Verbose "[$timestamp] Starting MCP Server: $ServerType"
    }
    
    process {
        try {
            # Load MCP server configuration
            $configPath = "$PSScriptRoot\..\..\..\.ai\mcp\configs\mcp-servers-config.json"
            if (-not (Test-Path $configPath)) {
                throw "MCP server configuration not found at: $configPath"
            }
            
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $serverConfig = $config.servers.$ServerType
            
            if (-not $serverConfig) {
                throw "Server type '$ServerType' not found in configuration"
            }
            
            # Build command based on server type
            $command = $serverConfig.config.command
            $args = $serverConfig.config.args
            
            # Add environment variables if specified
            if ($serverConfig.config.env) {
                foreach ($key in $serverConfig.config.env.PSObject.Properties.Name) {
                    [Environment]::SetEnvironmentVariable($key, $serverConfig.config.env.$key, [EnvironmentVariableTarget]::Process)
                }
            }
            
            # Log startup
            $startupLog = @{
                Timestamp = $timestamp
                Server = $ServerType
                Command = $command
                Arguments = $args -join ' '
                Capabilities = $serverConfig.capabilities
            }
            $startupLog | ConvertTo-Json | Out-File $logFile -Append
            
            # Start the MCP server process
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = $command
            $processInfo.Arguments = $args -join ' '
            $processInfo.UseShellExecute = $false
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.RedirectStandardInput = $true
            $processInfo.CreateNoWindow = $true
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            
            # Register event handlers for output
            $outputHandler = {
                param($sender, $e)
                if ($e.Data) {
                    $logEntry = "[$([datetime]::Now.ToString('HH:mm:ss.fff'))] OUTPUT: $($e.Data)"
                    Add-Content -Path $using:logFile -Value $logEntry
                }
            }
            
            $errorHandler = {
                param($sender, $e)
                if ($e.Data) {
                    $logEntry = "[$([datetime]::Now.ToString('HH:mm:ss.fff'))] ERROR: $($e.Data)"
                    Add-Content -Path $using:logFile -Value $logEntry
                    Write-Warning $e.Data
                }
            }
            
            Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outputHandler | Out-Null
            Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errorHandler | Out-Null
            
            # Start the process
            $process.Start() | Out-Null
            $process.BeginOutputReadLine()
            $process.BeginErrorReadLine()
            
            # Store process information
            $global:MCPServerProcesses = if ($global:MCPServerProcesses) { $global:MCPServerProcesses } else { @{} }
            $global:MCPServerProcesses[$ServerType] = @{
                Process = $process
                StartTime = $timestamp
                LogFile = $logFile
                Config = $serverConfig
            }
            
            Write-Host "MCP Server '$ServerType' started successfully" -ForegroundColor Green
            Write-Host "Log file: $logFile" -ForegroundColor Cyan
            
            # Return server info
            return [PSCustomObject]@{
                ServerType = $ServerType
                ProcessId = $process.Id
                StartTime = $timestamp
                LogFile = $logFile
                Status = 'Running'
                Capabilities = $serverConfig.capabilities
            }
            
        }
        catch {
            Write-Error "Failed to start MCP server '$ServerType': $_"
            
            # Log error
            $errorLog = @{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Server = $ServerType
                Error = $_.ToString()
                StackTrace = $_.ScriptStackTrace
            }
            $errorLog | ConvertTo-Json | Out-File $logFile -Append
            
            throw
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBqBVjhgdps0Wjs
# KuHbLqEnnYuTiaBwZ0eGs1qhpz83nKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG3wd2KOGVAfnenFiVFrLJzE
# sPoYlwTkmBW3KXUYv+PMMA0GCSqGSIb3DQEBAQUABIIBAFH8GYIIPWStxfnloChJ
# dIvnvxl+hnYXHWJKawRLVGDmoMArx+YloAK6H7cNEb+9uuvVC6yKkLWVWK+owy0b
# 8wv98FriSBKxJn5NLmECQRiTCLcqDHJkK0pHivoNYzpWgTmriF3oI0bHKfllN4A8
# nfKcHDPbasf81GbPn+01iS+DMiKLVkU8gofnCO+zgrHI1PB2e6eigiDPT7ZnWPfi
# swLDbtnXRcQ5gewCGYMdi/V/jMSrJBUNS484J/NLI79GV5vtpyPtvX3q4yqQmEZR
# ncaCRZVYmbvUx2hUaRz50ZDTtG+gsXTt/xS24NtpQBfpdbUttChfW0PG5CwAubc4
# z5U=
# SIG # End signature block
