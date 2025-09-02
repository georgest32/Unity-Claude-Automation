function Invoke-PythonBridgeCommand {
    <#
    .SYNOPSIS
    Sends commands to the Python bridge and receives responses
    
    .DESCRIPTION
    Communicates with the Python bridge server via named pipes to execute
    LangGraph and AutoGen operations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ping', 'execute_langgraph', 'execute_autogen', 'shutdown')]
        [string]$Method,
        
        [Parameter()]
        [hashtable]$Parameters = @{},
        
        [Parameter()]
        [string]$PipeName = "UnityClaudeRepoPipe",
        
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    begin {
        Write-Verbose "Sending command to Python bridge: $Method"
    }
    
    process {
        try {
            # Check if bridge is running
            if (-not $global:PythonBridgeProcess -or $global:PythonBridgeProcess.Status -ne 'Running') {
                throw "Python bridge is not running. Start it first with Start-PythonBridge"
            }
            
            $pipePath = "\\.\pipe\$PipeName"
            
            # Create message
            $message = @{
                method = $Method
                params = $Parameters
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            } | ConvertTo-Json -Compress
            
            Write-Verbose "Sending message: $message"
            
            # Connect to named pipe
            $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(
                ".",
                $PipeName,
                [System.IO.Pipes.PipeDirection]::InOut,
                [System.IO.Pipes.PipeOptions]::None
            )
            
            try {
                # Connect with timeout
                $pipe.Connect($TimeoutSeconds * 1000)
                
                # Send message
                $writer = New-Object System.IO.StreamWriter($pipe)
                $writer.WriteLine($message)
                $writer.Flush()
                
                # Read response
                $reader = New-Object System.IO.StreamReader($pipe)
                $response = $reader.ReadLine()
                
                Write-Verbose "Received response: $response"
                
                # Parse response
                $result = $response | ConvertFrom-Json
                
                if ($result.status -eq 'error') {
                    throw "Python bridge error: $($result.error)"
                }
                
                return $result.result
                
            }
            finally {
                if ($pipe) {
                    $pipe.Close()
                    $pipe.Dispose()
                }
            }
            
        }
        catch {
            Write-Error "Failed to execute Python bridge command: $_"
            throw
        }
    }
}

function Test-PythonBridge {
    <#
    .SYNOPSIS
    Tests the Python bridge connection
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PipeName = "UnityClaudeRepoPipe"
    )
    
    try {
        $result = Invoke-PythonBridgeCommand -Method 'ping' -PipeName $PipeName
        if ($result -eq 'pong') {
            Write-Host "Python bridge is responding correctly" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "Unexpected response from Python bridge: $result"
            return $false
        }
    }
    catch {
        Write-Error "Python bridge test failed: $_"
        return $false
    }
}

function Stop-PythonBridge {
    <#
    .SYNOPSIS
    Stops the Python bridge server
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$PipeName = "UnityClaudeRepoPipe"
    )
    
    try {
        if ($global:PythonBridgeProcess) {
            # Send shutdown command
            try {
                Invoke-PythonBridgeCommand -Method 'shutdown' -PipeName $PipeName
                Write-Verbose "Shutdown command sent to Python bridge"
            }
            catch {
                Write-Verbose "Could not send shutdown command: $_"
            }
            
            # Kill process if still running
            $process = $global:PythonBridgeProcess.Process
            if ($process -and -not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit()
            }
            
            $global:PythonBridgeProcess.Status = 'Stopped'
            Write-Host "Python bridge stopped" -ForegroundColor Yellow
            
            return $true
        }
        else {
            Write-Warning "Python bridge is not running"
            return $false
        }
    }
    catch {
        Write-Error "Failed to stop Python bridge: $_"
        return $false
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDx4OKX+Wcgaf0o
# MTtpiI5Yljqg7uIubCISNJwDwMkDIqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDxME06WRVTaTBOdhy5r2zHY
# Nf67qbA9VrQj1zDwN3xBMA0GCSqGSIb3DQEBAQUABIIBAKfqXyqU4RbMY+1K/G26
# e+JxVhGhrU08Ro3L15vzAb02prg3lkYuMgM0dMStGWB/OQoUL2flB9IX817KH9UG
# iEW0tesHm7lGk3JrpM+00J93I/2sOiGI2TG62rJOTZQPGNR/iLBQ5tLANp22naZ5
# 6tpPu+uKf3ZWhgWpCpEPxBdAUyNhsiTjNpwPjUILfaR2IVdWKOWWkYQUoWxlk5nX
# UMQt5gkPqFoW8sWKn7OqB7dsOwx1isCEBIqcw8h0LenojrbzQ91gGfLer77Bci2h
# f335R8qeYEDuzrCfckzn09ulxnrNqwVkUxEXfm57lg5/8SjcULJCL0txRffpocH4
# VxM=
# SIG # End signature block
