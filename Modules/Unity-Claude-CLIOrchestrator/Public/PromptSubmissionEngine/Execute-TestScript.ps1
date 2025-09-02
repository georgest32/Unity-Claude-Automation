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
        
        # Build execution command
        $command = "& '$ScriptPath'"
        if ($Arguments) {
            $command += " $Arguments"
        }
        
        # Execute with timeout
        $job = Start-Job -ScriptBlock {
            param($cmd, $workDir)
            Set-Location $workDir
            Invoke-Expression $cmd
        } -ArgumentList $command, $WorkingDirectory
        
        $completed = Wait-Job -Job $job -Timeout ($TimeoutMinutes * 60)
        
        if ($completed) {
            $output = Receive-Job -Job $job
            $success = $job.State -eq 'Completed'
            $errorOutput = if ($job.Error) { $job.Error | Out-String } else { "" }
        } else {
            Stop-Job -Job $job
            $output = "Script execution timed out after $TimeoutMinutes minutes"
            $success = $false
            $errorOutput = "Timeout"
        }
        
        Remove-Job -Job $job -Force
        
        $executionEnd = Get-Date
        $duration = $executionEnd - $executionStart
        
        $result = [PSCustomObject]@{
            Success = $success
            ScriptPath = $ScriptPath
            Arguments = $Arguments
            WorkingDirectory = $WorkingDirectory
            Output = $output
            ErrorOutput = $errorOutput
            StartTime = $executionStart
            EndTime = $executionEnd
            Duration = $duration
            DurationMs = $duration.TotalMilliseconds
        }
        
        if ($success) {
            Write-Host "Test script completed successfully in $([Math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Green
        } else {
            Write-Host "Test script failed after $([Math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Red
        }
        
        return $result
        
    } catch {
        $executionEnd = Get-Date
        $duration = $executionEnd - $executionStart
        
        Write-Host "Test script execution error: $($_.Exception.Message)" -ForegroundColor Red
        
        return [PSCustomObject]@{
            Success = $false
            ScriptPath = $ScriptPath
            Arguments = $Arguments
            WorkingDirectory = $WorkingDirectory
            Output = ""
            ErrorOutput = $_.Exception.Message
            StartTime = $executionStart
            EndTime = $executionEnd
            Duration = $duration
            DurationMs = $duration.TotalMilliseconds
        }
    }
}