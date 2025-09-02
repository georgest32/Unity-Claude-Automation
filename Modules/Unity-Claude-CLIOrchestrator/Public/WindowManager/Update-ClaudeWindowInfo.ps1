function Update-ClaudeWindowInfo {
    <#
    .SYNOPSIS
        Updates Claude window information in system_status.json
        
    .DESCRIPTION
        Stores Claude CLI window details for reliable future detection
        
    .PARAMETER WindowHandle
        The window handle of the Claude CLI window
        
    .PARAMETER ProcessId
        The process ID of the Claude CLI window
        
    .PARAMETER WindowTitle
        The title of the Claude CLI window
        
    .PARAMETER ProcessName
        The name of the Claude CLI process
        
    .EXAMPLE
        Update-ClaudeWindowInfo -WindowHandle $handle -ProcessId $pid -WindowTitle $title -ProcessName $name
    #>
    [CmdletBinding()]
    param(
        [IntPtr]$WindowHandle,
        [int]$ProcessId, 
        [string]$WindowTitle,
        [string]$ProcessName
    )
    
    Write-Host "    Updating Claude window info in system_status.json..." -ForegroundColor Gray
    
    try {
        $systemStatusPath = ".\system_status.json"
        $systemStatus = @{}
        
        # Load existing status or create new
        if (Test-Path $systemStatusPath) {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json -AsHashtable
        }
        
        # Ensure structure exists
        if (-not $systemStatus.SystemInfo) { $systemStatus.SystemInfo = @{} }
        if (-not $systemStatus.SystemInfo.ClaudeCodeCLI) { $systemStatus.SystemInfo.ClaudeCodeCLI = @{} }
        
        # Update Claude window information
        $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessId = $ProcessId
        $systemStatus.SystemInfo.ClaudeCodeCLI.WindowHandle = [int64]$WindowHandle
        $systemStatus.SystemInfo.ClaudeCodeCLI.WindowTitle = $WindowTitle
        $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessName = $ProcessName
        $systemStatus.SystemInfo.ClaudeCodeCLI.LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        $systemStatus.SystemInfo.ClaudeCodeCLI.DetectionMethod = "AutonomousAgent"
        
        # Save back to file
        $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
        
        Write-Host "    Claude window info updated successfully" -ForegroundColor Green
        Write-Host "    PID: $ProcessId, Handle: $WindowHandle, Title: '$WindowTitle'" -ForegroundColor Gray
        
    } catch {
        Write-Host "    Warning: Could not update system_status.json: $_" -ForegroundColor Yellow
    }
}