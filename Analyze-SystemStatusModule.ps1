# Analyze-SystemStatusModule.ps1
# Comprehensive analysis of Unity-Claude-SystemStatus module using AST
# Date: 2025-08-20
# Purpose: Identify duplicates, orphaned code, and create function inventory

param(
    [string]$ModulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1",
    [string]$OutputPath = ".\SystemStatus_Analysis_Results.json"
)

Write-Host "=== Unity-Claude-SystemStatus Module Analysis ===" -ForegroundColor Cyan
Write-Host "Analyzing: $ModulePath" -ForegroundColor Gray

# Verify file exists
if (-not (Test-Path $ModulePath)) {
    Write-Error "Module file not found: $ModulePath"
    exit 1
}

# Get file info
$fileInfo = Get-Item $ModulePath
Write-Host "File Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
$lineCount = (Get-Content $ModulePath | Measure-Object -Line).Lines
Write-Host "Total Lines: $lineCount" -ForegroundColor Gray

# Parse the module using AST
Write-Host "`nParsing module with AST..." -ForegroundColor Yellow
$parseErrors = @()
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $ModulePath,
    [ref]$null,
    [ref]$parseErrors
)

if ($parseErrors.Count -gt 0) {
    Write-Warning "Parse errors found: $($parseErrors.Count)"
    $parseErrors | ForEach-Object { Write-Warning "  - Line $($_.Extent.StartLineNumber): $($_.Message)" }
}

# Find all functions
Write-Host "`nAnalyzing functions..." -ForegroundColor Yellow
$functions = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true)

Write-Host "Total function definitions found: $($functions.Count)" -ForegroundColor Green

# Group functions by name to find duplicates
$functionGroups = $functions | Group-Object -Property Name
$uniqueFunctions = $functionGroups | Where-Object { $_.Count -eq 1 }
$duplicateFunctions = $functionGroups | Where-Object { $_.Count -gt 1 }

Write-Host "Unique functions: $($uniqueFunctions.Count)" -ForegroundColor Green
Write-Host "Functions with duplicates: $($duplicateFunctions.Count)" -ForegroundColor Yellow

# Create detailed function inventory
$functionInventory = @()
foreach ($func in $functions) {
    $functionInventory += @{
        Name = $func.Name
        StartLine = $func.Extent.StartLineNumber
        EndLine = $func.Extent.EndLineNumber
        LineCount = $func.Extent.EndLineNumber - $func.Extent.StartLineNumber + 1
        Parameters = $func.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
        IsExported = $false  # Will be updated later
    }
}

# Find Export-ModuleMember statements
Write-Host "`nAnalyzing exports..." -ForegroundColor Yellow
$exportStatements = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.CommandAst] -and
    $args[0].CommandElements[0].Value -eq 'Export-ModuleMember'
}, $true)

$exportedFunctions = @()
foreach ($export in $exportStatements) {
    foreach ($element in $export.CommandElements) {
        if ($element -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
            $exportedFunctions += $element.Value
        }
    }
}

# Mark exported functions
foreach ($func in $functionInventory) {
    if ($exportedFunctions -contains $func.Name) {
        $func.IsExported = $true
    }
}

Write-Host "Exported functions: $($exportedFunctions.Count)" -ForegroundColor Green

# Analyze regions
Write-Host "`nAnalyzing regions..." -ForegroundColor Yellow
$content = Get-Content $ModulePath
$regions = @()
$regionStack = @()

for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match '^#region\s*(.*)') {
        $regionStack += @{
            Name = $Matches[1]
            StartLine = $i + 1
        }
    }
    elseif ($content[$i] -match '^#endregion') {
        if ($regionStack.Count -gt 0) {
            $region = $regionStack[-1]
            $region.EndLine = $i + 1
            $regions += $region
            $regionStack = $regionStack[0..($regionStack.Count - 2)]
        }
        else {
            Write-Warning "Orphaned #endregion at line $($i + 1)"
        }
    }
}

if ($regionStack.Count -gt 0) {
    Write-Warning "Unclosed regions: $($regionStack.Count)"
    $regionStack | ForEach-Object { Write-Warning "  - Region '$($_.Name)' at line $($_.StartLine)" }
}

Write-Host "Total regions: $($regions.Count)" -ForegroundColor Green

# Look for potential orphaned code patterns
Write-Host "`nSearching for orphaned code patterns..." -ForegroundColor Yellow
$orphanedCode = @()

# Check for incomplete blocks
for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    
    # Check for stray closing braces at start of line
    if ($line -match '^\s*\}\s*$' -and $i -gt 0) {
        $prevLine = $content[$i - 1]
        if ($prevLine -match '#endregion\.' -or $prevLine -match '\.Exception\.Message') {
            $orphanedCode += @{
                Line = $i + 1
                Type = "Stray closing brace after corrupted line"
                Content = $line
            }
        }
    }
    
    # Check for merge conflict markers
    if ($line -match '^<<<<<<<|^=======|^>>>>>>>') {
        $orphanedCode += @{
            Line = $i + 1
            Type = "Merge conflict marker"
            Content = $line
        }
    }
    
    # Check for truncated error handling
    if ($line -match 'Exception\.Message.*-Level.*ERROR' -and $line -notmatch '^s*Write-') {
        $orphanedCode += @{
            Line = $i + 1
            Type = "Truncated error handling"
            Content = $line
        }
    }
}

