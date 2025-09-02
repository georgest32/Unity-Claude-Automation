# Test-RefactoredModule.ps1
# Test the refactored semantic analysis module structure

Write-Host "Testing refactored semantic analysis module structure..." -ForegroundColor Cyan

# Show file sizes
Write-Host "`nFile sizes after refactoring:" -ForegroundColor Yellow
Get-ChildItem 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis*.psm1' | 
    Select-Object Name, @{Name='SizeKB';Expression={[math]::Round($_.Length/1KB,1)}}, LastWriteTime |
    Format-Table -AutoSize

# Test module import
Write-Host "`nTesting module import..." -ForegroundColor Yellow
try {
    # Clean any existing modules first
    Get-Module Unity-Claude* | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Import CPG dependencies
    Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force -Global -ErrorAction Stop
    Write-Host "  CPG module imported successfully" -ForegroundColor Green
    
    # Import the main semantic analysis module (which should import sub-modules)
    Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1' -Force -ErrorAction Stop
    Write-Host "  Semantic Analysis module imported successfully" -ForegroundColor Green
    
    # Test function availability
    Write-Host "`nTesting function availability:" -ForegroundColor Yellow
    $expectedFunctions = @(
        'Find-DesignPatterns',
        'Get-CodePurpose',
        'Get-CohesionMetrics',
        'Extract-BusinessLogic',
        'Recover-Architecture',
        'Test-DocumentationCompleteness',
        'Test-NamingConventions',
        'Get-TechnicalDebt',
        'New-QualityReport'
    )
    
    foreach ($funcName in $expectedFunctions) {
        $func = Get-Command $funcName -ErrorAction SilentlyContinue
        if ($func) {
            Write-Host "  $funcName : Available" -ForegroundColor Green
        } else {
            Write-Host "  $funcName : Missing" -ForegroundColor Red
        }
    }
    
    # Test basic functionality with a simple graph
    Write-Host "`nTesting basic functionality..." -ForegroundColor Yellow
    $testCode = {
        class TestSingleton {
            static [TestSingleton] $Instance
            hidden TestSingleton() {}
            static [TestSingleton] GetInstance() {
                if ([TestSingleton]::Instance -eq $null) {
                    [TestSingleton]::Instance = [TestSingleton]::new()
                }
                return [TestSingleton]::Instance
            }
        }
    }
    
    $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock $testCode
    Write-Host "  Graph created with $($graph.Nodes.Count) nodes" -ForegroundColor Green
    
    # Test pattern detection
    $patterns = Find-DesignPatterns -Graph $graph
    Write-Host "  Pattern detection: Found $(@($patterns).Count) patterns" -ForegroundColor Green
    
    # Test purpose classification
    $purposes = Get-CodePurpose -Graph $graph  
    Write-Host "  Purpose classification: Found $(@($purposes).Count) purposes" -ForegroundColor Green
    
    # Test cohesion metrics
    $cohesion = Get-CohesionMetrics -Graph $graph
    Write-Host "  Cohesion metrics: Analyzed $(@($cohesion).Count) modules" -ForegroundColor Green
    
    Write-Host "`nRefactored module structure test: PASSED" -ForegroundColor Green
    
} catch {
    Write-Host "`nRefactored module structure test: FAILED" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBu2DfgwbSrSBDy
# lULdge+fOpZbWpzuq7TFRno7cnZ8UqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOaVVSOf+ot+p5nTQVlRWWMh
# wPh4nUVeVIIHjKRRlHejMA0GCSqGSIb3DQEBAQUABIIBAEBg3+fv1sGx0ccDHKRr
# eYhABzqRpSv/uXBLoAMZ7ujhjhpm4PVuqHR/vxRJJ9wkkctMpJeQj4zh3kPh9djN
# Tzv3nK5OzPJX+3MEKjZLt9ajHm0Cxq4poPeOBaXq/IHTYGimRshc3ih0i4AEclc5
# BQ0gCZA9RPifszsBU3wF4ajLja+Ae+29lEnTkDL6u89MNIH1LqH+U0En+fVfuKbu
# AmQhfj5Md4MtrEoy2RE2oabTQYkxIuEhG29BUQPaxjft3Nd4bXsxwdbEskxMPEvo
# QZIZBf3hfZ9pc8MiemVAIPRoAuVl/nR0ItulqgNBCHAHisjOd56Ffdg9dLFgh5Lv
# tI4=
# SIG # End signature block
