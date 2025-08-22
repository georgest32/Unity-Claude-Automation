# Initialize Test Metrics for Learning Analytics Testing
# Generates sample metrics data for realistic testing of analytics functions
# PowerShell 5.1 compatible

param(
    [int]$DaysOfData = 30,
    [double]$BaseSuccessRate = 0.75,
    [double]$SuccessVariance = 0.15,
    [double]$BaseConfidence = 0.80,
    [double]$ConfidenceVariance = 0.10,
    [int]$MetricsPerDay = 5
)

# Import required module
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking

Write-Host "=== Initializing Test Metrics Data ===" -ForegroundColor Yellow
Write-Host "Generating $DaysOfData days of metrics with $MetricsPerDay metrics per day" -ForegroundColor Cyan

function Generate-RandomBoolean {
    <#
    .SYNOPSIS
    Generates a random boolean with specified probability
    
    .PARAMETER Probability
    Probability of returning true (0-100)
    #>
    param(
        [double]$Probability = 50
    )
    
    return (Get-Random -Maximum 100) -lt $Probability
}

function Generate-MetricData {
    <#
    .SYNOPSIS
    Generates realistic metric data with controlled randomness
    #>
    param(
        [string]$PatternID,
        [DateTime]$Timestamp,
        [double]$BaseSuccessRate,
        [double]$BaseConfidence,
        [double]$DayProgress  # 0.0 to 1.0 representing progress through the time period
    )
    
    # Add slight improvement trend over time (learning effect)
    $learningBonus = $DayProgress * 0.1  # Up to 10% improvement over time
    
    # Calculate success probability with variance and learning
    $successProbability = [Math]::Min(100, ($BaseSuccessRate + $learningBonus + (Get-Random -Minimum -$SuccessVariance -Maximum $SuccessVariance)) * 100)
    $success = Generate-RandomBoolean -Probability $successProbability
    
    # Confidence tends to be higher for successful applications
    $confidenceAdjustment = if ($success) { 0.05 } else { -0.05 }
    $confidence = [Math]::Max(0.1, [Math]::Min(0.99, 
        $BaseConfidence + $confidenceAdjustment + (Get-Random -Minimum -$ConfidenceVariance -Maximum $ConfidenceVariance)
    ))
    
    # Execution time varies but tends to be faster for successful operations
    $baseTime = if ($success) { 500 } else { 800 }
    $executionTime = $baseTime + (Get-Random -Minimum -200 -Maximum 400)
    
    return @{
        PatternID = $PatternID
        Success = $success
        ConfidenceScore = [Math]::Round($confidence, 4)
        ExecutionTimeMs = [Math]::Max(100, $executionTime)
        Timestamp = $Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

try {
    # Get existing patterns or create test patterns if none exist
    $patternsRaw = Get-PatternsFromJSON
    
    # Handle different return types from Get-PatternsFromJSON
    $patterns = $null
    if ($patternsRaw -is [hashtable]) {
        $patterns = $patternsRaw
    } elseif ($patternsRaw -is [array] -and $patternsRaw.Count -gt 0) {
        # Array of pattern objects - convert to hashtable
        $patterns = @{}
        foreach ($p in $patternsRaw) {
            if ($p.PatternID) {
                $patterns[$p.PatternID] = $p
            } elseif ($p.ID) {
                $patterns[$p.ID] = $p
            }
        }
    }
    
    if (-not $patterns -or $patterns.Count -eq 0) {
        Write-Host "No patterns found. Creating test patterns..." -ForegroundColor Yellow
        
        # Create sample patterns for testing
        $testPatterns = @(
            @{
                ID = "CS0246_UNITY"
                ErrorSignature = "CS0246: The type or namespace name 'UnityEngine' could not be found"
                Fix = "Add using UnityEngine; at the top of the file"
                Category = "Missing Using Directive"
                BaseSuccess = 0.90
                BaseConfidence = 0.85
            },
            @{
                ID = "CS0103_VAR"
                ErrorSignature = "CS0103: The name 'variable' does not exist in the current context"
                Fix = "Declare the variable before using it"
                Category = "Undeclared Variable"
                BaseSuccess = 0.75
                BaseConfidence = 0.80
            },
            @{
                ID = "CS1061_METHOD"
                ErrorSignature = "CS1061: Type does not contain a definition for method"
                Fix = "Check method name spelling or add the missing method"
                Category = "Missing Method"
                BaseSuccess = 0.70
                BaseConfidence = 0.75
            },
            @{
                ID = "CS0029_CONVERT"
                ErrorSignature = "CS0029: Cannot implicitly convert type"
                Fix = "Add explicit cast or change variable type"
                Category = "Type Conversion"
                BaseSuccess = 0.65
                BaseConfidence = 0.70
            },
            @{
                ID = "NULL_REF"
                ErrorSignature = "NullReferenceException: Object reference not set to an instance"
                Fix = "Add null check before accessing object"
                Category = "Null Reference"
                BaseSuccess = 0.80
                BaseConfidence = 0.82
            }
        )
        
        foreach ($pattern in $testPatterns) {
            Add-PatternToJSON -PatternID $pattern.ID -Pattern @{
                ErrorSignature = $pattern.ErrorSignature
                ErrorMessage = $pattern.ErrorSignature
                Fix = $pattern.Fix
                Category = $pattern.Category
                Confidence = $pattern.BaseConfidence
            }
            Write-Host "  Added pattern: $($pattern.ID)" -ForegroundColor Green
        }
        
        # Use test patterns for metric generation
        $patternData = $testPatterns
    } else {
        Write-Host "Found $($patterns.Count) existing patterns" -ForegroundColor Green
        
        # If we don't have enough patterns, create some test patterns anyway
        if ($patterns.Count -lt 5) {
            Write-Host "Not enough patterns found. Creating additional test patterns..." -ForegroundColor Yellow
            
            # Create sample patterns for testing
            $testPatterns = @(
                @{
                    ID = "CS0246_UNITY"
                    ErrorSignature = "CS0246: The type or namespace name 'UnityEngine' could not be found"
                    Fix = "Add using UnityEngine; at the top of the file"
                    Category = "Missing Using Directive"
                    BaseSuccess = 0.90
                    BaseConfidence = 0.85
                },
                @{
                    ID = "CS0103_VAR"
                    ErrorSignature = "CS0103: The name 'variable' does not exist in the current context"
                    Fix = "Declare the variable before using it"
                    Category = "Undeclared Variable"
                    BaseSuccess = 0.75
                    BaseConfidence = 0.80
                },
                @{
                    ID = "CS1061_METHOD"
                    ErrorSignature = "CS1061: Type does not contain a definition for method"
                    Fix = "Check method name spelling or add the missing method"
                    Category = "Missing Method"
                    BaseSuccess = 0.70
                    BaseConfidence = 0.75
                },
                @{
                    ID = "CS0029_CONVERT"
                    ErrorSignature = "CS0029: Cannot implicitly convert type"
                    Fix = "Add explicit cast or change variable type"
                    Category = "Type Conversion"
                    BaseSuccess = 0.65
                    BaseConfidence = 0.70
                },
                @{
                    ID = "NULL_REF"
                    ErrorSignature = "NullReferenceException: Object reference not set to an instance"
                    Fix = "Add null check before accessing object"
                    Category = "Null Reference"
                    BaseSuccess = 0.80
                    BaseConfidence = 0.82
                }
            )
            
            foreach ($pattern in $testPatterns) {
                # Check if pattern already exists
                if (-not $patterns.ContainsKey($pattern.ID)) {
                    Add-PatternToJSON -PatternID $pattern.ID -Pattern @{
                        ErrorSignature = $pattern.ErrorSignature
                        ErrorMessage = $pattern.ErrorSignature
                        Fix = $pattern.Fix
                        Category = $pattern.Category
                        Confidence = $pattern.BaseConfidence
                    }
                    Write-Host "  Added pattern: $($pattern.ID)" -ForegroundColor Green
                }
            }
            
            # Use test patterns for metric generation
            $patternData = $testPatterns
        } else {
            # Convert hashtable patterns to array format for processing
            $patternData = @()
            foreach ($key in $patterns.Keys) {
                # Skip empty keys
                if ([string]::IsNullOrWhiteSpace($key)) {
                    Write-Warning "Skipping pattern with empty ID"
                    continue
                }
                
                $patternData += @{
                    ID = $key
                    BaseSuccess = 0.70 + (Get-Random -Maximum 20) / 100.0
                    BaseConfidence = 0.75 + (Get-Random -Maximum 15) / 100.0
                }
            }
        }
    }
    
    # Generate metrics for each pattern
    $totalMetrics = 0
    $startDate = (Get-Date).AddDays(-$DaysOfData)
    
    Write-Host "`nGenerating metrics data..." -ForegroundColor Cyan
    
    foreach ($pattern in $patternData) {
        # Skip if pattern ID is empty
        if ([string]::IsNullOrWhiteSpace($pattern.ID)) {
            Write-Warning "  Skipping pattern with empty ID"
            continue
        }
        
        Write-Host "  Processing pattern: $($pattern.ID)" -ForegroundColor Gray
        
        for ($day = 0; $day -lt $DaysOfData; $day++) {
            $dayProgress = $day / $DaysOfData
            $currentDate = $startDate.AddDays($day)
            
            # Generate multiple metrics per day with time variation
            for ($metric = 0; $metric -lt $MetricsPerDay; $metric++) {
                # Add random hours and minutes to spread throughout the day
                $timestamp = $currentDate.AddHours((Get-Random -Maximum 24)).AddMinutes((Get-Random -Maximum 60))
                
                # Generate metric data
                $metricData = Generate-MetricData `
                    -PatternID $pattern.ID `
                    -Timestamp $timestamp `
                    -BaseSuccessRate $pattern.BaseSuccess `
                    -BaseConfidence $pattern.BaseConfidence `
                    -DayProgress $dayProgress
                
                # Record the metric (timestamp is generated automatically)
                Record-PatternApplicationMetric `
                    -PatternID $metricData.PatternID `
                    -Success $metricData.Success `
                    -ConfidenceScore $metricData.ConfidenceScore `
                    -ExecutionTimeMs $metricData.ExecutionTimeMs
                
                $totalMetrics++
            }
        }
    }
    
    Write-Host "`nMetrics generation complete!" -ForegroundColor Green
    Write-Host "  Total patterns: $($patternData.Count)" -ForegroundColor Gray
    Write-Host "  Total metrics generated: $totalMetrics" -ForegroundColor Gray
    Write-Host "  Date range: $($startDate.ToString('yyyy-MM-dd')) to $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
    
    # Display summary statistics
    Write-Host "`nVerifying generated data..." -ForegroundColor Cyan
    $analytics = Get-PatternUsageAnalytics -TopCount 10
    
    if ($analytics -and $analytics.TopPatternsByUsage) {
        Write-Host "  Top patterns by usage:" -ForegroundColor Gray
        $analytics.TopPatternsByUsage | Select-Object -First 3 | ForEach-Object {
            Write-Host "    $($_.PatternID): $($_.UsageCount) uses, $([Math]::Round($_.SuccessRate * 100, 1))% success" -ForegroundColor Cyan
        }
    }
    
    Write-Host "`nTest metrics initialized successfully!" -ForegroundColor Green
    Write-Host "You can now run Test-LearningAnalytics.ps1 for comprehensive testing" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to initialize test metrics: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbfdVv0bDK0XY7wG/7mjMyt3I
# IKCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsPLFdqvyUVxsia+K8Ju7kSjX1EcwDQYJKoZIhvcNAQEBBQAEggEAJGGo
# 2Lhw26IebfCSPC6lBlYzp6xtuqM6v8AEC01ALq2HumYVYeRWC+qHEmTrVa8FAuJ9
# m9HBGplxnZujBF4Yfu6E4cV2kNrZh1cL4gsfeG9xpaa9p9hEtHJFF/ZHGkyunGk6
# BoQxjFJR81NoYb/wMydNlKdtKIP5S0LW2ofx0K1y3PvNESpG6u52A6tpbl/bjI3H
# IWvHNUPIyKjR9XmwTX55vhqxQf+4T3Yw+sMHmJ54Gu5ya57Z+b8qdcOUloeG7Nr1
# atXKQdY4yOIKo0fD89IQCR8EVa7ndAZ6APGZW3D/30ETUAaQrb2cBzUoD4JQuunS
# A91EWbhs+TqgEoQ6xg==
# SIG # End signature block
