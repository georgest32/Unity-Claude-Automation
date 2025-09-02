function Get-MCPServerStatus {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('ripgrep', 'filesystem', 'git', 'ctags', 'All')]
        [string]$ServerType = 'All',
        
        [Parameter()]
        [switch]$Detailed
    )
    
    begin {
        Write-Verbose "Getting MCP Server status for: $ServerType"
    }
    
    process {
        try {
            # Load configuration
            $configPath = "$PSScriptRoot\..\..\..\.ai\mcp\configs\mcp-servers-config.json"
            $config = if (Test-Path $configPath) {
                Get-Content $configPath -Raw | ConvertFrom-Json
            } else {
                $null
            }
            
            $results = @()
            
            if ($ServerType -eq 'All') {
                $serversToCheck = @('ripgrep', 'filesystem', 'git', 'ctags')
            }
            else {
                $serversToCheck = @($ServerType)
            }
            
            foreach ($server in $serversToCheck) {
                $status = [PSCustomObject]@{
                    ServerType = $server
                    Status = 'Not Running'
                    ProcessId = $null
                    StartTime = $null
                    Runtime = $null
                    LogFile = $null
                    Capabilities = @()
                }
                
                # Check if server is running
                if ($global:MCPServerProcesses -and $global:MCPServerProcesses.ContainsKey($server)) {
                    $serverInfo = $global:MCPServerProcesses[$server]
                    $process = $serverInfo.Process
                    
                    if ($process -and -not $process.HasExited) {
                        $status.Status = 'Running'
                        $status.ProcessId = $process.Id
                        $status.StartTime = $serverInfo.StartTime
                        $status.Runtime = (New-TimeSpan -Start $serverInfo.StartTime -End (Get-Date)).ToString()
                        $status.LogFile = $serverInfo.LogFile
                        
                        if ($Detailed) {
                            # Check process health
                            try {
                                $proc = Get-Process -Id $process.Id -ErrorAction Stop
                                $status | Add-Member -NotePropertyName 'CPUUsage' -NotePropertyValue $proc.CPU
                                $status | Add-Member -NotePropertyName 'MemoryMB' -NotePropertyValue ([math]::Round($proc.WorkingSet64 / 1MB, 2))
                                $status | Add-Member -NotePropertyName 'Threads' -NotePropertyValue $proc.Threads.Count
                            }
                            catch {
                                Write-Verbose "Could not get detailed process info: $_"
                            }
                        }
                    }
                    else {
                        # Process has exited, clean up
                        $status.Status = 'Stopped'
                        $global:MCPServerProcesses.Remove($server)
                    }
                }
                
                # Add capabilities from config
                if ($config -and $config.servers.$server) {
                    $status.Capabilities = $config.servers.$server.capabilities
                    
                    if ($Detailed) {
                        $status | Add-Member -NotePropertyName 'Description' -NotePropertyValue $config.servers.$server.description
                        $status | Add-Member -NotePropertyName 'Package' -NotePropertyValue $config.servers.$server.package
                    }
                }
                
                $results += $status
            }
            
            # Display results
            if ($results.Count -eq 1) {
                return $results[0]
            }
            else {
                # Create summary table
                Write-Host "`nMCP Server Status Summary" -ForegroundColor Cyan
                Write-Host ("=" * 60) -ForegroundColor DarkGray
                
                $results | Format-Table -Property ServerType, Status, ProcessId, Runtime -AutoSize
                
                # Show running count
                $runningCount = ($results | Where-Object { $_.Status -eq 'Running' }).Count
                $totalCount = $results.Count
                
                Write-Host "`n$runningCount of $totalCount servers are running" -ForegroundColor $(if ($runningCount -eq $totalCount) { 'Green' } elseif ($runningCount -eq 0) { 'Red' } else { 'Yellow' })
                
                if ($Detailed) {
                    return $results
                }
            }
            
        }
        catch {
            Write-Error "Failed to get MCP server status: $_"
            throw
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCnyAwlY3zgd3In
# adzohqeI5xZDc7kDak+eB2V1uPQSvaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGWYeBNAPX5HhgJCoHoBF2ki
# Lmsen5vtQy0ZJOFORflrMA0GCSqGSIb3DQEBAQUABIIBAGz05zb5VeAzxCnjUVuQ
# y264mXoywKcnPPXeFkVTnbG0EO39lqXPbOUgNXHF9+ZQlqS8T04PgTPdA3fEozja
# pcFZ+3t8kuoxfUR/PiW7jsHmDbcwxgEzZ6Kd7d0iBouZ7o693c3Tnos4EV4v4gl9
# rbs50YnDmnj3dXICd4pdQDJFim3jsdmIf1wHnYTc06XAGjQr9PjX4hXO4V7a1O5R
# izH5QNlDKKeScv+3ynVn0Em2MVNzBFBk0r7/teaN6+UA4ZkOJld0km+rCG9uVapf
# 78Jv1EuUbDk0tHKrTB7iz0Vr2CZDkesDtmB+Pv4fSO5XGBKho9H3jVdiHqH4Hz0S
# Psc=
# SIG # End signature block
