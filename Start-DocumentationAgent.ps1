# Start-DocumentationAgent.ps1
# Starts the documentation agent that monitors code changes and generates/updates documentation
# Date: 2025-08-24

param(
    [switch]$WatchMode = $true,
    [switch]$GenerateInitial = $false,
    [switch]$UpdateGitHub = $false,
    [switch]$Debug = $false,
    [int]$Port = 8085,
    [string]$OutputPath = ".\docs\generated"
)

# Ensure PowerShell 7
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    }
}

$ErrorActionPreference = "Continue"
$InformationPreference = "Continue"

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Documentation Agent" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Load required modules
$modules = @(
    'Unity-Claude-FileMonitor',
    'Unity-Claude-DocumentationDrift',
    'Unity-Claude-GitHub',
    'Unity-Claude-RepoAnalyst',
    'Unity-Claude-CPG'
)

foreach ($module in $modules) {
    $modulePath = Join-Path $PSScriptRoot "Modules\$module\$module.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
        Write-Host "[OK] Loaded module: $module" -ForegroundColor Green
    } else {
        Write-Warning "Module not found: $module"
    }
}

# Configuration
$config = @{
    WatchPaths = @(
        "$PSScriptRoot\Modules",
        "$PSScriptRoot\scripts",
        "$PSScriptRoot\agents"
    )
    FilePatterns = @('*.ps1', '*.psm1', '*.psd1', '*.py', '*.js', '*.ts', '*.md')
    ExcludePatterns = @('*.test.ps1', '*backup*', 'node_modules', '.venv', '__pycache__')
    DebounceTime = 2000  # milliseconds
    OutputPath = $OutputPath
    Port = $Port
}

# Initialize documentation drift detection
if (Get-Command Set-DocumentationDriftConfig -ErrorAction SilentlyContinue) {
    Set-DocumentationDriftConfig -EnableAutoDetection -ScanInterval 300
    Write-Host "[OK] Documentation drift detection configured" -ForegroundColor Green
}

# Start file monitoring
$fileMonitorJobs = @()
if ($WatchMode) {
    Write-Host "`nStarting file monitors..." -ForegroundColor Yellow
    
    foreach ($path in $config.WatchPaths) {
        if (Test-Path $path) {
            try {
                if (Get-Command Start-FileMonitor -ErrorAction SilentlyContinue) {
                    $job = Start-FileMonitor -Path $path `
                        -Filter $config.FilePatterns `
                        -Recurse `
                        -DebounceTime $config.DebounceTime `
                        -Action {
                            param($Event)
                            Write-Host "[CHANGE] $($Event.FullPath)" -ForegroundColor Yellow
                            
                            # Trigger documentation update
                            if ($Event.FullPath -match '\.(ps1|psm1|psd1|py|js|ts)$') {
                                & "$PSScriptRoot\scripts\docs\Update-DocumentationForFile.ps1" `
                                    -FilePath $Event.FullPath `
                                    -OutputPath $using:OutputPath
                            }
                        }
                    
                    $fileMonitorJobs += $job
                    Write-Host "[OK] Monitoring: $path" -ForegroundColor Green
                }
            } catch {
                Write-Warning "Failed to start monitor for ${path}: $_"
            }
        }
    }
}

# Generate initial documentation if requested
if ($GenerateInitial) {
    Write-Host "`nGenerating initial documentation..." -ForegroundColor Yellow
    
    $docGenScript = Join-Path $PSScriptRoot "scripts\docs\Generate-ModuleDocumentation.ps1"
    if (Test-Path $docGenScript) {
        & $docGenScript -OutputPath $OutputPath
        Write-Host "[OK] Initial documentation generated" -ForegroundColor Green
    } else {
        Write-Warning "Documentation generator script not found"
    }
}

# Start documentation server (REST API)
$serverJob = $null
try {
    Write-Host "`nStarting documentation server on port $Port..." -ForegroundColor Yellow
    
    $serverScript = @'
    param($Port, $OutputPath)
    
    Add-Type -AssemblyName System.Net.Http
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:${Port}/")
    $listener.Start()
    
    Write-Host "Documentation server running on http://localhost:$Port" -ForegroundColor Green
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $path = $request.Url.LocalPath
        
        switch -Regex ($path) {
            '^/status$' {
                $status = @{
                    active = $true
                    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    outputPath = $OutputPath
                }
                $json = $status | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentType = "application/json"
            }
            '^/generate' {
                # Trigger documentation generation
                & "$PSScriptRoot\scripts\docs\Generate-ModuleDocumentation.ps1" -OutputPath $OutputPath
                $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"status":"generating"}')
                $response.ContentType = "application/json"
            }
            default {
                $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"error":"not found"}')
                $response.StatusCode = 404
                $response.ContentType = "application/json"
            }
        }
        
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
'@
    
    $serverJob = Start-Job -ScriptBlock ([ScriptBlock]::Create($serverScript)) -ArgumentList $Port, $OutputPath
    
    Start-Sleep -Seconds 2
    
    # Test server
    try {
        $testResponse = Invoke-RestMethod -Uri "http://localhost:$Port/status" -Method Get
        Write-Host "[OK] Documentation server active" -ForegroundColor Green
    } catch {
        Write-Warning "Documentation server may not be responding"
    }
    
} catch {
    Write-Error "Failed to start documentation server: $_"
}

