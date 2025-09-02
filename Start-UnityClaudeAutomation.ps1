# Start-UnityClaudeAutomation.ps1
# Quick launcher for Unity-Claude Automation with Learning System
# ASCII-only to avoid encoding issues. PowerShell 5.1+.
# Date: 2025-08-17
#requires -Version 5.1


# PowerShell 7 Self-Elevation

[CmdletBinding()]
param(
    # Accept Mode by name OR position 0 (so: .\Start-UnityClaudeAutomation.ps1 Test)
    [Parameter(Position=0)]
    [ValidateSet('Monitor', 'Once', 'Test', 'Setup')]
    [string]$Mode = 'Once',

    [switch]$UseAPI,
    [switch]$AutoFix
)

# PowerShell 7 Self-Elevation
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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBlC+u7ApTtaj9f
# ftWEt7LrVebYQ6TEmW1xqrMBCPKzhKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOK9Owe9UuiioK4Jx4FiT3Tf
# FQifAa6aaTXZ5b7l3F4gMA0GCSqGSIb3DQEBAQUABIIBADjfq1xPRNzVCR8bhDgU
# NvRjAs4mHc2EDFexSRJHrX42JoxQEStv/+wL4/ipydUeWYfhq2tHXErpd1C3L1QT
# WUYjgnjyG7pzew63gM8vSOEx96XJdy6/6fWN3G00O9GuNyWkKPMHlh29ennS6K6W
# 3Q9heM/b82FJkPouEJp3w/NWd0IRT6EDTTfyQov1nnvA1BedwJkvdbCgBRH3JNKT
# b3WNZKonxkE/gRVdLtgnpr+Th6yUlMO9hy5fpmEM+nlcdnbs4jl6o9O6VQ89hCT/
# x+V/EdhnR600jrytSNvxkPX9gGbSDjk2uP3zBgJtdhzyfnA76FHbQjN6IVmWUH1M
# w0o=
# SIG # End signature block
