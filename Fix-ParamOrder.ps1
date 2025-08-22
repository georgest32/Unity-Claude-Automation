# Fix-ParamOrder.ps1
# Fixes the param block order in scripts with PS7 self-elevation

$scriptsToFix = @(
    "Start-UnifiedSystem-Complete.ps1",
    "Start-UnifiedSystem.ps1", 
    "Start-UnifiedSystem-Final.ps1",
    "Start-UnifiedSystem-Fixed.ps1",
    "Start-SystemStatusMonitoring-Generic.ps1",
    "Start-SystemStatusMonitoring-Window.ps1",
    "Start-SystemStatusMonitoring-Enhanced.ps1",
    "Start-SystemStatusMonitoring-Working.ps1",
    "Start-SystemStatusMonitoring.ps1",
    "Start-AutonomousMonitoring.ps1",
    "Start-AutonomousMonitoring-Fixed.ps1",
    "Start-AutonomousMonitoring-Enhanced.ps1",
    "Start-UnityClaudeAutomation.ps1",
    "Start-BidirectionalServer.ps1",
    "Start-SimpleMonitoring.ps1",
    "Start-EnhancedDashboard.ps1",
    "Start-EnhancedDashboard-Fixed.ps1",
    "Start-EnhancedDashboard-Working.ps1"
)

foreach ($script in $scriptsToFix) {
    $path = Join-Path $PSScriptRoot $script
    if (Test-Path $path) {
        Write-Host "Fixing: $script" -ForegroundColor Yellow
        
        $content = Get-Content $path -Raw
        
        # Extract param block if it exists
        if ($content -match '(?ms)(param\s*\([^)]+\))') {
            $paramBlock = $matches[1]
            
            # Remove param block from current location
            $contentNoParam = $content -replace '(?ms)param\s*\([^)]+\)\s*', ''
            
            # Find where to insert (after initial comments but before code)
            $lines = $contentNoParam -split "`r?`n"
            $insertAt = 0
            
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i].Trim()
                if ($line -ne "" -and -not $line.StartsWith("#") -and -not $line.StartsWith("<#")) {
                    $insertAt = $i
                    break
                }
            }
            
            # Rebuild with param first
            $newLines = @()
            if ($insertAt -gt 0) {
                $newLines += $lines[0..($insertAt-1)]
            }
            $newLines += ""
            $newLines += $paramBlock
            $newLines += ""
            $newLines += $lines[$insertAt..($lines.Count-1)]
            
            $newContent = $newLines -join "`r`n"
            Set-Content -Path $path -Value $newContent -Encoding UTF8
            Write-Host "  Fixed param order" -ForegroundColor Green
        } else {
            Write-Host "  No param block found" -ForegroundColor Gray
        }
    }
}

Write-Host "`nParam order fixed in all scripts!" -ForegroundColor Green