# Main monitoring loop
Write-Host "`n=================================" -ForegroundColor Cyan
Write-Host "Documentation Agent Active" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Monitoring paths:" -ForegroundColor Yellow
$config.WatchPaths | ForEach-Object { Write-Host "  - $_" }
Write-Host "`nServer: http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Output: $OutputPath" -ForegroundColor Yellow
Write-Host "`nPress Ctrl+C to stop..." -ForegroundColor Gray

# GitHub integration check
if ($UpdateGitHub) {
    Write-Host "`nGitHub integration enabled" -ForegroundColor Yellow
    
    # Check for updates every 5 minutes
    $githubTimer = New-Object System.Timers.Timer
    $githubTimer.Interval = 300000  # 5 minutes
    $githubTimer.AutoReset = $true
    
    Register-ObjectEvent -InputObject $githubTimer -EventName Elapsed -Action {
        Write-Host "[GITHUB] Checking for documentation updates..." -ForegroundColor Cyan
        
        # Check for drift
        if (Get-Command Test-DocumentationDrift -ErrorAction SilentlyContinue) {
            $drift = Test-DocumentationDrift -Path $using:PSScriptRoot
            if ($drift.HasDrift) {
                Write-Host "[DRIFT] Documentation drift detected" -ForegroundColor Yellow
                
                # Create PR if configured
                if (Get-Command New-GitHubPullRequest -ErrorAction SilentlyContinue) {
                    $pr = New-GitHubPullRequest `
                        -Title "docs: Auto-update documentation" `
                        -Body "Automated documentation update based on code changes" `
                        -Branch "docs/auto-update-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                    
                    if ($pr) {
                        Write-Host "[PR] Created PR #$($pr.number)" -ForegroundColor Green
                    }
                }
            }
        }
    }
    
    $githubTimer.Start()
}

# Keep script running
try {
    while ($true) {
        Start-Sleep -Seconds 10
        
        # Check job health
        if ($serverJob -and $serverJob.State -ne 'Running') {
            Write-Warning "Documentation server stopped. Restarting..."
            $serverJob = Start-Job -ScriptBlock ([ScriptBlock]::Create($serverScript)) -ArgumentList $Port, $OutputPath
        }
        
        # Display status
        if ($Debug) {
            $activeMonitors = $fileMonitorJobs | Where-Object { $_.State -eq 'Running' }
            Write-Host "[STATUS] Active monitors: $($activeMonitors.Count), Server: $($serverJob.State)" -ForegroundColor Gray
        }
    }
} finally {
    Write-Host "`nShutting down documentation agent..." -ForegroundColor Yellow
    
    # Cleanup
    $fileMonitorJobs | ForEach-Object { Stop-Job $_ -Force }
    if ($serverJob) { Stop-Job $serverJob -Force }
    if ($githubTimer) { $githubTimer.Stop() }
    
    Write-Host "Documentation agent stopped" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAaBtu3TxtSmz1L
# ae79oC9xMF/1aZIg4znIkOhPv0GicqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE9qRo2mtjn0FGc8cjuEysZO
# BU7WEMo3QldeO0kuNKWBMA0GCSqGSIb3DQEBAQUABIIBAIVUszS+sBdlJrfT528m
# XutLcIlLYG9wr9IBV4uMxdqUN2zGiEt9XgjHobZa7s+1w+/2NmbbIXZ+IDXkF/Io
# 7Ki0+nPBf/8lowk7aYK51dQrFllDtmLg6Hb4inieYIkOFa78HtCwcmt8h0Yms1vX
# I1t/MNEgPbj4FZ5rlikxWYObhcXiWpHCaqSsL0cIzVNsTFTE9vYJZzFE4e95OHyG
# QgWZx5ShIYE+8UKGwGTiWHxHQnZF3qnUdMHrSiht6tYoKlKFjAVoo9BGtFXmM/PN
# jdj+y/igV9l7B9JUfDtics5k7v9dvBLXkgscp46ZvqhRfkh7/KcKkcCuMI3A9sO/
# NSc=
# SIG # End signature block
