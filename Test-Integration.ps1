# Test-Integration.ps1
# Integration smoke tests for the Unity-Claude Automation toolchain
# Safe for PowerShell 5.1+; ASCII-only; no here-strings or emojis.
# Date: 2025-08-17
#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$SkipDryRun   # Skip calling Import-ResearchedPatterns.ps1 -DryRun
)

$ErrorActionPreference = 'Stop'

# -----------------------------
# Helpers
# -----------------------------

function Add-PathIfMissing {
    param([Parameter(Mandatory=$true)][string]$PathToAdd)
    $sep = [System.IO.Path]::PathSeparator
    $current = ($env:PSModulePath -split [System.Text.RegularExpressions.Regex]::Escape($sep)) |
        Where-Object { $_ -and $_.Trim() } |
        ForEach-Object { [System.IO.Path]::GetFullPath($_) }
    $normalized = [System.IO.Path]::GetFullPath($PathToAdd)
    if (-not ($current -contains $normalized)) {
        $env:PSModulePath = "$PathToAdd$sep$($env:PSModulePath)"
    }
}

function Test-ParseFile {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Passed = $false; Message = "File not found: $Path" }
    }
    $tokens = $null; $errs = $null
    try {
        [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errs)
        if ($errs -and $errs.Count -gt 0) {
            $first = $errs[0]
            $loc = "Line {0}, Col {1}" -f $first.Extent.StartLineNumber, $first.Extent.StartColumnNumber
            $msg = "{0} at {1}. Text: {2}" -f $first.Message, $loc, $first.Extent.Text
            return [pscustomobject]@{ Passed = $false; Message = $msg }
        }
        return [pscustomobject]@{ Passed = $true; Message = "Parsed OK" }
    } catch {
        return [pscustomobject]@{ Passed = $false; Message = "Parse threw: $($_.Exception.Message)" }
    }
}

function Invoke-TestStep {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ScriptBlock]$Action
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $passed = $false; $msg = "OK"
    try { & $Action; $passed = $true } catch { $passed = $false; $msg = $_.Exception.Message } finally { $sw.Stop() }
    [pscustomobject]@{ Name=$Name; Passed=$passed; DurationMs=[int]$sw.ElapsedMilliseconds; Message=$msg }
}

# Collect results in a list (PS 5.1 friendly)
$results = New-Object System.Collections.Generic.List[object]

# Build common paths (relative to this script)
$root           = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$modulesRoot    = Join-Path $root 'Modules'
$processScript  = Join-Path $root 'Process-UnityErrorWithLearning.ps1'
$importPatterns = Join-Path $root 'Import-ResearchedPatterns.ps1'
$editorLogDir   = Join-Path $env:LOCALAPPDATA 'Unity\Editor'

# Verbose passthrough
$verbosePass = @{}
if ($PSBoundParameters.ContainsKey('Verbose') -and [bool]$PSBoundParameters['Verbose']) { $verbosePass['Verbose'] = $true }

Write-Host ""
Write-Host "=== Unity-Claude Integration Test ===" -ForegroundColor Cyan

# -----------------------------
# Tests
# -----------------------------

# 1) PowerShell version
$results.Add( (Invoke-TestStep -Name "PowerShell version" -Action {
    $v = $PSVersionTable.PSVersion
    if ($v.Major -lt 5) { throw "PowerShell $v detected; require 5.1 or later." }
    Write-Verbose ("Detected PowerShell {0}" -f $v)
}) )

# 2) Ensure local Modules path is present in PSModulePath
$results.Add( (Invoke-TestStep -Name "Modules path available" -Action {
    if (-not (Test-Path -LiteralPath $modulesRoot)) { throw "Modules directory not found: $modulesRoot" }
    Add-PathIfMissing -PathToAdd $modulesRoot
}) )

# 3) Check required module folders exist (without importing)
$requiredModules = @('Unity-Claude-Core','Unity-Claude-Errors','Unity-Claude-IPC','Unity-Claude-Learning-Simple')
$results.Add( (Invoke-TestStep -Name "Module folders present" -Action {
    $missing = @()
    foreach ($m in $requiredModules) {
        $p = Join-Path $modulesRoot $m
        if (-not (Test-Path -LiteralPath $p)) { $missing += $m }
    }
    if ($missing.Count -gt 0) { throw ("Missing modules: {0}" -f ($missing -join ', ')) }
}) )

# 4) Parse key scripts for syntax validity (no execution)
$results.Add( (Invoke-TestStep -Name "Parse: Process-UnityErrorWithLearning.ps1" -Action {
    $r = Test-ParseFile -Path $processScript
    if (-not $r.Passed) { throw $r.Message }
}) )
$results.Add( (Invoke-TestStep -Name "Parse: Import-ResearchedPatterns.ps1" -Action {
    $r = Test-ParseFile -Path $importPatterns
    if (-not $r.Passed) { throw $r.Message }
}) )

