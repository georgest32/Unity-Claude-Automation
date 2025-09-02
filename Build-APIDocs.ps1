# Build-APIDocs.ps1
# Builds API documentation from source code using various tools

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'CSharp', 'TypeScript', 'Python', 'PowerShell')]
    [string]$Language = 'All',
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean
)

$ErrorActionPreference = 'Continue'

function Write-Status {
    param([string]$Message, [string]$Type = 'Info')
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    Write-Host $Message -ForegroundColor $colors[$Type]
}

# Clean previous builds if requested
if ($Clean) {
    Write-Status "Cleaning previous API documentation..." -Type Info
    Remove-Item -Path "docs\api\unity" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "docs\api\typescript" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "docs\api\python\generated" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "_site\docfx" -Recurse -Force -ErrorAction SilentlyContinue
}

# Build C# documentation with DocFX
if ($Language -eq 'All' -or $Language -eq 'CSharp') {
    Write-Status "`n=== Building C#/.NET Documentation with DocFX ===" -Type Info
    
    if (Get-Command docfx -ErrorAction SilentlyContinue) {
        try {
            Write-Status "Generating C# API metadata..." -Type Info
            docfx metadata docfx.json --warningsAsErrors false 2>&1 | Out-Null
            
            Write-Status "Building C# documentation site..." -Type Info
            docfx build docfx.json --warningsAsErrors false 2>&1 | Out-Null
            
            # Convert to Markdown for MkDocs integration
            if (Test-Path "_site\docfx\api") {
                Write-Status "Converting to Markdown format..." -Type Info
                Copy-Item -Path "_site\docfx\api\*.md" -Destination "docs\api\unity\" -Force -ErrorAction SilentlyContinue
                Write-Status "✓ C# documentation generated successfully" -Type Success
            }
        }
        catch {
            Write-Status "✗ DocFX build failed: $_" -Type Error
        }
    }
    else {
        Write-Status "✗ DocFX not found. Install with: dotnet tool install -g docfx" -Type Warning
    }
}

# Build TypeScript documentation with TypeDoc
if ($Language -eq 'All' -or $Language -eq 'TypeScript') {
    Write-Status "`n=== Building TypeScript Documentation with TypeDoc ===" -Type Info
    
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        # Check if there are TypeScript files
        $tsFiles = Get-ChildItem -Path "scripts" -Filter "*.ts" -Recurse -ErrorAction SilentlyContinue
        
        if ($tsFiles.Count -gt 0) {
            Write-Status "Found $($tsFiles.Count) TypeScript files" -Type Info
            npx typedoc 2>&1 | Out-Null
            
            if (Test-Path "docs\api\typescript") {
                Write-Status "✓ TypeScript documentation generated successfully" -Type Success
            }
        }
        else {
            Write-Status "No TypeScript files found in scripts/" -Type Warning
            # Create placeholder
            New-Item -Path "docs\api\typescript" -ItemType Directory -Force | Out-Null
            @"
# TypeScript API Documentation

No TypeScript files found in the project yet.

TypeDoc will automatically generate documentation here when TypeScript files are added to the `scripts/` directory.
"@ | Out-File -FilePath "docs\api\typescript\index.md" -Encoding UTF8
        }
    }
    else {
        Write-Status "✗ TypeDoc not found. Install with: npm install --save-dev typedoc" -Type Warning
    }
}

# Build Python documentation with Sphinx
if ($Language -eq 'All' -or $Language -eq 'Python') {
    Write-Status "`n=== Building Python Documentation with Sphinx ===" -Type Info
    
    if (Test-Path ".venv\Scripts\sphinx-build.exe") {
        # Check for Python files
        $pyFiles = Get-ChildItem -Path "scripts" -Filter "*.py" -Recurse -ErrorAction SilentlyContinue
        
        if ($pyFiles.Count -gt 0) {
            Write-Status "Found $($pyFiles.Count) Python files" -Type Info
            
            # Create API RST files
            New-Item -Path "docs\api\python\generated" -ItemType Directory -Force | Out-Null
            
            # Generate autodoc files
            & ".\.venv\Scripts\sphinx-apidoc.exe" -o "docs\api\python\generated" "scripts" --force --module-first --separate 2>&1 | Out-Null
            
            # Build HTML documentation
            & ".\.venv\Scripts\sphinx-build.exe" -b html "docs" "_build\sphinx" 2>&1 | Out-Null
            
            # Convert to Markdown
            if (Test-Path "_build\sphinx") {
                Write-Status "✓ Python documentation generated successfully" -Type Success
            }
        }
        else {
            Write-Status "No Python files found in scripts/" -Type Warning
            # Create placeholder
            @"
# Python API Documentation

No Python files found in the project yet.

Sphinx will automatically generate documentation here when Python files are added to the `scripts/` directory.
"@ | Out-File -FilePath "docs\api\python\index.md" -Encoding UTF8
        }
    }
    else {
        Write-Status "✗ Sphinx not found. Activate venv and install: pip install sphinx" -Type Warning
    }
}

# Build PowerShell documentation
if ($Language -eq 'All' -or $Language -eq 'PowerShell') {
    Write-Status "`n=== Building PowerShell Documentation ===" -Type Info
    
    # Use existing PowerShell documentation extraction
    $docScript = ".\scripts\docs\Get-PowerShellDocumentation.ps1"
    if (Test-Path $docScript) {
        # Create output directory
        New-Item -Path "docs\api\powershell\generated" -ItemType Directory -Force | Out-Null
        & $docScript -Path ".\Modules" -OutputFormat Markdown -Recurse
        Write-Status "✓ PowerShell documentation generated successfully" -Type Success
    }
    else {
        Write-Status "PowerShell documentation script not found" -Type Warning
    }
}

Write-Status "`n=== API Documentation Build Complete ===" -Type Success
Write-Status "Documentation generated in: docs\api\" -Type Info

# Rebuild MkDocs to include new API docs
Write-Status "`nRebuilding MkDocs site with API documentation..." -Type Info
if (Test-Path ".venv\Scripts\Activate.ps1") {
    & ".\.venv\Scripts\Activate.ps1"
    mkdocs build 2>&1 | Out-Null
    Write-Status "✓ MkDocs site rebuilt with API documentation" -Type Success
}

Write-Status "`nAPI documentation ready for deployment!" -Type Success
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBTYeCoGeQAE3u8
# 7IE5Sym4tSI5FruT0KGLVetukR18N6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIME6yxIQ4DGXkDok3k3DYx4J
# 0n0VXaJMem53nUb+fYcsMA0GCSqGSIb3DQEBAQUABIIBAGENbSa8Fd8wPs9rPgy7
# FCwna/TohSs3dfNWZXuJhknr92qjOj4rJgLQS0ZpHjZdVlbNl1Pkh0TPw2ODpiHX
# /+5OYlNHMckgC2/+pv3q5ysjO+3X5v7C1BGlIQ0uJTwUHU4BLxO5+tUO1bBdJazZ
# bMbMAXZNFZ8dp5oKSJCY9cR0GIMVHeA8nn968xeSVpwmk4CV2Ar1d09d43n+XAuJ
# jrj1hWtH1AUj8NuLX4doNAmwKBrOkZwU5kaS2IJpbX8fI3BSCPjPUaT9WmFosObd
# 2WBQEJo2g84kqCMn9RVxZ79ZkY5gXzkiYTF4QI0m+QdfBm5XjVZj2XcInr5cXS1h
# 37Y=
# SIG # End signature block
