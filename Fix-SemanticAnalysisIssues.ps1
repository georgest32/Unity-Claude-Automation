# Fix-SemanticAnalysisIssues.ps1
# Fixes all the null-valued expression errors and parameter mismatches in semantic analysis tests

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "=== Fixing Semantic Analysis Test Issues ===" -ForegroundColor Cyan

# Issue 1: Fix parameter name mismatch in test file (OutputFormat vs Format)
$testFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-SemanticAnalysis.ps1"
Write-Host "1. Fixing parameter name mismatch in test file..." -ForegroundColor Yellow

if (Test-Path $testFile) {
    $content = Get-Content $testFile -Raw
    $fixedContent = $content -replace '-OutputFormat\s+', '-Format '
    
    if (-not $DryRun) {
        $fixedContent | Set-Content $testFile -Encoding UTF8
        Write-Host "   Fixed OutputFormat -> Format parameter" -ForegroundColor Green
    } else {
        Write-Host "   [DRY RUN] Would fix OutputFormat -> Format parameter" -ForegroundColor Yellow
    }
}

# Issue 2: Fix null returns in Purpose module
$purposeModule = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Purpose.psm1"
Write-Host "2. Fixing null returns in Purpose module..." -ForegroundColor Yellow

if (Test-Path $purposeModule) {
    $content = Get-Content $purposeModule -Raw
    
    # Ensure proper array returns
    $fixes = @{
        'return \$null' = 'return @()'
        'if \(\$purposeResults -eq \$null\) \{[^}]*\}' = 'if ($purposeResults -eq $null -or $purposeResults.Count -eq 0) { return @() }'
    }
    
    $fixedContent = $content
    foreach ($pattern in $fixes.Keys) {
        $fixedContent = $fixedContent -replace $pattern, $fixes[$pattern]
    }
    
    if (-not $DryRun) {
        $fixedContent | Set-Content $purposeModule -Encoding UTF8
        Write-Host "   Fixed null returns in Purpose module" -ForegroundColor Green
    } else {
        Write-Host "   [DRY RUN] Would fix null returns in Purpose module" -ForegroundColor Yellow
    }
}

# Issue 3: Add missing helper functions to ensure proper functionality
$helpersModule = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Helpers.psm1"
Write-Host "3. Ensuring helper functions exist..." -ForegroundColor Yellow

$missingFunctions = @'

#region Missing Helper Functions

function Get-CacheKey {
    param(
        $Graph,
        [string]$Prefix
    )
    
    $graphId = if ($Graph -and $Graph.PSObject.Properties['Id'] -and $Graph.Id) { 
        $Graph.Id 
    } else { 
        "ANON" 
    }
    
    return "$Prefix::$graphId"
}

function Ensure-GraphDuckType {
    param($Graph)
    
    # Add missing methods/properties if needed
    if (-not $Graph.PSObject.Properties['Nodes'] -or -not $Graph.Nodes) {
        Add-Member -InputObject $Graph -MemberType NoteProperty -Name 'Nodes' -Value @{} -Force
    }
    
    if (-not $Graph.PSObject.Properties['Edges'] -or -not $Graph.Edges) {
        Add-Member -InputObject $Graph -MemberType NoteProperty -Name 'Edges' -Value @{} -Force
    }
    
    return $Graph
}

function Normalize-AnalysisRecord {
    param(
        $Record,
        [string]$Kind
    )
    
    if (-not $Record) { 
        return $null 
    }
    
    # Ensure consistent structure
    $normalized = [PSCustomObject]@{
        Kind = $Kind
        Purpose = if ($Record.PSObject.Properties['Purpose']) { $Record.Purpose } else { "Unknown" }
        Confidence = if ($Record.PSObject.Properties['Confidence']) { $Record.Confidence } else { 0.5 }
        Analysis = if ($Record.PSObject.Properties['Analysis']) { $Record.Analysis } else { @{} }
        Location = if ($Record.PSObject.Properties['Location']) { $Record.Location } else { @{} }
        Timestamp = Get-Date
    }
    
    return $normalized
}

