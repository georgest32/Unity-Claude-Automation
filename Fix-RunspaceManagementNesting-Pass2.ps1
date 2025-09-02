
# Fix-RunspaceManagementNesting-Pass2.ps1
# Cleans up leftover continuation/path-only lines after removing Import-Module statements,
# which can leave stray "\" or path fragments that break module load.

param(
    [string]$RunspaceModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-RunspaceManagement",
    [switch]$Verify,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Section {
    param([string]$t,[string]$c='Cyan')
    Write-Host "`n=== $t ===" -ForegroundColor $c
}
function Assert-Path {
    param([Parameter(Mandatory)][string]$p)
    if(-not (Test-Path -LiteralPath $p)){ throw "Path not found: $p" }
}

Section "Fix-RunspaceManagementNesting-Pass2"
Write-Host "RunspaceModulePath: $RunspaceModulePath" -ForegroundColor Yellow
Assert-Path -p $RunspaceModulePath

$psm1s = Get-ChildItem -LiteralPath $RunspaceModulePath -Recurse -Filter *.psm1 -ErrorAction SilentlyContinue

# Patterns that indicate a leftover continuation/path fragment line
$contRegexes = @(
    '^\s*\\\s*$',                                # a lone backslash
    '^\s*\\.*$',                                 # line starts with backslash path
    '^\s*\.\s*\\.*$',                            # .\something
    '^\s*\.\.\s*\\.*$',                          # ..\something
    '^\s*["'']\s*\\.*$',                         # " \something or ' \something
    '^\s*["'']\s*\.\s*\\.*$',                    # ".\something  or '.\something
    '^\s*["'']\s*\.\.\s*\\.*$',                  # "..\something or '..\something
    '^\s*\$PSScriptRoot\s*[\\/].*$',             # $PSScriptRoot\something
    '^\s*["'']\s*\$PSScriptRoot\s*[\\/].*$',     # "$PSScriptRoot\something or '$PSScriptRoot\something
    '^\s*[,;]\s*\\.*$'                           # continuation punctuation then backslash path
)

[int]$changedFiles = 0
foreach ($f in $psm1s) {
    $text  = Get-Content -LiteralPath $f.FullName -Raw
    $lines = [regex]::Split($text, "\r?\n")
    $orig  = @($lines)  # snapshot copy

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]

        # 1) Direct stray path-only / continuation lines
        $isPathOnly = $false
        foreach ($pat in $contRegexes) {
            if ($line -match $pat) { $isPathOnly = $true; break }
        }
        if ($isPathOnly) {
            if (-not $DryRun) { $lines[$i] = "# Removed stray path line: " + $line }
            continue
        }

        # 2) After our previous removal marker, also clean subsequent continuation lines
        if ($line -match '^\s*#\s*Removed by Fix-RunspaceManagementNesting') {
            $j = $i + 1
            while ($j -lt $lines.Length) {
                $next = $lines[$j]
                $matchCont = $false
                foreach ($pat in $contRegexes) {
                    if ($next -match $pat) { $matchCont = $true; break }
                }
                # extra heuristic: indented line that begins with path-ish chars
                if (-not $matchCont -and $next -match '^\s+([\\/]|\.{1,2}[\\/])') { $matchCont = $true }

                if ($matchCont) {
                    if (-not $DryRun) { $lines[$j] = "# Removed continuation after Import-Module: " + $next }
                    $j++
                    continue
                }
                break
            }
        }
    }

    # Write back if changed
    $modified = $false
    if ($lines.Length -ne $orig.Length) { $modified = $true }
    else {
        for ($k=0; $k -lt $lines.Length; $k++) {
            if ($lines[$k] -ne $orig[$k]) { $modified = $true; break }
        }
    }

    if ($modified) {
        if (-not $DryRun) {
            Set-Content -LiteralPath $f.FullName -Value ($lines -join "`r`n") -Encoding UTF8
            Write-Host "Patched stray lines in: $(Split-Path $f.FullName -Leaf)" -ForegroundColor Green
        } else {
            Write-Host "Would patch stray lines in: $(Split-Path $f.FullName -Leaf)" -ForegroundColor Yellow
        }
        $changedFiles++
    }
}

Write-Host "Files changed: $changedFiles" -ForegroundColor Green

if ($Verify) {
    Section "Verify import" 'Yellow'
    Get-Module Unity-Claude-RunspaceManagement* | Remove-Module -Force -ErrorAction SilentlyContinue
    $man = Get-ChildItem -LiteralPath $RunspaceModulePath -Filter *.psd1 | Select-Object -First 1
    if ($man) {
        Import-Module $man.FullName -Force -Verbose:$true
    } else {
        $root = Get-ChildItem -LiteralPath $RunspaceModulePath -Filter *.psm1 | Select-Object -First 1
        if ($root) { Import-Module $root.FullName -Force -Verbose:$true }
    }
    Write-Host "Verify complete." -ForegroundColor Green
}

Section "Done" 'Cyan'

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCADGPlDZRxlMIUi
# otxxaT8IPs3gJ8+oov7SeBio8qqYoKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPKTmRHAFRj+Z0YsvPoyP5KF
# 5AqGxxnYJ+oeZJN50NfHMA0GCSqGSIb3DQEBAQUABIIBAHrFtmqsxb5SK1Xd3fTy
# 0e3DFWuaSGHZu5OeGnkfta7RritpLvZfOgBfCfKoas1xes4Fp7DIcEPi4z/0X+VS
# hMtckp/kX+7A/jWLu9vRuX/6K20CLMFSsxUrvG4QXEGABqKaRHBhpb8AFDP2n+Sg
# hDXpqkxlARHt8+67Cr5MvqZa60iZbMvRosvZM71qyFWMJ+Z6wOV4W1mLovqEggQw
# B8zGy/j48PYjSWrIOtZ7R2bjAOuXyvsqyguNWvLADVHpk0aEvBtxYpaMv43RXfrQ
# JwrCmsIoQVfLeZSYTqFMUBGjLwXDMGMfjEk7+W/TdcWsjrtTmzI03DCfo0resbc7
# jjg=
# SIG # End signature block
