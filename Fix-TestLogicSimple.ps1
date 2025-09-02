# Fix-TestLogicSimple.ps1 
# Simple fix for the remaining semantic analysis test failures

$ErrorActionPreference = "Stop"

Write-Host "=== Simple Fix for Semantic Analysis Test Issues ===" -ForegroundColor Cyan

# The main issue is that tests expect single objects but functions return arrays
# Let's fix the test file to handle this properly

$testFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-SemanticAnalysis.ps1"
$content = Get-Content $testFile -Raw

Write-Host "1. Fixing Code Purpose Classification test..." -ForegroundColor Yellow

# Fix line 284-286: Handle array return from Get-CodePurpose
$oldSection = @'
            $purpose = Get-CodePurpose -Graph $graph
            $correctClassification = $purpose.PrimaryPurpose -eq $test.Purpose
            Write-TestResult "Purpose Classification: $($test.Purpose)" $correctClassification "Detected: $($purpose.PrimaryPurpose), Confidence: $($purpose.Confidence)"
'@

$newSection = @'
            $purposeResults = Get-CodePurpose -Graph $graph
            $purposeArray = @($purposeResults)
            if ($purposeArray.Count -gt 0) {
                $purpose = $purposeArray[0]
                $detectedPurpose = if ($purpose.PSObject.Properties['Purpose']) { $purpose.Purpose } else { $purpose.PrimaryPurpose }
                $correctClassification = $detectedPurpose -eq $test.Purpose
                Write-TestResult "Purpose Classification: $($test.Purpose)" $correctClassification "Detected: $detectedPurpose, Confidence: $($purpose.Confidence)"
            } else {
                Write-TestResult "Purpose Classification: $($test.Purpose)" $false "No purpose detected"
            }
'@

$content = $content.Replace($oldSection.Trim(), $newSection.Trim())

Write-Host "2. Fixing Cohesion Metrics test..." -ForegroundColor Yellow

# Fix cohesion metrics test 
$oldCohesion = @'
        $cohesionMetrics = Get-CohesionMetrics -Graph $graph
        
        Write-TestResult "Cohesion Metrics Calculation" ($null -ne $cohesionMetrics) "CHM: $($cohesionMetrics.CHM), CHD: $($cohesionMetrics.CHD)"
        
        # Validate metric ranges
        $validCHM = $cohesionMetrics.CHM -ge 0 -and $cohesionMetrics.CHM -le 1
        $validCHD = $cohesionMetrics.CHD -ge 0 -and $cohesionMetrics.CHD -le 1
'@

$newCohesion = @'
        $cohesionResults = Get-CohesionMetrics -Graph $graph
        $cohesionArray = @($cohesionResults)
        
        if ($cohesionArray.Count -gt 0) {
            $cohesionMetrics = $cohesionArray[0]
            Write-TestResult "Cohesion Metrics Calculation" ($null -ne $cohesionMetrics) "CHM: $($cohesionMetrics.CHM), CHD: $($cohesionMetrics.CHD)"
            
            # Validate metric ranges
            $validCHM = $cohesionMetrics.CHM -ge 0 -and $cohesionMetrics.CHM -le 1
            $validCHD = $cohesionMetrics.CHD -ge 0 -and $cohesionMetrics.CHD -le 1
        } else {
            Write-TestResult "Cohesion Metrics Calculation" $false "No cohesion metrics calculated"
            $validCHM = $false
            $validCHD = $false
        }
'@

$content = $content.Replace($oldCohesion.Trim(), $newCohesion.Trim())

Write-Host "3. Fixing Business Logic test..." -ForegroundColor Yellow

# Fix business logic test  
$oldBusiness = @'
        $businessLogic = Extract-BusinessLogic -Graph $graph
        
        Write-TestResult "Business Logic Extraction" ($null -ne $businessLogic) "Found $($businessLogic.Count) business rules"
        
        # Check for discount rule detection
        $discountRule = $businessLogic | Where-Object { $_.RuleType -eq "CalculationRule" }
        Write-TestResult "Discount Rule Detection" ($null -ne $discountRule) "Rule detected with confidence: $($discountRule.Confidence)"
'@

$newBusiness = @'
        $businessLogic = Extract-BusinessLogic -Graph $graph
        $businessArray = @($businessLogic)
        
        Write-TestResult "Business Logic Extraction" ($businessArray.Count -gt 0) "Found $($businessArray.Count) business rules"
        
        # Check for discount rule detection
        $discountRule = $businessArray | Where-Object { $_.RuleType -eq "CalculationRule" } | Select-Object -First 1
        Write-TestResult "Discount Rule Detection" ($null -ne $discountRule) "Rule detected with confidence: $(if ($discountRule) { $discountRule.Confidence } else { 'N/A' })"
