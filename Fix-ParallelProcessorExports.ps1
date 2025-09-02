
# Fix-ParallelProcessorExports.ps1
# Comprehensive script to fix export/manifest issues in Unity-Claude-ParallelProcessor (refactored)
# Usage:
#   .\Fix-ParallelProcessorExports.ps1
#   .\Fix-ParallelProcessorExports.ps1 -ModulePath "C:\path\to\module"
#   .\Fix-ParallelProcessorExports.ps1 -TestOnly
#   .\Fix-ParallelProcessorExports.ps1 -RunTests

param(
    [string]$ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ParallelProcessor",
    [switch]$TestOnly,
    [switch]$RunTests
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Text, [string]$Color = 'Cyan')
    Write-Host ""
    Write-Host ("=== {0} ===" -f $Text) -ForegroundColor $Color
}

function Assert-Path {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Path not found: $Path"
    }
}

function Test-ParsePSM1s {
    param([Parameter(Mandatory)][string]$Folder)
    $bad = @()
    $psm1s = Get-ChildItem -LiteralPath $Folder -Recurse -Filter *.psm1 -ErrorAction SilentlyContinue
    foreach ($f in $psm1s) {
        $tokens=$null;$errors=$null
        [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$tokens,[ref]$errors)
        if ($errors) {
            $bad += [PSCustomObject]@{
                File   = $f.FullName
                Errors = ($errors | ForEach-Object { $_.Message + " @Line " + $_.Extent.StartLineNumber })
            }
        }
    }
    return ,$bad
}

Write-Section "Unity-Claude-ParallelProcessor Export Fix Script"
Write-Host "ModulePath: $ModulePath" -ForegroundColor Yellow

Assert-Path -Path $ModulePath

# Detect orchestrator/root PSM1 and manifest
$RootPsm1Candidates = @(
    (Join-Path $ModulePath 'Unity-Claude-ParallelProcessor-Refactored.psm1'),
    (Join-Path $ModulePath 'Unity-Claude-ParallelProcessor.psm1')
) | Where-Object { Test-Path $_ }

if (-not $RootPsm1Candidates -or $RootPsm1Candidates.Count -eq 0) {
    throw "Cannot find root PSM1 in $ModulePath"
}
$RootPsm1 = $RootPsm1Candidates[0]

$ManifestPath = Join-Path $ModulePath 'Unity-Claude-ParallelProcessor.psd1'
if (-not (Test-Path $ManifestPath)) {
    Write-Warning "Manifest not found: $ManifestPath (continuing)"
}

# Critical functions expected by tests/consumers
$CriticalFunctions = @(
  'Get-OptimalThreadCount',
  'New-RunspacePoolManager',
  'New-JobScheduler',
  'New-StatisticsTracker',
  'Test-RunspacePoolHealth',
  'Format-StatisticsReport',
  'New-ParallelProcessor',
  'Invoke-Parallel',
  'Stop-ParallelProcessor',
  'Get-ParallelStatistics',
  # common alternates
  'Invoke-ParallelProcessing',
  'Start-BatchProcessing',
  'Get-ParallelProcessorStatistics',
  'Test-ParallelProcessorHealth',
  'Get-UnityClaudeParallelProcessorInfo'
) | Select-Object -Unique

Write-Section "Preflight: Parsing PSM1s for syntax errors" 'DarkCyan'
$parseIssues = Test-ParsePSM1s -Folder $ModulePath
if ($parseIssues.Count -gt 0) {
    Write-Host "Found parse errors in:" -ForegroundColor Red
    $parseIssues | ForEach-Object {
        Write-Host (" - {0}" -f $_.File) -ForegroundColor Red
        $_.Errors | ForEach-Object { Write-Host ("     {0}" -f $_) -ForegroundColor Red }
    }
    throw "Fix parse errors before proceeding."
} else {
    Write-Host "No syntax errors detected." -ForegroundColor Green
}