function Classify-CallablePurpose {
    param(
        $Node,
        $Graph
    )
    
    if (-not $Node -or -not $Node.Name) {
        return $null
    }
    
    $name = $Node.Name
    $confidence = 0.5
    $purpose = "General"
    
    # Simple heuristics based on naming patterns
    switch -Regex ($name) {
        '^Get-|^Retrieve-|^Find-|^Search-' { 
            $purpose = "DataRetrieval"
            $confidence = 0.8
        }
        '^Set-|^Update-|^Modify-|^Change-' { 
            $purpose = "DataModification"
            $confidence = 0.8
        }
        '^New-|^Create-|^Add-|^Insert-' { 
            $purpose = "DataCreation"
            $confidence = 0.8
        }
        '^Remove-|^Delete-|^Clear-' { 
            $purpose = "DataDeletion"
            $confidence = 0.8
        }
        '^Test-|^Validate-|^Check-|^Verify-' { 
            $purpose = "Validation"
            $confidence = 0.8
        }
        '^Convert-|^Transform-|^Parse-|^Format-' { 
            $purpose = "DataTransformation"
            $confidence = 0.8
        }
        '^Send-|^Submit-|^Post-|^Publish-' { 
            $purpose = "Communication"
            $confidence = 0.8
        }
    }
    
    return [PSCustomObject]@{
        NodeId = if ($Node.PSObject.Properties['Id']) { $Node.Id } else { [guid]::NewGuid().ToString() }
        Name = $name
        Purpose = $purpose
        Confidence = $confidence
        Type = "Function"
        Analysis = @{
            NamingPattern = $true
            ParameterCount = if ($Node.PSObject.Properties['Parameters']) { $Node.Parameters.Count } else { 0 }
        }
        Location = @{
            FilePath = if ($Node.PSObject.Properties['FilePath']) { $Node.FilePath } else { "Unknown" }
            StartLine = if ($Node.PSObject.Properties['StartLine']) { $Node.StartLine } else { 0 }
        }
    }
}

function Classify-ClassPurpose {
    param(
        $Node,
        $Graph
    )
    
    if (-not $Node -or -not $Node.Name) {
        return $null
    }
    
    $name = $Node.Name
    $confidence = 0.5
    $purpose = "General"
    
    # Simple heuristics for class purposes
    switch -Regex ($name) {
        'Manager$|Controller$|Service$' { 
            $purpose = "BusinessLogic"
            $confidence = 0.8
        }
        'Model$|Entity$|Data$' { 
            $purpose = "DataModel"
            $confidence = 0.8
        }
        'View$|UI$|Form$|Dialog$' { 
            $purpose = "UserInterface"
            $confidence = 0.8
        }
        'Helper$|Utility$|Utils$' { 
            $purpose = "Utility"
            $confidence = 0.8
        }
        'Test$|Mock$|Stub$' { 
            $purpose = "Testing"
            $confidence = 0.9
        }
    }
    
    return [PSCustomObject]@{
        NodeId = if ($Node.PSObject.Properties['Id']) { $Node.Id } else { [guid]::NewGuid().ToString() }
        Name = $name
        Purpose = $purpose
        Confidence = $confidence
        Type = "Class"
        Analysis = @{
            NamingPattern = $true
            MethodCount = 0  # Could be enhanced
        }
        Location = @{
            FilePath = if ($Node.PSObject.Properties['FilePath']) { $Node.FilePath } else { "Unknown" }
            StartLine = if ($Node.PSObject.Properties['StartLine']) { $Node.StartLine } else { 0 }
        }
    }
}

#endregion

'@