'@

$content = $content.Replace($oldBusiness.Trim(), $newBusiness.Trim())

Write-Host "4. Fixing Quality Analysis test..." -ForegroundColor Yellow

# Fix quality analysis tests - they have multiple issues
$oldQuality = @'
        $docCompleteness = Test-DocumentationCompleteness -Graph $graph
        Write-TestResult "Documentation Completeness Analysis" ($null -ne $docCompleteness) "Coverage: $($docCompleteness.CoveragePercentage)%"
        
        # Test naming conventions
        $namingResults = Test-NamingConventions -Graph $graph
        Write-TestResult "Naming Convention Validation" ($null -ne $namingResults) "Compliance: $($namingResults.CompliancePercentage)%"
        
        # Test technical debt analysis
        $debtAnalysis = Get-TechnicalDebt -Graph $graph
        Write-TestResult "Technical Debt Analysis" ($null -ne $debtAnalysis) "Debt Score: $($debtAnalysis.TotalDebtScore)"
'@

$newQuality = @'
        $docCompleteness = Test-DocumentationCompleteness -Graph $graph
        $docArray = @($docCompleteness)
        if ($docArray.Count -gt 0) {
            $doc = $docArray[0]
            $coverage = if ($doc.PSObject.Properties['CoveragePercentage']) { $doc.CoveragePercentage } else { 0 }
            Write-TestResult "Documentation Completeness Analysis" ($null -ne $doc) "Coverage: $coverage%"
        } else {
            Write-TestResult "Documentation Completeness Analysis" $false "No documentation analysis"
        }
        
        # Test naming conventions
        $namingResults = Test-NamingConventions -Graph $graph
        $namingArray = @($namingResults)
        if ($namingArray.Count -gt 0) {
            $naming = $namingArray[0]
            $compliance = if ($naming.PSObject.Properties['CompliancePercentage']) { $naming.CompliancePercentage } else { 0 }
            Write-TestResult "Naming Convention Validation" ($null -ne $naming) "Compliance: $compliance%"
        } else {
            Write-TestResult "Naming Convention Validation" $false "No naming analysis"
        }
        
        # Test technical debt analysis
        $debtAnalysis = Get-TechnicalDebt -Graph $graph
        $debtArray = @($debtAnalysis)
        if ($debtArray.Count -gt 0) {
            $debt = $debtArray[0]
            $score = if ($debt.PSObject.Properties['TotalDebtScore']) { $debt.TotalDebtScore } else { 0 }
            Write-TestResult "Technical Debt Analysis" ($null -ne $debt) "Debt Score: $score"
        } else {
            Write-TestResult "Technical Debt Analysis" $false "No debt analysis"
        }
'@

$content = $content.Replace($oldQuality.Trim(), $newQuality.Trim())

# Save the fixed file
$content | Set-Content $testFile -Encoding UTF8
Write-Host "   Test file updated with array handling fixes" -ForegroundColor Green

Write-Host "`n=== Fix Complete ===" -ForegroundColor Cyan
Write-Host "Updated test logic to properly handle array returns from semantic analysis functions" -ForegroundColor Green
Write-Host "Re-run Test-SemanticAnalysis.ps1 to verify the fixes" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAHoalI8KKt+PEW
# snLR1LVccU81kIFGZ2sm98RyshXnL6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL90NeWvGV/Hb8GylJkntnrz
# RXmt5n4J8pOcnzGBQ+PXMA0GCSqGSIb3DQEBAQUABIIBAF1gYYv5XSvB4DaeruK1
# wshkaG9HukT3JCIXdKNHwm97l/SVG9ELlFUIJrVlhRacYTl+SqWO0EtuVnCZqpZp
# 7mWHe+h9Gh5bQNKuTzEEheJqlmn+k5X0uyhbRdx55eA4lA1g2mBG9Eg0H4k0o0mb
# 38iULLDBvzokAuMDUqUHD7Q8qTwu9aOwGLRT5Rjii5mi8EHFsY6ZA+pXF/DU9pCA
# 7C46M/KVNVth6O94JuSiDJWEVIsv1EOq2i1JdD3v4Z41ua7Ko2Aai0hGkz59YfQn
# WYtBQehEMRHGaUzPdMTO44NvQ2Q0+K95c8IO6qoK4e+XbDZHdWpa8YYShSmTff3R
# oOw=
# SIG # End signature block