Write-Section "Step 1: Ensure submodules export functions" 'Yellow'
$funcToFile = @{}
$psm1sAll = Get-ChildItem -LiteralPath $ModulePath -Recurse -Filter *.psm1 -ErrorAction SilentlyContinue
foreach ($file in $psm1sAll) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    foreach ($fn in $CriticalFunctions) {
        if ($funcToFile.ContainsKey($fn)) { continue }
        if ($content -match "(?ms)^\s*function\s+$([regex]::Escape($fn))\b") {
            $funcToFile[$fn] = $file.FullName
        }
    }
}

foreach ($kv in $funcToFile.GetEnumerator()) {
    $fn = $kv.Key
    $path = $kv.Value
    $txt = Get-Content -LiteralPath $path -Raw
    $already = $false
    foreach ($line in ($txt -split "`r?`n")) {
        if ($line -match '^\s*Export-ModuleMember\b' -and $line -match [regex]::Escape($fn)) {
            $already = $true; break
        }
    }
    if (-not $already) {
        if ($TestOnly) {
            Write-Host "Would append export for $fn in $path" -ForegroundColor Yellow
        } else {
            Add-Content -LiteralPath $path -Value "`r`n# Added by Fix-ParallelProcessorExports`r`nExport-ModuleMember -Function $fn`r`n"
            Write-Host "Appended export for $fn in $([System.IO.Path]::GetFileName($path))" -ForegroundColor Green
        }
    } else {
        Write-Host "Already exported: $fn ($([System.IO.Path]::GetFileName($path)))" -ForegroundColor DarkGreen
    }
}

Write-Section "Step 2: Root module export section" 'Yellow'
$rootTxt = Get-Content -LiteralPath $RootPsm1 -Raw
if ($rootTxt -notmatch '\$__publicFunctions\s*=') {
$exportBlock = @"
# === Added by Fix-ParallelProcessorExports ===
try {
    \$__publicFunctions = @(
        'Format-StatisticsReport',
        'Get-OptimalThreadCount',
        'Get-ParallelStatistics',
        'New-JobScheduler',
        'New-ParallelProcessor',
        'New-RunspacePoolManager',
        'New-StatisticsTracker',
        'Stop-ParallelProcessor',
        'Invoke-Parallel'
    ) | Where-Object { \$_ -and (Get-Command \$_ -ErrorAction SilentlyContinue) }

    if (\$__publicFunctions.Count -gt 0) {
        Export-ModuleMember -Function \$__publicFunctions
    } else {
        Write-Verbose "No public functions matched the critical list; exporting all as fallback."
        Export-ModuleMember -Function *
    }
} catch {
    Export-ModuleMember -Function *
}
# === End added ===
"@

    if ($TestOnly) {
        Write-Host "Would append root export block to $RootPsm1" -ForegroundColor Yellow
    } else {
        Set-Content -LiteralPath $RootPsm1 -Value ($rootTxt.TrimEnd() + "`r`n`r`n" + $exportBlock) -Encoding UTF8
        Write-Host "Root export block appended to $([System.IO.Path]::GetFileName($RootPsm1))" -ForegroundColor Green
    }
} else {
    Write-Host "Root export section already present" -ForegroundColor DarkGreen
}

