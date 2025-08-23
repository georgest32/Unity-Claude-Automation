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