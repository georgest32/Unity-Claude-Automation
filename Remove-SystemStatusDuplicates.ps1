# Remove-SystemStatusDuplicates.ps1
# Removes duplicate functions from Unity-Claude-SystemStatus module using AST
# Date: 2025-08-20
# Purpose: Phase 2 of refactoring - deduplicate the module

param(
    [string]$SourcePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1",
    [string]$OutputPath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus-Deduplicated.psm1",
    [string]$LogPath = ".\SystemStatus_Deduplication_Log.txt"
)

Write-Host "=== Unity-Claude-SystemStatus Deduplication ===" -ForegroundColor Cyan
Write-Host "Source: $SourcePath" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray

$log = @()
$log += "Deduplication started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$log += "Source: $SourcePath"
$log += ""

# Verify source exists
if (-not (Test-Path $SourcePath)) {
    Write-Error "Source file not found: $SourcePath"
    exit 1
}

# Read the source file
Write-Host "`nReading source file..." -ForegroundColor Yellow
$content = Get-Content $SourcePath
$originalLineCount = $content.Count
Write-Host "Original file: $originalLineCount lines" -ForegroundColor Gray
$log += "Original file: $originalLineCount lines"

# Parse with AST to find functions
Write-Host "`nParsing module with AST..." -ForegroundColor Yellow
$parseErrors = @()
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $SourcePath,
    [ref]$null,
    [ref]$parseErrors
)

if ($parseErrors.Count -gt 0) {
    Write-Warning "Parse errors found: $($parseErrors.Count)"
    $log += "Parse errors: $($parseErrors.Count)"
}

# Find all functions
$functions = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true)

Write-Host "Found $($functions.Count) function definitions" -ForegroundColor Gray
$log += "Found $($functions.Count) function definitions"

# Group by name to identify duplicates
$functionGroups = $functions | Group-Object -Property Name
$duplicateFunctions = $functionGroups | Where-Object { $_.Count -gt 1 }

Write-Host "Functions with duplicates: $($duplicateFunctions.Count)" -ForegroundColor Yellow
$log += "Functions with duplicates: $($duplicateFunctions.Count)"

# Track which lines to remove
$linesToRemove = @{}
$removedFunctions = @()

foreach ($dupGroup in $duplicateFunctions) {
    $funcName = $dupGroup.Name
    $instances = $dupGroup.Group | Sort-Object { $_.Extent.StartLineNumber }
    
    Write-Host "  Processing '$funcName' with $($instances.Count) definitions" -ForegroundColor Gray
    $log += "Function '$funcName': keeping first at line $($instances[0].Extent.StartLineNumber), removing $($instances.Count - 1) duplicates"
    
    # Keep the first instance, mark others for removal
    for ($i = 1; $i -lt $instances.Count; $i++) {
        $startLine = $instances[$i].Extent.StartLineNumber
        $endLine = $instances[$i].Extent.EndLineNumber
        
        # Mark lines for removal (1-indexed to 0-indexed)
        for ($line = $startLine - 1; $line -le $endLine - 1; $line++) {
            $linesToRemove[$line] = $true
        }
        
        $removedFunctions += @{
            Name = $funcName
            StartLine = $startLine
            EndLine = $endLine
        }
    }
}

Write-Host "`nRemoving duplicate functions..." -ForegroundColor Yellow
$log += ""
$log += "Removed functions:"
foreach ($removed in $removedFunctions) {
    $log += "  - $($removed.Name) at lines $($removed.StartLine)-$($removed.EndLine)"
}

# Build deduplicated content
$deduplicatedContent = @()
$removedLineCount = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    if (-not $linesToRemove.ContainsKey($i)) {
        $deduplicatedContent += $content[$i]
    } else {
        $removedLineCount++
    }
}

Write-Host "Removed $removedLineCount lines" -ForegroundColor Green
$log += ""
$log += "Removed $removedLineCount lines"

# Fix unclosed regions
Write-Host "`nFixing unclosed regions..." -ForegroundColor Yellow
$regionStack = @()
$regionsFixed = 0

$fixedContent = @()
foreach ($line in $deduplicatedContent) {
    if ($line -match '^#region\s*(.*)') {
        $regionStack += $Matches[1]
        $fixedContent += $line
    }
    elseif ($line -match '^#endregion') {
        if ($regionStack.Count -gt 0) {
            $regionStack = $regionStack[0..($regionStack.Count - 2)]
            $fixedContent += $line
        } else {
            # Skip orphaned endregion
            Write-Host "  Removed orphaned #endregion" -ForegroundColor Gray
            $regionsFixed++
        }
    } else {
        $fixedContent += $line
    }
}

# Add missing endregions
if ($regionStack.Count -gt 0) {
    Write-Host "  Adding $($regionStack.Count) missing #endregion tags" -ForegroundColor Gray
    for ($i = 0; $i -lt $regionStack.Count; $i++) {
        $fixedContent += "#endregion"
        $regionsFixed++
    }
}