Write-Host "Potential orphaned code fragments: $($orphanedCode.Count)" -ForegroundColor $(if ($orphanedCode.Count -gt 0) { 'Yellow' } else { 'Green' })

# Identify duplicate content blocks
Write-Host "`nAnalyzing duplicate content blocks..." -ForegroundColor Yellow
$duplicateBlocks = @()

# Check for exact duplicate functions
foreach ($dupGroup in $duplicateFunctions) {
    $funcName = $dupGroup.Name
    $instances = $dupGroup.Group
    
    Write-Host "  Duplicate function '$funcName' found at lines:" -ForegroundColor Yellow
    $instances | ForEach-Object {
        Write-Host "    - Line $($_.Extent.StartLineNumber) to $($_.Extent.EndLineNumber)" -ForegroundColor Gray
    }
    
    $duplicateBlocks += @{
        Type = "Function"
        Name = $funcName
        Count = $instances.Count
        Locations = $instances | ForEach-Object {
            @{
                StartLine = $_.Extent.StartLineNumber
                EndLine = $_.Extent.EndLineNumber
            }
        }
    }
}

# Calculate statistics
$totalLines = $lineCount
$uniqueContentLines = 0
$duplicateLines = 0

foreach ($block in $duplicateBlocks) {
    if ($block.Type -eq "Function" -and $block.Count -gt 1) {
        # Count lines in duplicate functions (keep first, count rest as duplicates)
        for ($i = 1; $i -lt $block.Locations.Count; $i++) {
            $loc = $block.Locations[$i]
            $duplicateLines += ($loc.EndLine - $loc.StartLine + 1)
        }
    }
}

$uniqueContentLines = $totalLines - $duplicateLines

# Create analysis results
$analysisResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    FilePath = $ModulePath
    FileSize = $fileInfo.Length
    TotalLines = $totalLines
    UniqueContentLines = $uniqueContentLines
    DuplicateLines = $duplicateLines
    DuplicationPercentage = [Math]::Round(($duplicateLines / $totalLines) * 100, 2)
    Functions = @{
        Total = $functions.Count
        Unique = $uniqueFunctions.Count
        Duplicated = $duplicateFunctions.Count
        Exported = $exportedFunctions.Count
        Inventory = $functionInventory | Sort-Object StartLine
    }
    Regions = @{
        Total = $regions.Count
        List = $regions
    }
    DuplicateBlocks = $duplicateBlocks
    OrphanedCode = $orphanedCode
    ParseErrors = $parseErrors | ForEach-Object {
        @{
            Line = $_.Extent.StartLineNumber
            Message = $_.Message
        }
    }
}

# Save results to JSON
Write-Host "`nSaving analysis results to: $OutputPath" -ForegroundColor Cyan
$analysisResults | ConvertTo-Json -Depth 10 | Set-Content $OutputPath

# Display summary
Write-Host "`n=== Analysis Summary ===" -ForegroundColor Green
Write-Host "Total Lines: $totalLines"
Write-Host "Unique Content: ~$uniqueContentLines lines"
Write-Host "Duplicate Content: ~$duplicateLines lines ($([Math]::Round(($duplicateLines / $totalLines) * 100, 2))%)"
Write-Host "Functions: $($functions.Count) total, $($uniqueFunctions.Count) unique, $($duplicateFunctions.Count) duplicated"
Write-Host "Exported Functions: $($exportedFunctions.Count)"
Write-Host "Regions: $($regions.Count)"
Write-Host "Orphaned Code Fragments: $($orphanedCode.Count)"
Write-Host "Parse Errors: $($parseErrors.Count)"

if ($duplicateFunctions.Count -gt 0) {
    Write-Host "`nRecommendation: Remove duplicate functions to reduce module by ~$duplicateLines lines" -ForegroundColor Yellow
}

if ($orphanedCode.Count -gt 0) {
    Write-Host "Warning: Orphaned code detected that should be reviewed and removed" -ForegroundColor Yellow
}

Write-Host "`nAnalysis complete! Results saved to: $OutputPath" -ForegroundColor Green

# Return results object for further processing
return $analysisResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUttyH7W78fE5kAG2xLPQCUzMt
# 5RagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUkAcrczjIjjVrnFaBsByN7mMf2BkwDQYJKoZIhvcNAQEBBQAEggEAhm0Y
# eUH9dnhhzgDIP7g5IoikUVTwkkKMwn/ZX6T7dqpTVuT36rhcgp1De97rGMb/P52I
# aCzs684NeetHySZYzM8etrouAp1uKTWBsNmXygOsl9xhP54H4jJHXRnrpOrhTFP1
# ICuLSp1RnY5rn1ApLQQCanBTZNFdLRTMj+2F/oG/VUOZHk+d4rK60TYf3n1qcPVr
# xWbwZI9mCo+Ffj891XNsNzS3/xNtbXJQ2yESE+7Ht7sfzuTvxIhRNoE8AAdN6QtI
# dJUL9GvW9+8A7+AWQf8hRz6paAOi3Aj3wteh1mj0h3iv6RpyEpBDkuCy+1uBGFmJ
# bqiR4Ko7H4eHJxfN1A==
# SIG # End signature block
