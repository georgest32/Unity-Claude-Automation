# Four-step validation for CPG fixes
Write-Host "=== Four-Step CPG Fix Validation ===" -ForegroundColor Cyan

try {
    # Clean slate
    Write-Host "Purging loaded modules from session..." -ForegroundColor Yellow
    'Unity-Claude-CPG','Unity-Claude-CPG-ASTConverter','Unity-Claude-SemanticAnalysis','Unity-Claude-ObsolescenceDetection' |
        ForEach-Object {
            Get-Module $_ -All | Remove-Module -Force -ErrorAction SilentlyContinue
        }
    
    # Optional: clear script scope copies if you dot-source elsewhere in tests
    $ExecutionContext.SessionState.PSVariable.Remove('Cmd_ConvertASTtoCPG') 2>$null
    $ExecutionContext.SessionState.PSVariable.Remove('AstConverterModule') 2>$null
    
    Write-Host "Importing from exact path to avoid PSModulePath ambiguity..." -ForegroundColor Yellow
    $moduleManifest = Join-Path $PSScriptRoot 'Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1'
    Import-Module $moduleManifest -Force -Verbose:$false
    
    Write-Host "Module path confirmation:" -ForegroundColor Cyan
    (Get-Module Unity-Claude-CPG).Path | Write-Host -ForegroundColor Yellow
    
    Write-Host "`n=== STEP 1: Function Visibility ===" -ForegroundColor Magenta
    $cmd = Get-Command ConvertTo-CPGFromScriptBlock -Module Unity-Claude-CPG -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "✅ ConvertTo-CPGFromScriptBlock found!" -ForegroundColor Green
        $cmd | Format-List Source, Name, Module
    } else {
        Write-Host "❌ ConvertTo-CPGFromScriptBlock NOT FOUND in module" -ForegroundColor Red
        Write-Host "Available functions:" -ForegroundColor Yellow
        Get-Command -Module Unity-Claude-CPG | Select-Object Name | Format-Table
        throw "Function export failed"
    }
    
    Write-Host "`n=== STEP 2: Smoke Graph Test ===" -ForegroundColor Magenta
    $g = ConvertTo-CPGFromScriptBlock -ScriptBlock { function F { 1+1 }; F } -Verbose
    if (-not $g) {
        throw "Graph generation returned null"
    }
    Write-Host "✅ Graph created successfully!" -ForegroundColor Green
    Write-Host "   Graph name: $($g.Name)" -ForegroundColor Cyan
    Write-Host "   Nodes: $($g.Nodes.Count)" -ForegroundColor Cyan
    Write-Host "   Edges: $($g.Edges.Count)" -ForegroundColor Cyan
    
    # Check root file node name
    $fileNode = $g.Nodes.Values | Where-Object { $_.Type -eq [CPGNodeType]::File }
    if ($fileNode -and $fileNode.Name -like "InMemory:*") {
        Write-Host "✅ Root file node has expected InMemory: pseudo path" -ForegroundColor Green
    } else {
        Write-Host "❌ Root file node name unexpected: $($fileNode.Name)" -ForegroundColor Red
    }
    
    Write-Host "`n=== STEP 3: Pattern Function Test ===" -ForegroundColor Magenta
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1" -Force
    $patterns = Find-DesignPatterns -Graph $g -Verbose:$false
    if ($patterns -ne $null) {
        Write-Host "✅ Pattern detection successful!" -ForegroundColor Green
        Write-Host "   Found $($patterns.Count) patterns" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Pattern detection returned null" -ForegroundColor Red
        throw "Pattern detection failed"
    }
    
    Write-Host "`n=== STEP 4: Full Test Suite ===" -ForegroundColor Magenta
    Write-Host "Running Test-SemanticAnalysis.ps1 with verbose output..." -ForegroundColor Cyan
    & "$PSScriptRoot\Test-SemanticAnalysis.ps1" -TestType Patterns -Verbose
    
    Write-Host "`n🎉 All validation steps completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAs1q/jBmmbr9TJ
# 69CalXfpjWfeS4Q+y7O/0XG+145tS6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICO+Ake0f+XtbGfsGnOXt7dO
# Ui0kHWkdG4IZS9xDRXLhMA0GCSqGSIb3DQEBAQUABIIBADVcor22YedwPU1PfsN6
# c8tmLyPfgoQPkHikG4bBD46fZnT8XEdNS/HCeqWwX/hkXZ46NXRmw6kUFU9w3Q5S
# 65rEK6+fPFmvUUyJTd+wmbuYYJxgnWYfzUP4Y8Ws0attx7uHVx5Gc6ZAOjeg3nap
# WGmRsvaM8jrJYu7EF7o18+DnNoP+ouTqxKzzZRrxGstmP3k5HsYUThtNoK5wfCSR
# RiYC3d6RrhpWE5JXkgyKGzL9prB+1DbdsHmBMTVF219SaD6VCKlYaIGYMvUN2iUN
# /O3wCWzvSxyUhiWwtos1VWh0103PFjBnDSO9aDIV6mqbu76D6rW349e3vIUEKn5K
# MKc=
# SIG # End signature block