# 5) Import core learning module and check key commands exist
$results.Add( (Invoke-TestStep -Name "Import learning module" -Action {
    Import-Module Unity-Claude-Learning-Simple -Force -ErrorAction Stop
    $needCmds = @('Initialize-LearningStorage','Add-ErrorPattern','Get-LearningConfig')
    $missing = @()
    foreach ($c in $needCmds) { if (-not (Get-Command $c -ErrorAction SilentlyContinue)) { $missing += $c } }
    if ($missing.Count -gt 0) { throw ("Module missing exported commands: {0}" -f ($missing -join ', ')) }
}) )

# 6) Initialize learning storage (no-op safe if already initialized)
$results.Add( (Invoke-TestStep -Name "Initialize learning storage" -Action {
    Initialize-LearningStorage -ErrorAction Stop | Out-Null
}) )

# 7) Dry-run pattern import (skippable)
if (-not $SkipDryRun) {
    $results.Add( (Invoke-TestStep -Name "Dry-run pattern import" -Action {
        if (-not (Test-Path -LiteralPath $importPatterns)) { throw "Import-ResearchedPatterns.ps1 not found." }
        & $importPatterns -DryRun @verbosePass
    }) )
}

# 8) Unity Editor log directory presence (monitor mode depends on it)
$results.Add( (Invoke-TestStep -Name "Unity Editor log directory" -Action {
    if (-not (Test-Path -LiteralPath $editorLogDir)) { throw ("Editor log directory not found: {0}" -f $editorLogDir) }
}) )

# -----------------------------
# Report
# -----------------------------
$total  = $results.Count
$passed = ($results | Where-Object { $_.Passed }).Count
$failed = $total - $passed
$avgMs  = if ($total -gt 0) { [int](($results | Measure-Object -Property DurationMs -Average).Average) } else { 0 }
$perf   = if ($avgMs -lt 100) { 'A' } elseif ($avgMs -lt 500) { 'B' } else { 'C' }

Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host ("Total  : {0}" -f $total)
Write-Host ("Passed : {0}" -f $passed) -ForegroundColor Green
if ($failed -gt 0) { Write-Host ("Failed : {0}" -f $failed) -ForegroundColor Yellow } else { Write-Host ("Failed : {0}" -f $failed) }
Write-Host ("Average step time: {0} ms (Perf grade {1})" -f $avgMs, $perf)

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failures:" -ForegroundColor Yellow
    $i = 1
    foreach ($r in $results | Where-Object { -not $_.Passed }) {
        Write-Host ("  {0}. {1} -> {2}" -f $i, $r.Name, $r.Message)
        $i++
    }
}

# Optional: write a text report next to the script
try {
    $reportPath = Join-Path $root 'Test-Integration-Report.txt'
    $lines = @()
    $lines += "Unity-Claude Integration Test Report"
    $lines += ("Timestamp: {0:yyyy-MM-dd HH:mm:ss}" -f (Get-Date))
    $lines += ""
    foreach ($r in $results) {
        $status = if ($r.Passed) { "PASS" } else { "FAIL" }
        $lines += ("[{0}] {1} ({2} ms) - {3}" -f $status, $r.Name, $r.DurationMs, $r.Message)
    }
    $lines += ""
    $lines += ("Summary: {0}/{1} passed; {2} failed; Avg {3} ms; Grade {4}" -f $passed, $total, $failed, $avgMs, $perf)
    $lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Host ""
    Write-Host ("Report written: {0}" -f $reportPath) -ForegroundColor Gray
} catch {
    Write-Host ("Could not write report: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if ($failed -gt 0) { $global:LASTEXITCODE = 1 } else { $global:LASTEXITCODE = 0 }

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUih05+SqROLz8OlRlzi5ElD6s
# LWqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUArtsHH69ziv0nAlefCK0aw2e9DAwDQYJKoZIhvcNAQEBBQAEggEAeopr
# rtgBJiFkqGiWMd58aBob+SrmYMZP99IYLyF+8YRDr5oP5zxo/XO6b81wmKfyjJMw
# eHhIckad8ELhAGTFOwd0wCfo18gHO4DUo0H1+U+O/LKVtZBY03BRy30mqTjA/XTM
# X8O1UeYhHchVL3mu38RvtCg8HyYvgn55Jdwwk42XS2olawR2pBn9+23fIGsXV1On
# U65E+gmoYtCe+n/WbhkdS0GGsj7V7551iN4kgAU9iXqhApwj7Iz0jVAMmNar7SIU
# 6BYyyWiwbfa+ywr4iIRCrhJBGRZd7xo2MVZ2i5msjTt3JC6nx8ks27wcfHESCiGB
# vS3JcVrxfmZgVH6ttw==
# SIG # End signature block
