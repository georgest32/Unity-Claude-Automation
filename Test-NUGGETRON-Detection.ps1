<#
.SYNOPSIS
    Simple test to verify NUGGETRON window detection
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "NUGGETRON WINDOW DETECTION TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Method 1: Direct search for NUGGETRON
Write-Host "`n1. Direct PowerShell process search:" -ForegroundColor Yellow
$nuggetronProcess = Get-Process | Where-Object {
    $_.ProcessName -match 'pwsh|powershell' -and
    $_.MainWindowTitle -eq '**NUGGETRON**'
}

if ($nuggetronProcess) {
    Write-Host "  [OK] FOUND NUGGETRON!" -ForegroundColor Green
    Write-Host "     - PID: $($nuggetronProcess.Id)" -ForegroundColor Gray
    Write-Host "     - Title: '$($nuggetronProcess.MainWindowTitle)'" -ForegroundColor Gray
    Write-Host "     - Handle: $($nuggetronProcess.MainWindowHandle)" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] NUGGETRON not found via direct search" -ForegroundColor Red
}

# Method 2: Check all PowerShell windows
Write-Host "`n2. All PowerShell windows:" -ForegroundColor Yellow
Get-Process | Where-Object {
    $_.ProcessName -match 'pwsh|powershell' -and
    $_.MainWindowHandle -ne 0
} | ForEach-Object {
    $marker = if ($_.MainWindowTitle -eq '**NUGGETRON**') { " <- THIS IS NUGGETRON!" } else { "" }
    Write-Host "   - PID $($_.Id): '$($_.MainWindowTitle)'$marker" -ForegroundColor Gray
}

# Method 3: Check protected registration
Write-Host "`n3. Protected registration file:" -ForegroundColor Yellow
$protectedRegPath = ".\.nuggetron_registration.json"
if (Test-Path $protectedRegPath) {
    $reg = Get-Content $protectedRegPath -Raw | ConvertFrom-Json
    Write-Host "   Protected registration found:" -ForegroundColor Gray
    Write-Host "   - UniqueID: '$($reg.UniqueIdentifier)'" -ForegroundColor Gray
    Write-Host "   - Title: '$($reg.WindowTitle)'" -ForegroundColor Gray
    Write-Host "   - PID: $($reg.ProcessId)" -ForegroundColor Gray
    Write-Host "   - Protected: $($reg.Protected)" -ForegroundColor Gray
    
    # Verify the process still exists
    $proc = Get-Process -Id $reg.ProcessId -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "   [OK] Process $($reg.ProcessId) is still running" -ForegroundColor Green
        Write-Host "   - Current title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
        if ($proc.MainWindowTitle -eq '**NUGGETRON**') {
            Write-Host "   [OK] Title matches NUGGETRON!" -ForegroundColor Green
        } else {
            Write-Host "   [ERROR] Title doesn't match! Expected '**NUGGETRON**', got '$($proc.MainWindowTitle)'" -ForegroundColor Red
        }
    } else {
        Write-Host "   [ERROR] Process $($reg.ProcessId) no longer exists!" -ForegroundColor Red
    }
} else {
    Write-Host "   [WARN] No protected registration file found" -ForegroundColor Yellow
}

# Method 4: Check system_status.json protected section
Write-Host "`n4. System status NUGGETRON_PROTECTED section:" -ForegroundColor Yellow
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json
    if ($status.NUGGETRON_PROTECTED) {
        $reg = $status.NUGGETRON_PROTECTED
        Write-Host "   Protected section found:" -ForegroundColor Gray
        Write-Host "   - UniqueID: '$($reg.UniqueIdentifier)'" -ForegroundColor Gray
        Write-Host "   - Title: '$($reg.WindowTitle)'" -ForegroundColor Gray
        Write-Host "   - PID: $($reg.ProcessId)" -ForegroundColor Gray
        Write-Host "   - WARNING: $($reg.WARNING)" -ForegroundColor Gray
        
        # Verify the process still exists
        $proc = Get-Process -Id $reg.ProcessId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "   [OK] Process $($reg.ProcessId) is still running" -ForegroundColor Green
            Write-Host "   - Current title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
            if ($proc.MainWindowTitle -eq '**NUGGETRON**') {
                Write-Host "   [OK] Title matches NUGGETRON!" -ForegroundColor Green
            } else {
                Write-Host "   [ERROR] Title doesn't match! Expected '**NUGGETRON**', got '$($proc.MainWindowTitle)'" -ForegroundColor Red
            }
        } else {
            Write-Host "   [ERROR] Process $($reg.ProcessId) no longer exists!" -ForegroundColor Red
        }
    } else {
        Write-Host "   [WARN] No NUGGETRON_PROTECTED section found" -ForegroundColor Yellow
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan