
# Fix-RunspaceManagementNesting.ps1
# Removes intra-module Import-Module loops and prevents hitting the PowerShell module nesting limit.
# Also validates by re-importing the module after patching.
# Usage:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File .\Fix-RunspaceManagementNesting.ps1 -RunspaceModulePath "C:\...\Unity-Claude-RunspaceManagement" -Verify
#   .\Fix-RunspaceManagementNesting.ps1 -DryRun

param(
    [string]$RunspaceModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement",
    [switch]$Verify,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Section([string]$t,[string]$c='Cyan'){ Write-Host "`n=== $t ===" -ForegroundColor $c }
function Assert-Path([string]$p){ if(-not (Test-Path -LiteralPath $p)){ throw "Path not found: $p" } }

Section "Fix-RunspaceManagementNesting"
Write-Host "RunspaceModulePath: $RunspaceModulePath" -ForegroundColor Yellow
Assert-Path $RunspaceModulePath

$core = Join-Path $RunspaceModulePath 'Core'
if (-not (Test-Path $core)) { throw "Core folder not found: $core" }

# 1) Preflight parse for syntax errors
Section "Preflight: Parse PSM1s" 'DarkCyan'
$psm1s = Get-ChildItem -LiteralPath $RunspaceModulePath -Recurse -Filter *.psm1 -ErrorAction SilentlyContinue
$bad=@()
foreach($f in $psm1s){
  $t=$null;$e=$null
  [void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$t,[ref]$e)
  if($e){ $bad += [PSCustomObject]@{ File=$f.FullName; Errors=($e|%{ $_.Message + " @Line " + $_.Extent.StartLineNumber }) } }
}
if($bad.Count){
  Write-Host "Parse errors found:" -ForegroundColor Red
  $bad | % { Write-Host " - $($_.File)" -ForegroundColor Red; $_.Errors | % { Write-Host "     $_" -ForegroundColor Red } }
  throw "Fix parse errors first."
}else{ Write-Host "No syntax errors detected." -ForegroundColor Green }

# 2) Strip intra-module Import-Module statements that cause recursion
Section "Removing intra-module imports that cause nesting" 'Yellow'

# Narrow patterns: Only remove imports that reference this same module or its Core files, or the ParallelProcessing module.
$patterns = @(
    '^\s*Import-Module\s+.*Unity-Claude-RunspaceManagement[\\/].*RunspaceCore\.psm1.*$',
    '^\s*Import-Module\s+.*Unity-Claude-RunspaceManagement[\\/].*Core[\\/].*\.psm1.*$',
    '^\s*Import-Module\s+.*Unity-Claude-RunspaceManagement(\.psd1|\.psm1)?.*$',
    '^\s*Using\s+Module\s+.*Unity-Claude-RunspaceManagement.*$',
    '^\s*Import-Module\s+.*Unity-Claude-ParallelProcessing(\.psd1|\.psm1)?.*$'
)

[int]$filesChanged = 0
foreach($f in $psm1s){
    $raw = Get-Content -LiteralPath $f.FullName -Raw
    $orig = $raw
    foreach($pat in $patterns){
        $raw = [System.Text.RegularExpressions.Regex]::Replace($raw, $pat, '# Removed by Fix-RunspaceManagementNesting: \0', 'Multiline,IgnoreCase')
    }
    if($raw -ne $orig){
        if($DryRun){
            Write-Host "Would patch: $(Split-Path $f.FullName -Leaf)" -ForegroundColor Yellow
        } else {
            Set-Content -LiteralPath $f.FullName -Value $raw -Encoding UTF8
            Write-Host "Patched: $(Split-Path $f.FullName -Leaf)" -ForegroundColor Green
            $filesChanged++
        }
    }
}
Write-Host "Files changed: $filesChanged" -ForegroundColor Green

# 3) Optional: Add a simple import guard in RunspaceCore.psm1 to avoid re-entrancy side-effects
$runspaceCore = Join-Path $core 'RunspaceCore.psm1'
if (Test-Path -LiteralPath $runspaceCore){
    $rcTxt = Get-Content -LiteralPath $runspaceCore -Raw
    if ($rcTxt -notmatch '\$script:__UCRM_RunspaceCore_Loaded'){
        $guard = @"
# === Added by Fix-RunspaceManagementNesting ===
if (\$script:__UCRM_RunspaceCore_Loaded) {
    # Prevent side-effects if this file is re-executed
    return
}
\$script:__UCRM_RunspaceCore_Loaded = \$true
# === End added ===
"@
        if($DryRun){
            Write-Host "Would inject re-entry guard into RunspaceCore.psm1" -ForegroundColor Yellow
        } else {
            Set-Content -LiteralPath $runspaceCore -Value ($guard + "`r`n" + $rcTxt) -Encoding UTF8
            Write-Host "Injected re-entry guard into RunspaceCore.psm1" -ForegroundColor Green
        }
    } else {
        Write-Host "Re-entry guard already present in RunspaceCore.psm1" -ForegroundColor DarkGreen
    }
} else {
    Write-Warning "RunspaceCore.psm1 not found; skipping guard injection."
}

# 4) Verification: try to import the RunspaceManagement module
if ($Verify){
    Section "Verifying: Import Unity-Claude-RunspaceManagement" 'Yellow'
    # clear loaded variants
    Get-Module Unity-Claude-RunspaceManagement* | Remove-Module -Force -ErrorAction SilentlyContinue

    $man = Get-ChildItem -LiteralPath $RunspaceModulePath -Filter *.psd1 | Select-Object -First 1
    if (-not $man) {
        Write-Warning "No manifest found in $RunspaceModulePath; attempting to import .psm1"
        $rootPsm1 = Get-ChildItem -LiteralPath $RunspaceModulePath -Filter *.psm1 | Select-Object -First 1
        if ($rootPsm1) {
            Import-Module $rootPsm1.FullName -Force -ErrorAction Stop -Verbose:$true
        } else {
            Write-Warning "No PSM1 found to import."
        }
    } else {
        Import-Module $man.FullName -Force -ErrorAction Stop -Verbose:$true
    }
    Write-Host "Import verification complete." -ForegroundColor Green
}

Section "Done" 'Cyan'

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC8JyYRc1W6jQtq
# a9sgySjEOHyhE+sEb3gaUPFHddG25qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICaoBCpS5m0sVeTNesww8gq+
# CUUohDRpbiysVgSkNl9mMA0GCSqGSIb3DQEBAQUABIIBAJd204mmTf86uJqwyKeJ
# x+MGEwv1/cUVQCYp5JksJESbVDeaAXG3TS+ItBzyJqmk891bFKF/TkwEhvhcK4tT
# H0BrtGBwNp5XX5meGFpuDov/p8bJ6uPImeYy0EzGyoxeSV3psDUZq+XJLMkm/Ua5
# rk2IO3C4UrzvmO2mFJvjxsgJkfxsDfemIQNLLyAK4bWCDUU9Qaz15tv4yfXEJoGM
# t+wQVZAzO9bWXPZc46R7OfVfrW46wIzYIM9MT/xYzwCHk7NOHLeyt1l1g7+EB5DS
# LBvBwrd7SMH2++zPcieDnvX2NLx6MVk0i4LICyXl6R96kEe03AdNJ15zIsHsYFUx
# AZg=
# SIG # End signature block
