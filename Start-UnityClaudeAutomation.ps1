# Start-UnityClaudeAutomation.ps1
# Quick launcher for Unity-Claude Automation with Learning System
# ASCII-only to avoid encoding issues. PowerShell 5.1+.
# Date: 2025-08-17
#requires -Version 5.1


# PowerShell 7 Self-Elevation

param(
    # Accept Mode by name OR position 0 (so: .\Start-UnityClaudeAutomation.ps1 Test)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

[CmdletBinding()]
[Parameter(Position=0)]
    [ValidateSet('Monitor', 'Once', 'Test', 'Setup')]
    [string]$Mode = 'Once',

    [switch]$UseAPI,
    [switch]$AutoFix
)

# Fallback: if named binding didn't happen but a bare arg was passed, use it.
if (-not $PSBoundParameters.ContainsKey('Mode') -and $args.Count -ge 1 -and $args[0]) {
    $Mode = $args[0]
}

$ErrorActionPreference = 'Stop'

# ----- Plain ASCII banner -----
$banner = @(
'============================================================'
'  Unity-Claude Automation System v3.0'
'  Intelligent Error Resolution with Learning'
'============================================================'
) -join "`n"
Write-Host $banner -ForegroundColor Cyan

# Helper: build -Verbose passthrough only if requested
$verbosePass = @{}
if ($PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']) {
    $verbosePass['Verbose'] = $true
}

# Paths to child scripts (same directory as this file)
$root           = Split-Path -Parent $MyInvocation.MyCommand.Path
$processScript  = Join-Path $root 'Process-UnityErrorWithLearning.ps1'
$importPatterns = Join-Path $root 'Import-ResearchedPatterns.ps1'
$testsScript    = Join-Path $root 'Test-Integration.ps1'

# ----- API key check (only if requested) -----
if ($UseAPI -and -not $env:ANTHROPIC_API_KEY) {
    Write-Host "`nAPI mode requested but no API key found." -ForegroundColor Yellow
    Write-Host "Set your key with: `$env:ANTHROPIC_API_KEY = 'your-key-here'" -ForegroundColor Gray

    $response = Read-Host "`nEnter API key now (or press Enter to continue without API)"
    if ($response) {
        $env:ANTHROPIC_API_KEY = $response
        Write-Host "API key set for this session." -ForegroundColor Green
    } else {
        $UseAPI = $false
        Write-Host "Continuing without API support." -ForegroundColor Gray
    }
}

