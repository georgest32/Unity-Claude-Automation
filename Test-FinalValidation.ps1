# Final validation of CPG module fixes
cd 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

Write-Host '=== Final CPG Validation ===' -ForegroundColor Cyan

# Clean reload
Write-Host 'Cleaning and reloading modules...' -ForegroundColor Yellow
'Unity-Claude-CPG','Unity-Claude-CPG-ASTConverter','Unity-Claude-SemanticAnalysis' |
  ForEach-Object { Get-Module $_ -All | Remove-Module -Force -ErrorAction SilentlyContinue }

Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force -Global
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1' -Force

# Create test graph with pattern-like structures
$g = ConvertTo-CPGFromScriptBlock -ScriptBlock {
  function Get-SingletonInstance { 
    if(-not $script:instance) { 
      $script:instance = [pscustomobject]@{Id=1} 
    }
    return $script:instance 
  }
  function New-ItemFactory {
    param([string]$Type)
    if($Type -eq 'A') { 
      New-Object psobject 
    } else { 
      New-Object psobject 
    } 
  }
}

Write-Host "Graph created with $($g.Nodes.Count) nodes" -ForegroundColor Green

# Test analysis functions return arrays
Write-Host ''
Write-Host 'Testing analysis functions...' -ForegroundColor Yellow

$VerbosePreference = 'Continue'

Write-Host '  Find-DesignPatterns...' -ForegroundColor Cyan
$patterns = Find-DesignPatterns -Graph $g -Verbose
$patternsOk = ($patterns -is [array])
Write-Host "    Returns array: $patternsOk $(if($patternsOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($patternsOk){'Green'}else{'Red'})

Write-Host '  Get-CodePurpose...' -ForegroundColor Cyan
$purposes = Get-CodePurpose -Graph $g -Verbose
$purposesOk = ($purposes -is [array])
Write-Host "    Returns array: $purposesOk $(if($purposesOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($purposesOk){'Green'}else{'Red'})

Write-Host '  Get-CohesionMetrics...' -ForegroundColor Cyan
$cohesion = Get-CohesionMetrics -Graph $g -Verbose
$cohesionOk = ($cohesion -is [array])
Write-Host "    Returns array: $cohesionOk $(if($cohesionOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($cohesionOk){'Green'}else{'Red'})

Write-Host '  Extract-BusinessLogic...' -ForegroundColor Cyan
$biz = Extract-BusinessLogic -Graph $g -Verbose
$bizOk = ($biz -is [array])
Write-Host "    Returns array: $bizOk $(if($bizOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($bizOk){'Green'}else{'Red'})

Write-Host '  Recover-Architecture...' -ForegroundColor Cyan
$arch = Recover-Architecture -Graph $g -Verbose
$archOk = ($arch -is [array])
Write-Host "    Returns array: $archOk $(if($archOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($archOk){'Green'}else{'Red'})

$VerbosePreference = 'SilentlyContinue'

# Test OutputFormat
Write-Host ''
Write-Host 'Testing New-QualityReport OutputFormat...' -ForegroundColor Yellow
try {
    if (-not (Test-Path '.\test-reports')) {
        New-Item -Path '.\test-reports' -ItemType Directory -Force | Out-Null
    }
    
    # Test case-insensitive HTML
    $htmlReport = New-QualityReport -Graph $g -OutputPath '.\test-reports' -OutputFormat html -Format @('JSON')
    $htmlOk = ($htmlReport -is [hashtable])
    Write-Host "  HTML format (lowercase): $(if($htmlOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($htmlOk){'Green'}else{'Red'})
    
    # Test JSON
    $jsonReport = New-QualityReport -Graph $g -OutputPath '.\test-reports' -OutputFormat Json -Format @('JSON')
    $jsonOk = ($jsonReport -is [string] -and $jsonReport -like '*{*}*')
    Write-Host "  JSON format: $(if($jsonOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($jsonOk){'Green'}else{'Red'})
    
    # Test Markdown
    $mdReport = New-QualityReport -Graph $g -OutputPath '.\test-reports' -OutputFormat Markdown -Format @('JSON')
    $mdOk = ($mdReport -is [string] -and $mdReport -like '*# Code Quality Report*')
    Write-Host "  Markdown format: $(if($mdOk){'[OK]'}else{'[FAIL]'})" -ForegroundColor $(if($mdOk){'Green'}else{'Red'})
} catch {
    Write-Host "  OutputFormat test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ''
$allOk = $patternsOk -and $purposesOk -and $cohesionOk -and $bizOk -and $archOk
if ($allOk) {
    Write-Host '=== All Tests Passed ===' -ForegroundColor Green
} else {
    Write-Host '=== Some Tests Failed ===' -ForegroundColor Red
}

Write-Host ''
Write-Host 'Running full test suite...' -ForegroundColor Yellow
.\Test-SemanticAnalysis.ps1 -TestType All
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDLtZpa9LXi9EoT
# cKa0DdCd+eUgpfdbzFC0G1iQfbwVOaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHe7vsXWASP5jc629JR8nXyg
# 6Z7CDhzRabLt4MzXPoygMA0GCSqGSIb3DQEBAQUABIIBADiTnSltcnfwQGDI7447
# Fg69/LKX2Hz4OsGDGzDV5BJA+Za55oy44DYEAlH34HMRd32gY0ub/tpHnJmk+Cg0
# K56RaqC8LKPtM7FxcnnBPZtHEZ1rbfAAYLrwAnGYamaWK0oSyG6Gjq+m7nCFYDR7
# 0jius8Pw+8gA6/vsSqYkSYvx7OSOP6mHa87JTIgMX2HpUCXzZxltCDONrXGX4CBS
# 8H8AycJ/UkTi00y/hyD6Mo/Skuylinf1NW+nliWbHVBBjS+ZP7KqV+07jmkRo2e3
# qMQViQulszWMnTxDyhuKDsq+dqh8Q785BdNT8Joi1MWRDEV1q+cSNbU1dydyJavI
# XyY=
# SIG # End signature block
