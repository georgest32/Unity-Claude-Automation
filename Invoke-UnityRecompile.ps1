# Invoke-UnityRecompile.ps1
# Triggers Unity recompilation using CompilationPipeline.RequestScriptCompilation()
# This works even when Unity is not the active window
# Date: 2025-08-17

[CmdletBinding()]
param(
    [Parameter()]
    [string]$UnityPath = "C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe",
    
    [Parameter()]
    [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering",
    
    [Parameter()]
    [switch]$WaitForCompletion,
    
    [Parameter()]
    [switch]$ExportErrors
)

Write-Host "=== Unity Recompilation Trigger ===" -ForegroundColor Cyan
Write-Host "Using CompilationPipeline.RequestScriptCompilation()" -ForegroundColor Yellow

# Verify Unity executable exists
if (-not (Test-Path $UnityPath)) {
    Write-Host "[ERROR] Unity not found at: $UnityPath" -ForegroundColor Red
    Write-Host "Please update the path in the script or pass -UnityPath parameter" -ForegroundColor Yellow
    exit 1
}

# Verify project exists
if (-not (Test-Path $ProjectPath)) {
    Write-Host "[ERROR] Project not found at: $ProjectPath" -ForegroundColor Red
    exit 1
}

# Create automation logs directory
$logsDir = Join-Path $ProjectPath "AutomationLogs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    Write-Host "[OK] Created logs directory: $logsDir" -ForegroundColor Green
}

# Mark the Editor.log before recompilation
$editorLog = Join-Path $env:LOCALAPPDATA 'Unity\Editor\Editor.log'
if (Test-Path $editorLog) {
    $beforeSize = (Get-Item $editorLog).Length
    $beforeTime = (Get-Item $editorLog).LastWriteTime
    Write-Host "[INFO] Editor.log size before: $beforeSize bytes" -ForegroundColor Gray
}

# Build Unity command
$method = "UnityClaudeAutomation.ForceRecompileFromAutomation.ForceRecompileFromCLI"
$unityArgs = @(
    "-batchmode",
    "-quit",
    "-projectPath", "`"$ProjectPath`"",
    "-executeMethod", $method,
    "-logFile", "-"  # Output to stdout
)

if ($ExportErrors) {
    # Also export current errors
    $exportMethod = "UnityClaudeAutomation.ForceRecompileFromAutomation.ExportCurrentErrors"
    $unityArgs += @("-executeMethod", $exportMethod)
}

Write-Host ""
Write-Host "Executing Unity with method: $method" -ForegroundColor Yellow
Write-Host "Project: $ProjectPath" -ForegroundColor Gray
Write-Host ""

# Execute Unity in batch mode
$process = Start-Process -FilePath $UnityPath -ArgumentList $unityArgs -PassThru -NoNewWindow -Wait

if ($process.ExitCode -eq 0) {
    Write-Host "[OK] Unity command executed successfully" -ForegroundColor Green
}
else {
    Write-Host "[WARNING] Unity exited with code: $($process.ExitCode)" -ForegroundColor Yellow
}

# Check if Editor.log was updated
if (Test-Path $editorLog) {
    $afterSize = (Get-Item $editorLog).Length
    $afterTime = (Get-Item $editorLog).LastWriteTime
    
    if ($afterTime -gt $beforeTime) {
        Write-Host "[OK] Editor.log was updated" -ForegroundColor Green
        Write-Host "  Size changed: $beforeSize -> $afterSize bytes" -ForegroundColor Gray
        
        # Add a marker to the log
        $marker = "`n`n================================================================================`n"
        $marker += "[AUTOMATION RECOMPILE MARKER] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
        $marker += "Triggered by: Invoke-UnityRecompile.ps1`n"
        $marker += "================================================================================`n"
        
        Add-Content -Path $editorLog -Value $marker
    }
    else {
        Write-Host "[WARNING] Editor.log was not updated" -ForegroundColor Yellow
    }
}

# Check recompilation log
$recompileLog = Join-Path $logsDir "recompilation.log"
if (Test-Path $recompileLog) {
    Write-Host ""
    Write-Host "Recompilation log:" -ForegroundColor Cyan
    Get-Content $recompileLog -Tail 10 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

# Check current errors if exported
if ($ExportErrors) {
    $errorLog = Join-Path $logsDir "current_errors.log"
    if (Test-Path $errorLog) {
        Write-Host ""
        Write-Host "Current compilation errors:" -ForegroundColor Cyan
        Get-Content $errorLog -Tail 20 | ForEach-Object {
            if ($_ -match "error") {
                Write-Host "  $_" -ForegroundColor Red
            }
            else {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    }
}

Write-Host ""
Write-Host "=== Recompilation Complete ===" -ForegroundColor Green

if ($WaitForCompletion) {
    Write-Host "Waiting 5 seconds for compilation to fully complete..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "Tips:" -ForegroundColor Gray
Write-Host "- Check $recompileLog for compilation events" -ForegroundColor Gray
Write-Host "- Use -ExportErrors to export current compilation errors" -ForegroundColor Gray
Write-Host "- Use -WaitForCompletion to wait for compilation to finish" -ForegroundColor Gray
Write-Host ""

exit 0
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqnIZq8hwh3V9C+O3zGht6UCF
# xQugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUb1Q3MnlVptboeuxDAIdVNfcGs+MwDQYJKoZIhvcNAQEBBQAEggEApunv
# uQ25rrM6ZpJ4dgrNTv7zV7LqCY0RVTPnyyY8qsZBdrF/2u2bIyYCE74ZePTWl7zY
# VBil3AOgvHeW5sZOtTjaYucmvtU03QqQeJ39kehqFv3yEezk2L/0KOvVePwUAjPg
# 89A2aYwyXLVNbN0HfmwnQ7j1LxAEExx/G43UrOYMlISmgyaixv1J08XlfvmSRtdL
# BbO3yw2Nb6au+//jsec6N4uqNBl9MOY7V1Hz9NIaftchAq7bcd3qwA3/8d6aM482
# CNG6dYEE2o7Qeh117r7JT572JblnGrMAaiTDGfiXwx4RX3bn2n1x2CH82uu9V0/n
# p1ZwOAiETfzjeK7NAg==
# SIG # End signature block