switch ($Mode) {

    'Setup' {
        Write-Host "`n=== SETUP MODE ===" -ForegroundColor Yellow
        Write-Host "Installing required components..." -ForegroundColor Gray

        # Check PowerShell version
        Write-Host "`nChecking PowerShell version..." -ForegroundColor Gray
        $psVersion = $PSVersionTable.PSVersion
        $vColor = if ($psVersion.Major -ge 5) { 'Green' } else { 'Red' }
        Write-Host ("  PowerShell {0} detected" -f $psVersion) -ForegroundColor $vColor

        # Check local Modules folder contents (optional)
        Write-Host "`nChecking modules..." -ForegroundColor Gray
        $modulePath = Join-Path $root 'Modules'
        $modules = @(
            'Unity-Claude-Core',
            'Unity-Claude-Errors',
            'Unity-Claude-IPC',
            'Unity-Claude-Learning-Simple'
        )
        foreach ($module in $modules) {
            $moduleLoc = Join-Path $modulePath $module
            if (Test-Path $moduleLoc) {
                Write-Host "  [OK] $module found" -ForegroundColor Green
            } else {
                Write-Host "  [MISSING] $module" -ForegroundColor Red
            }
        }

        # Initialize learning patterns (safe if already imported)
        Write-Host "`nInitializing learning patterns..." -ForegroundColor Gray
        if (Test-Path $importPatterns) {
            & $importPatterns @verbosePass
        } else {
            Write-Host "  Could not find Import-ResearchedPatterns.ps1" -ForegroundColor Yellow
        }

        Write-Host "`nSetup complete." -ForegroundColor Green
    }

    'Test' {
        Write-Host "`n=== TEST MODE ===" -ForegroundColor Yellow
        Write-Host "Running integration tests..." -ForegroundColor Gray

        $resolvedTests = $testsScript
        Write-Host ("Using test file: {0}" -f $resolvedTests) -ForegroundColor Gray

        if (Test-Path $resolvedTests) {
            # Pre-parse to give a precise error (line/col/text) before invoking
            $tokens = $null; $errs = $null
            [System.Management.Automation.Language.Parser]::ParseFile($resolvedTests, [ref]$tokens, [ref]$errs) > $null
            if ($errs -and $errs.Count -gt 0) {
                $e = $errs[0]
                Write-Host ("Syntax error in {0} at line {1}, col {2}: {3}" -f $resolvedTests, $e.Extent.StartLineNumber, $e.Extent.StartColumnNumber, $e.Message) -ForegroundColor Red
                Write-Host ("Offending text: {0}" -f $e.Extent.Text.Trim()) -ForegroundColor Red
                break
            }
            & $resolvedTests @verbosePass
        } else {
            Write-Host "Test-Integration.ps1 not found. Running inline smoke tests..." -ForegroundColor Yellow

            # PS version
            $v = $PSVersionTable.PSVersion
            if ($v.Major -lt 5) {
                Write-Host ("PowerShell {0} detected; require 5.1 or later." -f $v) -ForegroundColor Red
                break
            } else {
                Write-Host ("PowerShell {0} OK" -f $v) -ForegroundColor Green
            }

            # Modules folder present
            $modulesRoot = Join-Path $root 'Modules'
            if (Test-Path $modulesRoot) {
                Write-Host ("Modules folder present: {0}" -f $modulesRoot) -ForegroundColor Green
            } else {
                Write-Host ("Modules folder missing: {0}" -f $modulesRoot) -ForegroundColor Yellow
            }

            Write-Host "Inline smoke tests finished." -ForegroundColor Green
        }
    }

    'Monitor' {
        Write-Host "`n=== MONITOR MODE ===" -ForegroundColor Yellow
        Write-Host "Starting continuous monitoring..." -ForegroundColor Gray
        Write-Host "Press Ctrl+C to stop" -ForegroundColor DarkGray

        if (-not (Test-Path $processScript)) {
            Write-Host "Missing Process-UnityErrorWithLearning.ps1" -ForegroundColor Red
            break
        }

        # FileSystemWatcher for the Unity Editor log
        $editorLogDir = Join-Path $env:LOCALAPPDATA 'Unity\Editor'
        if (-not (Test-Path $editorLogDir)) {
            Write-Host ("Editor log directory not found: {0}" -f $editorLogDir) -ForegroundColor Yellow
            break
        }

        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $editorLogDir
        $watcher.Filter = 'Editor.log'
        $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

        # Prepare shared config/state for the event runspace
        $shared = [hashtable]::Synchronized(@{
            ProcPath = $processScript
            UseAPI   = [bool]$UseAPI
            AutoFix  = [bool]$AutoFix
            Verbose  = $verbosePass.ContainsKey('Verbose')
            State    = [hashtable]::Synchronized(@{ LastRun = [datetime]::MinValue })
        })

        $action = {
            # Pull config/state passed via MessageData
            $cfg   = $event.MessageData
            $state = $cfg.State

            # Debounce: ignore events within 500ms
            $now = Get-Date
            if (($now - $state.LastRun).TotalMilliseconds -lt 500) { return }
            $state.LastRun = $now

            Write-Host ("`n[{0}] Change detected, processing..." -f (Get-Date -Format 'HH:mm:ss')) -ForegroundColor Yellow

            $params = @{
                UseAPI  = $cfg.UseAPI
                AutoFix = $cfg.AutoFix
            }
            if ($cfg.Verbose) { $params['Verbose'] = $true }

            & $cfg.ProcPath @params
        }

        # Stable SourceIdentifier for clean teardown
        $srcId = 'EditorLogChanged'
        try {
            $subscription = Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier $srcId -Action $action -MessageData $shared
        } catch {
            Write-Host ("Failed to register file watcher event: {0}" -f $_.Exception.Message) -ForegroundColor Red
            $watcher.Dispose()
            break
        }

        $watcher.EnableRaisingEvents = $true
        Write-Host "`nMonitoring started." -ForegroundColor Green
        Write-Host ("Watching: {0}\{1}" -f $watcher.Path, $watcher.Filter) -ForegroundColor Gray

        try {
            while ($true) { Start-Sleep -Seconds 1 }
        } finally {
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
            Unregister-Event -SourceIdentifier $srcId -ErrorAction SilentlyContinue
            if ($subscription) {
                Remove-Job -Id $subscription.Id -Force -ErrorAction SilentlyContinue
            }
            Write-Host "`nMonitoring stopped." -ForegroundColor Yellow
        }
    }

    'Once' {
        Write-Host "`n=== SINGLE RUN MODE ===" -ForegroundColor Yellow

        if (-not (Test-Path $processScript)) {
            Write-Host "Missing Process-UnityErrorWithLearning.ps1" -ForegroundColor Red
            break
        }

        $params = @{
            UseAPI  = [bool]$UseAPI
            AutoFix = [bool]$AutoFix
        }
        & $processScript @params @verbosePass
    }
}

# End of file

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyz7yB2L3UqEQgRGeOWYEhrlg
# 3sSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUwF8p46XP4xWfS477jXFo2rblXikwDQYJKoZIhvcNAQEBBQAEggEAMJQC
# Kl1xQv53g49FMdUkadexCo5jZ3wGk44Fip6uGfo9P75efX5hHsRX/qqjzdKx+uVg
# /5zaLqXjgXC2DGzd8ubyGhbr5rcGoNWIiFigbtoXidQZLhWcj8a6VsD2yGae9i60
# ZipvAiaHbN2iJjQ+71JLBm8v1wBSg47mqTEgw9XREaKULUiwK+i0alsG3NSjIVO3
# luIv7GR4VvF3AaHTj4knA/PSQPWbribVwSkG38g0fshO7Lh2BbL4laYKKuAcMNiN
# C29toDFTLJdrS6lH/I2Fb+fz9E85zfo8eGkEsN0ZiPNssIMolWov+KKJD/VwgoSQ
# koYz0kHswGUZLKagNQ==
# SIG # End signature block