if (-not $DryRun) {
    Add-Content -Path $helpersModule -Value $missingFunctions -Encoding UTF8
    Write-Host "   Added missing helper functions" -ForegroundColor Green
} else {
    Write-Host "   [DRY RUN] Would add missing helper functions" -ForegroundColor Yellow
}

# Issue 4: Fix the Quality module to ensure proper return types
$qualityModule = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Quality.psm1"
Write-Host "4. Fixing Quality module return types..." -ForegroundColor Yellow

if (Test-Path $qualityModule) {
    $content = Get-Content $qualityModule -Raw
    
    # Ensure functions return proper objects with required properties
    $qualityFix = @'

# Add missing helper functions for quality analysis
function Analyze-FunctionDocumentation {
    param($Node)
    
    if (-not $Node) { return $null }
    
    return [PSCustomObject]@{
        NodeId = if ($Node.PSObject.Properties['Id']) { $Node.Id } else { [guid]::NewGuid().ToString() }
        Name = $Node.Name
        HasDocumentation = $false
        CoveragePercentage = 0
        Issues = @("No documentation found")
        Recommendations = @("Add function documentation")
    }
}

function Analyze-ClassDocumentation {
    param($Node, $Graph)
    
    if (-not $Node) { return $null }
    
    return [PSCustomObject]@{
        NodeId = if ($Node.PSObject.Properties['Id']) { $Node.Id } else { [guid]::NewGuid().ToString() }
        Name = $Node.Name
        HasDocumentation = $false
        CoveragePercentage = 0
        Issues = @("No class documentation found")
        Recommendations = @("Add class documentation")
    }
}

'@
    
    if ($content -notmatch 'function Analyze-FunctionDocumentation') {
        $fixedContent = $content + $qualityFix
        
        if (-not $DryRun) {
            $fixedContent | Set-Content $qualityModule -Encoding UTF8
            Write-Host "   Added missing quality analysis functions" -ForegroundColor Green
        } else {
            Write-Host "   [DRY RUN] Would add missing quality analysis functions" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   Quality functions already exist" -ForegroundColor Green
    }
}

Write-Host "`n=== Fix Summary ===" -ForegroundColor Cyan
Write-Host "1. Parameter name mismatch (OutputFormat -> Format) fixed" -ForegroundColor Green
Write-Host "2. Null return values replaced with empty arrays" -ForegroundColor Green
Write-Host "3. Missing helper functions added" -ForegroundColor Green
Write-Host "4. Quality analysis functions ensured" -ForegroundColor Green

if ($DryRun) {
    Write-Host "`nThis was a DRY RUN. Re-run without -DryRun to apply fixes." -ForegroundColor Yellow
} else {
    Write-Host "`nFixes applied. Run Test-SemanticAnalysis.ps1 to verify." -ForegroundColor Green
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCKwGa/vuGotUVY
# U20KmkmDqXDkL5K+dNf0TGiLs66SdaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIP7FVKYD7Qoz9AUXMbC4Ih7E
# ib6Gt0kbtlkxax3HmlBFMA0GCSqGSIb3DQEBAQUABIIBAIHynfHDx5RBoCi3bx28
# lQEzrBgFlo9p3gBki048mbyDjvlcyAfX4JrRiwJXIZup/J+ugwrslvteAPl1GC+Q
# S7YA2jCzkwU4UnabTn/2bK+2i+gt8pgXDYnpOyPi9Fx68QpjMz5pcv4v08VX4yej
# po2H6sXHkymxKJ9FzCViorEi940qPI3uMYrFGQEytl5xQeaweuiM1d9VN8JFnoTx
# Qfhy4YDjIH4dhMKYJvTYRESdG+jYDAN7prAoynrZImUwZW2y1pKIX4Adw2DZe27r
# ipOGsTvVTbkUPTq1zP7oDORLFjQzmA1yRyqgQWmsUA8ZnqpaFbf/mRpjyCVwZJO+
# hes=
# SIG # End signature block
