# Import-UsefulPatterns.ps1
# Selectively imports only the 12 useful debug patterns from symbolic_main.db
# Date: 2025-08-17

param(
    [string]$DatabasePath = "C:\UnityProjects\Sound-and-Shoal\symbolic_main.db",
    [switch]$DryRun
)

Write-Host "`n=== SELECTIVE PATTERN IMPORT ===" -ForegroundColor Cyan
Write-Host "Importing useful patterns from symbolic_main.db" -ForegroundColor Yellow

# Add module path
$modulePath = Join-Path $PSScriptRoot 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

# Import the learning module
Write-Host "`nLoading Unity-Claude-Learning-Simple module..." -ForegroundColor Gray
Import-Module Unity-Claude-Learning-Simple -Force

# Initialize storage
Write-Host "Initializing pattern storage..." -ForegroundColor Gray
Initialize-LearningStorage | Out-Null

# Define the 12 useful patterns to import
$usefulPatterns = @(
    "NullReferenceException in PlayerController.Update",
    "Audio source component missing warning",
    "Unity Analyzer UNT0001",
    "Unity Analyzer UNT0003",
    "Unity Analyzer UNT0004",
    "Unity Analyzer UNT0005",
    "Unity Analyzer UNT0010",
    "Unity Analyzer UNT0011",
    "Unity Analyzer UNT0017",
    "Unity Analyzer UNT0018",
    "Unity Analyzer UNT0022",
    "Unity Analyzer UNT0028"
)

Write-Host "`nPatterns to import: $($usefulPatterns.Count)" -ForegroundColor Green

# Check if database exists
if (-not (Test-Path $DatabasePath)) {
    Write-Host "ERROR: Database not found at $DatabasePath" -ForegroundColor Red
    exit 1
}

# Check if sqlite3 is available
$sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite3) {
    Write-Host "ERROR: sqlite3 command not found. Please ensure SQLite is installed." -ForegroundColor Red
    exit 1
}

$importedCount = 0
$skippedCount = 0

foreach ($patternIssue in $usefulPatterns) {
    Write-Host "`nProcessing: $patternIssue" -ForegroundColor Yellow
    
    # Escape single quotes for SQL query
    $escapedIssue = $patternIssue -replace "'", "''"
    
    # Query the database for this pattern
    $query = "SELECT DISTINCT Issue, Cause, Fix FROM DebugPatterns WHERE Issue = '$escapedIssue' AND Fix IS NOT NULL AND Fix <> '' LIMIT 1;"
    
    try {
        $result = & sqlite3 $DatabasePath $query
        
        if ($result) {
            # Parse the result (format: Issue|Cause|Fix)
            $parts = $result -split '\|'
            if ($parts.Count -ge 3) {
                $issue = $parts[0]
                $cause = $parts[1]
                $fix = $parts[2]
                
                Write-Host "  Issue: $issue" -ForegroundColor Gray
                Write-Host "  Cause: $cause" -ForegroundColor Gray
                Write-Host "  Fix: $fix" -ForegroundColor Gray
                
                if (-not $DryRun) {
                    # Determine error type based on pattern
                    $errorType = switch -Wildcard ($issue) {
                        "Unity Analyzer*" { "UnityAnalyzer" }
                        "*Exception*" { "Exception" }
                        "CS*" { "CompilationError" }
                        "*warning*" { "Warning" }
                        default { "GeneralError" }
                    }
                    
                    # Add the pattern to our learning system
                    $patternId = Add-ErrorPattern -ErrorMessage $issue -ErrorType $errorType -Fix $fix -Context $cause
                    
                    if ($patternId) {
                        Write-Host "  ✅ Imported successfully (ID: $patternId)" -ForegroundColor Green
                        $importedCount++
                    } else {
                        Write-Host "  ⚠️ Pattern may already exist or import failed" -ForegroundColor Yellow
                        $skippedCount++
                    }
                } else {
                    Write-Host "  [DRY RUN] Would import this pattern" -ForegroundColor Cyan
                }
            } else {
                Write-Host "  ⚠️ Invalid result format" -ForegroundColor Yellow
                $skippedCount++
            }
        } else {
            Write-Host "  ⚠️ No data found for this pattern" -ForegroundColor Yellow
            $skippedCount++
        }
    } catch {
        Write-Host "  ❌ Error querying database: $_" -ForegroundColor Red
        $skippedCount++
    }
}

# Summary
Write-Host "`n=== IMPORT SUMMARY ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN - No patterns were actually imported" -ForegroundColor Yellow
    Write-Host "Patterns that would be imported: $($usefulPatterns.Count)" -ForegroundColor Gray
} else {
    Write-Host "Successfully imported: $importedCount patterns" -ForegroundColor Green
    if ($skippedCount -gt 0) {
        Write-Host "Skipped/Failed: $skippedCount patterns" -ForegroundColor Yellow
    }
    
    # Show current pattern count
    $config = Get-LearningConfig
    if (Test-Path $config.PatternsFile) {
        $jsonContent = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
        $totalPatterns = ($jsonContent | Get-Member -MemberType NoteProperty).Count
        Write-Host "Total patterns in database: $totalPatterns" -ForegroundColor Gray
    }
}

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "1. Test pattern matching with these new patterns" -ForegroundColor Gray
Write-Host "2. Consider adding more Unity-specific error patterns manually" -ForegroundColor Gray
Write-Host "3. Build patterns from actual project errors for better relevance" -ForegroundColor Gray
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJ1I5emjJVPIWyrfGskOozcGh
# BX+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6XtBNIPvL9Q1KpkhnfmvyYaHbBowDQYJKoZIhvcNAQEBBQAEggEAGeuT
# jjpGB1GXRiRxeTgi6fSTYTnHdPl8khcknfym+ze12mke/3+UT7swWj9xPT0QjuuR
# Kj0hCkhJeLOdCTFwOG0eZWYmka+gVv3ncWhN61P31JppdEA3MpakiW9VJIZDEtiq
# tCSCVG7KcwpGvIga6Rt7G6Gk7ExyAGSYUAbtl7B0JX9pXAmO2Znj0YiXdfqQCZDr
# ygYUsioELwNn9nOd6lT5gKAQz09ywvCwfpemAO8cvdo9zEJsyhNvQJetVSIU+7w0
# rHSy8vxVr3LYMuaU6IP0TbRHaix39626rD3m9bYsTW0NrpPkaUd/96RhsjI4E1D+
# bcW6Igb4IzmpDjhtwg==
# SIG # End signature block
