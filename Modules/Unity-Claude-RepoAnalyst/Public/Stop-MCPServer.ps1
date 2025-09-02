function Stop-MCPServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ripgrep', 'filesystem', 'git', 'ctags', 'All')]
        [string]$ServerType
    )
    
    begin {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Verbose "[$timestamp] Stopping MCP Server: $ServerType"
    }
    
    process {
        try {
            if (-not $global:MCPServerProcesses) {
                Write-Warning "No MCP servers are currently running"
                return
            }
            
            $serversToStop = @()
            
            if ($ServerType -eq 'All') {
                $serversToStop = $global:MCPServerProcesses.Keys
            }
            else {
                if ($global:MCPServerProcesses.ContainsKey($ServerType)) {
                    $serversToStop = @($ServerType)
                }
                else {
                    Write-Warning "MCP server '$ServerType' is not running"
                    return
                }
            }
            
            foreach ($server in $serversToStop) {
                $serverInfo = $global:MCPServerProcesses[$server]
                $process = $serverInfo.Process
                
                if ($process -and -not $process.HasExited) {
                    Write-Host "Stopping MCP server '$server' (PID: $($process.Id))..." -ForegroundColor Yellow
                    
                    # Send shutdown signal if possible
                    try {
                        $process.StandardInput.WriteLine("exit")
                        $process.StandardInput.Close()
                        
                        # Wait for graceful shutdown (max 5 seconds)
                        $process.WaitForExit(5000) | Out-Null
                    }
                    catch {
                        Write-Verbose "Could not send graceful shutdown signal: $_"
                    }
                    
                    # Force kill if still running
                    if (-not $process.HasExited) {
                        $process.Kill()
                        $process.WaitForExit()
                    }
                    
                    # Log shutdown
                    $shutdownLog = @{
                        Timestamp = $timestamp
                        Server = $server
                        ProcessId = $process.Id
                        Action = 'Stopped'
                        Runtime = (New-TimeSpan -Start $serverInfo.StartTime -End (Get-Date)).ToString()
                    }
                    $shutdownLog | ConvertTo-Json | Out-File $serverInfo.LogFile -Append
                    
                    Write-Host "MCP server '$server' stopped successfully" -ForegroundColor Green
                    
                    # Clean up global variable
                    $global:MCPServerProcesses.Remove($server)
                }
                else {
                    Write-Warning "MCP server '$server' process is not running or already exited"
                    $global:MCPServerProcesses.Remove($server)
                }
            }
            
            if ($global:MCPServerProcesses.Count -eq 0) {
                Remove-Variable -Name MCPServerProcesses -Scope Global -ErrorAction SilentlyContinue
            }
            
        }
        catch {
            Write-Error "Failed to stop MCP server '$ServerType': $_"
            throw
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBm+CtWDF90Gvjf
# 1q6AWdXi2TZyZomsHmVxsNoEDWGyQ6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB7Og23LjZZO2PFnKQ7/2fv0
# OrOh0LnYcMnE7aVHzCVCMA0GCSqGSIb3DQEBAQUABIIBADw7Tt7d7Oo2N/cJISE9
# qPI6szPbclVARALkCdGVfAoidARDiytK8wEReFjdZC805X9+9KaB6cmjPhMgrPfL
# PdDETjawQ+U6vqZwhQ30lhOGzJq6FxvziNTzsNYsIxIyJJdV1KH5szohOkPZhrpF
# pqyjbxIFaBwVMzaH8/71Zx2+kHlgOxuQooY8ZMBSpi52iK64XjtnCz/xsh/1tuwD
# mDZ87sjunyxo7Vo0jkJYAnv2u9xucF8K47eNarv++KXt+Cl9/PEBPzf0j6XPTgGX
# N6xAqYqPPHBjqjdMkZth5xMaC7oUs6txqdbqrzcWlBTeYbaFrWo9GmlwDTqZFqTk
# QWU=
# SIG # End signature block
