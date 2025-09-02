function Invoke-MCPServerCommand {
    <#
    .SYNOPSIS
    Sends commands to MCP servers and receives responses via named pipes IPC
    
    .DESCRIPTION
    This function provides a PowerShell interface to communicate with MCP servers
    using JSON-RPC protocol over named pipes or stdio
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ripgrep', 'filesystem', 'git', 'ctags')]
        [string]$ServerType,
        
        [Parameter(Mandatory = $true)]
        [string]$Method,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    begin {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Verbose "[$timestamp] Sending command to MCP Server: $ServerType"
    }
    
    process {
        try {
            # Check if server is running
            if (-not $global:MCPServerProcesses -or -not $global:MCPServerProcesses.ContainsKey($ServerType)) {
                throw "MCP server '$ServerType' is not running. Start it first with Start-MCPServer"
            }
            
            $serverInfo = $global:MCPServerProcesses[$ServerType]
            $process = $serverInfo.Process
            
            if ($process.HasExited) {
                throw "MCP server '$ServerType' process has exited"
            }
            
            # Create JSON-RPC request
            $requestId = [Guid]::NewGuid().ToString()
            $request = @{
                jsonrpc = "2.0"
                id = $requestId
                method = $Method
                params = $Parameters
            } | ConvertTo-Json -Depth 10 -Compress
            
            Write-Verbose "Sending request: $request"
            
            # Send request via stdin
            $process.StandardInput.WriteLine($request)
            $process.StandardInput.Flush()
            
            # Read response with timeout
            $response = $null
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
                if ($process.StandardOutput.Peek() -ge 0) {
                    $line = $process.StandardOutput.ReadLine()
                    
                    if ($line) {
                        Write-Verbose "Received line: $line"
                        
                        try {
                            $json = $line | ConvertFrom-Json
                            
                            # Check if this is our response
                            if ($json.id -eq $requestId) {
                                $response = $json
                                break
                            }
                        }
                        catch {
                            # Not JSON, might be a log message
                            Write-Verbose "Non-JSON output: $line"
                        }
                    }
                }
                
                Start-Sleep -Milliseconds 100
            }
            
            $stopwatch.Stop()
            
            if (-not $response) {
                throw "Timeout waiting for response from MCP server after $TimeoutSeconds seconds"
            }
            
            # Check for errors in response
            if ($response.error) {
                throw "MCP server error: $($response.error.message) (Code: $($response.error.code))"
            }
            
            # Log the interaction
            $interactionLog = @{
                Timestamp = $timestamp
                Server = $ServerType
                Method = $Method
                Parameters = $Parameters
                ResponseTime = $stopwatch.Elapsed.TotalMilliseconds
                Success = $true
            }
            $interactionLog | ConvertTo-Json | Out-File $serverInfo.LogFile -Append
            
            # Return the result
            return $response.result
            
        }
        catch {
            # Log error
            if ($serverInfo -and $serverInfo.LogFile) {
                $errorLog = @{
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Server = $ServerType
                    Method = $Method
                    Parameters = $Parameters
                    Error = $_.ToString()
                    Success = $false
                }
                $errorLog | ConvertTo-Json | Out-File $serverInfo.LogFile -Append
            }
            
            Write-Error "Failed to execute MCP command: $_"
            throw
        }
    }
}

# Create alias for convenience
Set-Alias -Name mcp -Value Invoke-MCPServerCommand
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAcI7PEdqBkQKWQ
# /iqo/JT5ngVxJvN6vGyyaavnw17L0qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID9vVY4gLfodEvylnODMgZ4z
# JU6Nq2Ds7rB2mmEaeOqXMA0GCSqGSIb3DQEBAQUABIIBAGhqm5W7O3oj/AGgq5Qi
# PKvQg696VQYD1IayHPFIc9aCrnDKL+8mPI0oO/9RDr3Zz7zHo49Y327Kcm8b7njx
# OLInKdZ03JFPw059BatRJSbf1jWp3Nr/gNTlhBZxzoiFnUr2utCW402XQKA6kjb3
# GISKevyrl/RnRY/S4vu/Cyf4PvDLmIEJa6RnTBS6XOJOUYHAv3RMiTpHhGgUcM5g
# axPKVreGmnKtUkKcG0RLUkNke+qnefikRXa0jxuH/5b7TrAAYkF3Jv0hzZBToyuB
# Ppo808u4eJ+dnWfkBP9IpXqefsR256SZOCo/x1MEp8RaIzVMBv/tkDGbrSHsLDnR
# 93o=
# SIG # End signature block
