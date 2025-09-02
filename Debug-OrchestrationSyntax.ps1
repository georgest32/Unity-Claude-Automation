# Debug-OrchestrationSyntax.ps1
# Enhanced debugging for OrchestrationManager.psm1 syntax errors

$filePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"

Write-Host "=== ENHANCED SYNTAX DEBUGGING ===" -ForegroundColor Cyan
Write-Host "Target file: $filePath" -ForegroundColor Yellow
Write-Host ""

# Step 1: Try to parse the file and get exact error location
Write-Host "Step 1: Parsing file with PowerShell AST parser..." -ForegroundColor Green
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)

if ($errors) {
    Write-Host "SYNTAX ERRORS FOUND:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host ""
        Write-Host "  Error #$($errors.IndexOf($error) + 1):" -ForegroundColor Yellow
        Write-Host "    Message: $($error.Message)" -ForegroundColor Red
        Write-Host "    Line: $($error.Extent.StartLineNumber)" -ForegroundColor Cyan
        Write-Host "    Column: $($error.Extent.StartColumnNumber)" -ForegroundColor Cyan
        Write-Host "    Text near error: $($error.Extent.Text)" -ForegroundColor Gray
        
        # Get context around the error
        $fileContent = Get-Content $filePath
        $errorLine = $error.Extent.StartLineNumber - 1
        
        Write-Host "    Context (lines $($errorLine - 1) to $($errorLine + 2)):" -ForegroundColor Magenta
        for ($i = [Math]::Max(0, $errorLine - 2); $i -le [Math]::Min($fileContent.Count - 1, $errorLine + 2); $i++) {
            $lineNum = $i + 1
            $prefix = if ($i -eq $errorLine) { ">>> " } else { "    " }
            $color = if ($i -eq $errorLine) { "Red" } else { "Gray" }
            Write-Host "$prefix$lineNum`: $($fileContent[$i])" -ForegroundColor $color
        }
    }
} else {
    Write-Host "No syntax errors found by AST parser" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2: Searching for problematic patterns..." -ForegroundColor Green

# Search for specific problematic patterns
$patterns = @{
    "Unclosed strings" = '["''][^"'']*$'
    "Missing closing parenthesis" = '\([^)]*$'
    "Missing closing bracket" = '\[[^\]]*$'
    "Missing closing brace" = '\{[^}]*$'
    "Double dots" = '\.\.'
    "Invalid variable names" = '\$[^a-zA-Z_]'
    "Orphaned occurrences" = '^\s*occurrences'
}

$content = Get-Content $filePath
$lineNum = 0

foreach ($line in $content) {
    $lineNum++
    foreach ($pattern in $patterns.GetEnumerator()) {
        if ($line -match $pattern.Value) {
            Write-Host "  Potential issue - $($pattern.Key) at line $lineNum`: $line" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Step 3: Checking specific 'occurrences' locations..." -ForegroundColor Green

# Find all occurrences of "occurrences"
$lineNum = 0
foreach ($line in $content) {
    $lineNum++
    if ($line -match 'occurrences') {
        Write-Host "  Line $lineNum`: $line" -ForegroundColor Cyan
        
        # Check if it's properly embedded in a string
        if ($line -match '"[^"]*occurrences[^"]*"' -or $line -match "'[^']*occurrences[^']*'") {
            Write-Host "    Status: Properly quoted" -ForegroundColor Green
        } else {
            Write-Host "    Status: MAY BE PROBLEMATIC - not in quotes" -ForegroundColor Red
            
            # Show surrounding context
            Write-Host "    Previous line: $($content[$lineNum - 2])" -ForegroundColor Gray
            Write-Host "    Next line: $($content[$lineNum])" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "Step 4: Testing module import directly..." -ForegroundColor Green

try {
    # Try importing just the problematic module
    Import-Module $filePath -Force -ErrorAction Stop
    Write-Host "  Module imported successfully!" -ForegroundColor Green
} catch {
    Write-Host "  Module import failed with error:" -ForegroundColor Red
    Write-Host "    $_" -ForegroundColor Red
    
    if ($_.Exception.InnerException) {
        Write-Host "    Inner exception: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
    }
    
    # Try to get more details from the error
    if ($_.FullyQualifiedErrorId) {
        Write-Host "    Error ID: $($_.FullyQualifiedErrorId)" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "Step 5: Checking for string interpolation issues..." -ForegroundColor Green

# Look for complex string interpolations that might be problematic
$lineNum = 0
foreach ($line in $content) {
    $lineNum++
    # Check for $() inside strings
    if ($line -match '\$\([^)]+\).*occurrences') {
        Write-Host "  Line $lineNum has string interpolation with 'occurrences':" -ForegroundColor Yellow
        Write-Host "    $line" -ForegroundColor Gray
        
        # Check if the parentheses are balanced
        $openCount = ([regex]::Matches($line, '\(')).Count
        $closeCount = ([regex]::Matches($line, '\)')).Count
        
        if ($openCount -ne $closeCount) {
            Write-Host "    WARNING: Unbalanced parentheses! Open: $openCount, Close: $closeCount" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "=== END OF DEBUGGING ===" -ForegroundColor Cyan