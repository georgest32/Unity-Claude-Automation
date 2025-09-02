# Start-PermissionPipe.ps1
# Creates a named pipe for Claude permission communication

$pipeName = "ClaudePermissions"
$fullPipeName = "\\.\pipe\$pipeName"

Write-Host "Starting Claude Permission Pipe..." -ForegroundColor Cyan
Write-Host "Pipe name: $fullPipeName" -ForegroundColor Gray

# Create the named pipe
$pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::InOut)

Write-Host "Waiting for Claude to connect..." -ForegroundColor Yellow

try {
    while ($true) {
        # Wait for connection
        $pipeServer.WaitForConnection()
        Write-Host "Claude connected!" -ForegroundColor Green
        
        $reader = New-Object System.IO.StreamReader($pipeServer)
        $writer = New-Object System.IO.StreamWriter($pipeServer)
        $writer.AutoFlush = $true
        
        while ($pipeServer.IsConnected) {
            $request = $reader.ReadLine()
            if ($request) {
                Write-Host "Received permission request: $request" -ForegroundColor Cyan
                
                # Parse the request
                $requestData = $request | ConvertFrom-Json
                
                # Determine response
                $response = "n"  # Default deny
                $reason = "Unknown operation"
                
                if ($requestData.Command -match "git status|git diff|ls|pwd|Get-ChildItem") {
                    $response = "y"
                    $reason = "Safe read-only operation"
                }
                
                Write-Host "Sending response: $response ($reason)" -ForegroundColor $(if ($response -eq "y") {"Green"} else {"Red"})
                
                # Send response back through pipe
                $responseData = @{
                    Approved = ($response -eq "y")
                    Reason = $reason
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                } | ConvertTo-Json -Compress
                
                $writer.WriteLine($responseData)
            }
        }
        
        $pipeServer.Disconnect()
        Write-Host "Claude disconnected" -ForegroundColor Yellow
    }
}
finally {
    $pipeServer.Dispose()
}