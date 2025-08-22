# BidirectionalClient-Example.ps1
# Example client for Unity-Claude bidirectional communication

[CmdletBinding()]
param(
    [ValidateSet('Pipe','Http','Both')]
    [string]$Mode = 'Both',
    
    [string]$PipeName = 'Unity-Claude-Bridge',
    
    [int]$HttpPort = 5555
)

Write-Host "Unity-Claude Bidirectional Communication Client" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

#region Named Pipe Client Example

if ($Mode -in 'Pipe', 'Both') {
    Write-Host "`n=== NAMED PIPE CLIENT ===" -ForegroundColor Yellow
    
    function Connect-ToPipeServer {
        param([string]$PipeName)
        
        try {
            Write-Host "Connecting to pipe: \\.\pipe\$PipeName" -ForegroundColor Gray
            
            $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream(
                ".",  # local machine
                $PipeName,
                [System.IO.Pipes.PipeDirection]::InOut
            )
            
            # Connect with 5 second timeout
            $pipeClient.Connect(5000)
            
            if ($pipeClient.IsConnected) {
                Write-Host "âœ" Connected to pipe server" -ForegroundColor Green
                
                $reader = New-Object System.IO.StreamReader($pipeClient)
                $writer = New-Object System.IO.StreamWriter($pipeClient)
                $writer.AutoFlush = $true
                
                # Read welcome message
                $welcome = $reader.ReadLine()
                Write-Host "Server: $welcome" -ForegroundColor Gray
                
                return @{
                    Client = $pipeClient
                    Reader = $reader
                    Writer = $writer
                }
            }
        } catch {
            Write-Host "FAILED Failed to connect: $_" -ForegroundColor Red
            return $null
        }
    }
    
    function Send-PipeCommand {
        param(
            $Connection,
            [string]$Command
        )
        
        if (-not $Connection) { return }
        
        try {
            Write-Host "Sending: $Command" -ForegroundColor Cyan
            $Connection.Writer.WriteLine($Command)
            
            $response = $Connection.Reader.ReadLine()
            Write-Host "Response: $response" -ForegroundColor Green
            
            return $response
        } catch {
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }
    
    # Connect to pipe server
    $pipeConnection = Connect-ToPipeServer -PipeName $PipeName
    
    if ($pipeConnection) {
        # Example commands
        Write-Host "`nSending test commands..." -ForegroundColor White
        
        # Ping test
        Send-PipeCommand -Connection $pipeConnection -Command "PING:Test"
        
        # Get status
        Send-PipeCommand -Connection $pipeConnection -Command "GET_STATUS:"
        
        # Submit error
        $errorData = @{
            File = "TestScript.cs"
            Line = 42
            Message = "Null reference exception"
            Type = "CS0001"
        } | ConvertTo-Json -Compress
        
        Send-PipeCommand -Connection $pipeConnection -Command "ERROR_REPORT:$errorData"
        
        # Claude question
        Send-PipeCommand -Connection $pipeConnection -Command "CLAUDE_QUESTION:How do I fix a null reference exception?"
        
        # Cleanup
        $pipeConnection.Reader.Dispose()
        $pipeConnection.Writer.Dispose()
        $pipeConnection.Client.Dispose()
        
        Write-Host "âœ" Pipe client disconnected" -ForegroundColor Green
    }
}

#endregion

#region HTTP API Client Example

if ($Mode -in 'Http', 'Both') {
    Write-Host "`n=== HTTP API CLIENT ===" -ForegroundColor Yellow
    
    $baseUrl = "http://localhost:$HttpPort/api"
    
    function Test-ApiEndpoint {
        param(
            [string]$Endpoint,
            [string]$Method = 'GET',
            [object]$Body = $null
        )
        
        $uri = "$baseUrl/$Endpoint"
        Write-Host "`n$Method $uri" -ForegroundColor Cyan
        
        try {
            $params = @{
                Uri = $uri
                Method = $Method
            }
            
            if ($Body) {
                $params.Body = $Body | ConvertTo-Json -Depth 10
                $params.ContentType = 'application/json'
                Write-Host "Body: $($params.Body)" -ForegroundColor Gray
            }
            
            $response = Invoke-RestMethod @params
            
            Write-Host "âœ" Success" -ForegroundColor Green
            Write-Host "Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
            
            return $response
            
        } catch {
            if ($_.Exception.Response) {
                $status = $_.Exception.Response.StatusCode.value__
                Write-Host "FAILED HTTP $status Error" -ForegroundColor Red
            } else {
                Write-Host "FAILED Connection failed: $_" -ForegroundColor Red
            }
            return $null
        }
    }
    
    Write-Host "`nTesting API endpoints..." -ForegroundColor White
    
    # Health check
    Test-ApiEndpoint -Endpoint "health"
    
    # Get status
    $status = Test-ApiEndpoint -Endpoint "status"
    
    if ($status) {
        Write-Host "`nServer Status:" -ForegroundColor White
        Write-Host "  Uptime: $([Math]::Round($status.uptime, 2)) seconds" -ForegroundColor Gray
        Write-Host "  Queued Messages: $($status.queued_messages)" -ForegroundColor Gray
        Write-Host "  Pending Responses: $($status.pending_responses)" -ForegroundColor Gray
    }
    
    # Submit error for analysis
    $error = @{
        Type = "CompilationError"
        File = "PlayerController.cs"
        Line = 156
        Column = 23
        Message = "CS0246: The type or namespace name 'IPlayerInput' could not be found"
        Context = @"
public class PlayerController : MonoBehaviour {
    private IPlayerInput input;  // Error here
    
    void Start() {
        input = GetComponent<IPlayerInput>();
    }
}
"@
    }
    
    Test-ApiEndpoint -Endpoint "errors" -Method POST -Body $error
    
    # Ask Claude a question
    $question = @{
        question = "How do I implement the IPlayerInput interface in Unity?"
        context = "Working with Unity 2021.1.14f1"
    }
    
    Test-ApiEndpoint -Endpoint "claude/ask" -Method POST -Body $question
    
    # Get pending responses
    Test-ApiEndpoint -Endpoint "responses"
}

#endregion

#region Interactive Mode

Write-Host "`n=== INTERACTIVE MODE ===" -ForegroundColor Yellow
Write-Host "Would you like to enter interactive mode? (Y/N): " -NoNewline -ForegroundColor Cyan
$interactive = Read-Host

if ($interactive -eq 'Y') {
    Write-Host "`nEntering interactive mode..." -ForegroundColor Green
    Write-Host "Commands:" -ForegroundColor White
    Write-Host "  pipe <command>  - Send command via named pipe" -ForegroundColor Gray
    Write-Host "  api <endpoint>  - Call HTTP API endpoint" -ForegroundColor Gray
    Write-Host "  status         - Get server status" -ForegroundColor Gray
    Write-Host "  quit           - Exit interactive mode" -ForegroundColor Gray
    
    while ($true) {
        Write-Host "`n> " -NoNewline -ForegroundColor Cyan
        $input = Read-Host
        
        if ($input -eq 'quit') {
            break
        }
        
        if ($input -like 'pipe *') {
            $command = $input.Substring(5)
            if ($pipeConnection) {
                Send-PipeCommand -Connection $pipeConnection -Command $command
            } else {
                Write-Host "Pipe not connected" -ForegroundColor Red
            }
        }
        elseif ($input -like 'api *') {
            $endpoint = $input.Substring(4)
            Test-ApiEndpoint -Endpoint $endpoint
        }
        elseif ($input -eq 'status') {
            if ($Mode -in 'Http', 'Both') {
                Test-ApiEndpoint -Endpoint "status"
            }
            if ($Mode -in 'Pipe', 'Both' -and $pipeConnection) {
                Send-PipeCommand -Connection $pipeConnection -Command "GET_STATUS:"
            }
        }
        else {
            Write-Host "Unknown command: $input" -ForegroundColor Yellow
        }
    }
}

#endregion

Write-Host "`nâœ" Client example completed" -ForegroundColor Green

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMbn2pZ+ieccq61BuLANNriZV
# wXOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBurYdLRf2pY+VmucURY6QJE+7UgwDQYJKoZIhvcNAQEBBQAEggEARRsA
# qesD5tHLU+mhnXTmS3CXnBkKYNEKZ+69v+AFltcS3TXJID90xgHewBPshLmmg13t
# FvfcYr+pl1nnuYrXNWyNwZ1F10psIL4Y1s3i5ZgCoaKyo9M5qWnc7d9tMugHOnf2
# FkPKVulvMGL7jJoKG/Dguj9FWv40+3oSKqQike/HNDjHA0yzClg3WYDhs1lhTtza
# DNU3sq4Rln5a0aSpBQRJGdSXl8lkQiu7vAW7aQhDMbSrFucQwc4YtUEAh31azWRW
# jgwK2YSFGVnzVKKAaKoWX+oWNimI/klyHxB1eOisMNSAT8W6RgnihaZoLGruGtle
# FTTMBR/n8zEJT0NWBg==
# SIG # End signature block