$log += "Regions fixed: $regionsFixed"

# Clean up obvious orphaned code patterns
Write-Host "`nCleaning orphaned code fragments..." -ForegroundColor Yellow
$cleanedContent = @()
$orphanedLinesRemoved = 0

for ($i = 0; $i -lt $fixedContent.Count; $i++) {
    $line = $fixedContent[$i]
    $skipLine = $false
    
    # Check for corrupted error handling
    if ($line -match '#endregion\.Exception\.Message.*-Level.*ERROR') {
        $skipLine = $true
        $orphanedLinesRemoved++
        Write-Host "  Removed corrupted line at position $i" -ForegroundColor Gray
    }
    
    # Check for stray closing braces after corrupted lines
    if ($i -gt 0 -and $line -match '^\s*\}\s*$') {
        $prevLine = $fixedContent[$i - 1]
        if ($prevLine -match '#endregion\.' -or $prevLine -match '\.Exception\.Message') {
            $skipLine = $true
            $orphanedLinesRemoved++
            Write-Host "  Removed stray brace at position $i" -ForegroundColor Gray
        }
    }
    
    # Check for merge conflict markers
    if ($line -match '^<<<<<<<|^=======|^>>>>>>>') {
        $skipLine = $true
        $orphanedLinesRemoved++
        Write-Host "  Removed merge conflict marker at position $i" -ForegroundColor Gray
    }
    
    if (-not $skipLine) {
        $cleanedContent += $line
    }
}

$log += "Orphaned lines removed: $orphanedLinesRemoved"

# Write deduplicated content
Write-Host "`nWriting deduplicated module..." -ForegroundColor Yellow
$cleanedContent | Set-Content $OutputPath -Encoding UTF8

$newLineCount = $cleanedContent.Count
$reduction = [Math]::Round((($originalLineCount - $newLineCount) / $originalLineCount) * 100, 2)

Write-Host "`n=== Deduplication Summary ===" -ForegroundColor Green
Write-Host "Original: $originalLineCount lines" -ForegroundColor Gray
Write-Host "Deduplicated: $newLineCount lines" -ForegroundColor Gray
Write-Host "Reduction: $reduction% ($($originalLineCount - $newLineCount) lines removed)" -ForegroundColor Green
Write-Host "Functions deduplicated: $($duplicateFunctions.Count)" -ForegroundColor Green
Write-Host "Regions fixed: $regionsFixed" -ForegroundColor Green
Write-Host "Orphaned lines removed: $orphanedLinesRemoved" -ForegroundColor Green

$log += ""
$log += "=== Summary ==="
$log += "Original: $originalLineCount lines"
$log += "Deduplicated: $newLineCount lines"
$log += "Reduction: $reduction%"
$log += "Functions deduplicated: $($duplicateFunctions.Count)"
$log += "Regions fixed: $regionsFixed"
$log += "Orphaned lines removed: $orphanedLinesRemoved"
$log += ""
$log += "Deduplication completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Save log
$log | Out-File $LogPath
Write-Host "`nLog saved to: $LogPath" -ForegroundColor Cyan

# Test the deduplicated module
Write-Host "`nTesting deduplicated module..." -ForegroundColor Yellow
try {
    $testAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $OutputPath,
        [ref]$null,
        [ref]$testErrors
    )
    
    if ($testErrors.Count -eq 0) {
        Write-Host "Deduplicated module parses successfully!" -ForegroundColor Green
    } else {
        Write-Warning "Deduplicated module has $($testErrors.Count) parse errors"
        $testErrors | ForEach-Object { Write-Warning "  - Line $($_.Extent.StartLineNumber): $($_.Message)" }
    }
} catch {
    Write-Error "Failed to parse deduplicated module: $_"
}

Write-Host "`nDeduplication complete! Output saved to: $OutputPath" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSWyOrO4Z7Bscnq10StOZBa47
# gRegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUfzWjChZsdQU/7ueHpM3sKYJjj9gwDQYJKoZIhvcNAQEBBQAEggEANMcg
# kcLbGQV0VxY99rc6EvYFt7w4138n+qPyIdxw83V7/LxuNm+gNIgvQseprUdwUDpF
# 75zg09K+Rj+vcgUJj+ZeTRWgvZFmTPx6ZnwTZ+IiGk0gD2HmmZdJ5aMQk+5YExLj
# P5hXguNv2ROS/LHLhPK8GYFw5TDdXmON1l5q7XWePBZYC3JKhOn3nG/D2H2kkAsc
# 3I8j7M36PLiIs4CMMNVHnrjWLMP00xUyvZ0LrWIWASQ1/frBn+fHM0bEZ8hhGPbd
# mOjjMKDEacspj9EAHC29PftX7EaDHSC/1rf9Vx2CsSvlsYwmJDTkOxARnYyA4TP/
# 9M1o8pLxh1eT5w3R2A==
# SIG # End signature block
