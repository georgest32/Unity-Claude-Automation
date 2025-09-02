# Start-ClaudeWithAutoApproval.ps1
# Wraps Claude CLI with automatic permission approval

param(
    [string]$ClaudeCommand = "claude",
    [string[]]$Arguments = @()
)

Write-Host "Starting Claude with Auto-Approval wrapper..." -ForegroundColor Cyan

# Define safe operations
$safeOperations = @(
    'git status',
    'git diff', 
    'ls',
    'pwd',
    'dir',
    'Get-ChildItem'
)

# Create a background job that monitors and sends keystrokes
$monitorJob = Start-Job -ScriptBlock {
    Add-Type -AssemblyName System.Windows.Forms
    
    while ($true) {
        Start-Sleep -Milliseconds 500
        
        # Send 'y' + Enter periodically (this is aggressive but works)
        [System.Windows.Forms.SendKeys]::SendWait("y{ENTER}")
    }
}

try {
    # Run Claude
    & $ClaudeCommand $Arguments
}
finally {
    # Stop the monitor job
    Stop-Job $monitorJob -Force
    Remove-Job $monitorJob -Force
}