if (Test-Path -LiteralPath $ManifestPath) {
    Write-Section "Step 3: Update manifest" 'Yellow'
    $manTxt = Get-Content -LiteralPath $ManifestPath -Raw
    $changed = $false

    if ($manTxt -match "FunctionsToExport\s*=\s*@\([^)]+\)" -or $manTxt -match "FunctionsToExport\s*=\s*'[^']*'") {
        if (-not $TestOnly) {
            $manTxt = $manTxt -replace "FunctionsToExport\s*=\s*@\([^)]+\)", "FunctionsToExport = '*'"
            $manTxt = $manTxt -replace "FunctionsToExport\s*=\s*'[^']*'", "FunctionsToExport = '*'"
            $changed = $true
            Write-Host "Set FunctionsToExport='*'" -ForegroundColor Green
        } else {
            Write-Host "Would set FunctionsToExport='*'" -ForegroundColor Yellow
        }
    } else {
        Write-Host "FunctionsToExport already wildcard or not present" -ForegroundColor DarkGreen
    }

    $refactoredName = [System.IO.Path]::GetFileName($RootPsm1)
    if ($manTxt -notmatch [regex]::Escape("RootModule = '$refactoredName'")) {
        if (-not $TestOnly) {
            $manTxt = $manTxt -replace "RootModule\s*=\s*'[^']*'", "RootModule = '$refactoredName'"
            $changed = $true
            Write-Host "Set RootModule='$refactoredName'" -ForegroundColor Green
        } else {
            Write-Host "Would set RootModule='$refactoredName'" -ForegroundColor Yellow
        }
    } else {
        Write-Host "RootModule already set to $refactoredName" -ForegroundColor DarkGreen
    }

    if (-not $TestOnly -and $changed) {
        Set-Content -LiteralPath $ManifestPath -Value $manTxt -Encoding UTF8
    }
} else {
    Write-Warning "Manifest not found; skipping manifest updates."
}

Write-Section "Step 4: Import & Verify" 'Yellow'
Get-Module Unity-Claude-ParallelProcessor* | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    if (Test-Path -LiteralPath $ManifestPath) {
        $mod = Import-Module $ManifestPath -Force -PassThru -ErrorAction Stop
        Write-Host "Imported via manifest: $($mod.Name) v$($mod.Version)" -ForegroundColor Green
    } else {
        $mod = Import-Module $RootPsm1 -Force -PassThru -ErrorAction Stop
        Write-Host "Imported via root PSM1: $($mod.Name)" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to import module: $($_.Exception.Message)"
    throw
}

$available = @()
$missing   = @()
foreach ($fn in $CriticalFunctions) {
    if (Get-Command $fn -ErrorAction SilentlyContinue) { $available += $fn } else { $missing += $fn }
}

Write-Host ("Available: {0}" -f ($available -join ', ')) -ForegroundColor Green
if ($missing.Count -gt 0) {
    Write-Host ("Missing:   {0}" -f ($missing -join ', ')) -ForegroundColor Yellow
} else {
    Write-Host "All critical functions are available." -ForegroundColor Green
}

if ($RunTests) {
    Write-Section "Step 5: Running ParallelProcessor test suite" 'Yellow'
    $testPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-ParallelProcessor-Refactored.ps1"
    if (Test-Path -LiteralPath $testPath) {
        & $testPath
    } else {
        Write-Warning "Test file not found at: $testPath"
    }
}

Write-Section "Done" 'Cyan'

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBUveneOjX9XicI
# Joxpp/KPpWQ/PPjU9qkUGpnVzBmAAaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHmjtbFn3OzEm19Fv1CF4ZPh
# louz0wQpbAiynTHHmFDNMA0GCSqGSIb3DQEBAQUABIIBAHvKljJqjroEGC6yLQyC
# cRKQMTQn/VJMrtWGEZeqKrq57BvcJr0He0NCc9nzhqcDMcvj9KCNLslrMKon/12r
# DbNi1N9avIM9yMOrO1Zmn3Hj99MccAaGu2On2c5L9Hb6rgTgq94a767wYgoCCHo1
# AMdg2eYcKei3JlefJj9ETiZlyFIly2AlEe4+kaKSKoevyRGPoIz2Jo5SKILyUYMh
# 8wR+y3bOFL2wkFmy/YYHOgYlI01NI1Iyl5RuGpVIFZ8ZdnpnWhkffX+HlaHKy4yu
# 7i6v7PD/Ic4F+lUBIoNiKd1dlbRE2TtgCHPHVj25f8l4vDHCGBbBP+nUBjPmGeLm
# 9FE=
# SIG # End signature block
