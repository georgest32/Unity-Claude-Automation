# Fix all syntax errors in DocumentationQualityAssessment module
$modulePath = ".\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1"

Write-Host "Reading module content..." -ForegroundColor Cyan
$content = Get-Content $modulePath -Raw
$lines = $content -split "`r?`n"

Write-Host "Fixing syntax errors..." -ForegroundColor Yellow

# Fix 1: Line 554 - Escape the percent sign
if ($lines[553] -match '\$successRate%') {
    Write-Host "  Fixing line 554: Escaping percent sign" -ForegroundColor Green
    $lines[553] = $lines[553] -replace '\$successRate%', '$successRate`%'
}

# Fix 2: Find and fix the try block without catch
Write-Host "  Searching for try blocks without catch/finally..." -ForegroundColor Green
$tryLineNumbers = @()
$catchLineNumbers = @()
$finallyLineNumbers = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*try\s*{') {
        $tryLineNumbers += $i
    }
    if ($lines[$i] -match '^\s*catch') {
        $catchLineNumbers += $i
    }
    if ($lines[$i] -match '^\s*finally') {
        $finallyLineNumbers += $i
    }
}

# Check if we need to add a catch block after the try at line 265
$line265TryIndex = 264  # 0-based index
if ($lines[$line265TryIndex] -match '^\s*try\s*{') {
    Write-Host "  Found try block at line 265" -ForegroundColor Yellow
    
    # Find the closing brace for this try block
    $braceCount = 0
    $foundTry = $false
    $endOfTryBlock = -1
    
    for ($i = $line265TryIndex; $i -lt [Math]::Min($lines.Count, $line265TryIndex + 200); $i++) {
        if ($lines[$i] -match 'try\s*{') {
            $foundTry = $true
            $braceCount++
        } elseif ($foundTry) {
            $braceCount += ([regex]::Matches($lines[$i], '{').Count)
            $braceCount -= ([regex]::Matches($lines[$i], '}').Count)
            
            if ($braceCount -eq 0) {
                $endOfTryBlock = $i
                break
            }
        }
    }
    
    if ($endOfTryBlock -gt 0) {
        # Check if there's already a catch or finally
        $hasHandler = $false
        if ($endOfTryBlock + 1 -lt $lines.Count) {
            if ($lines[$endOfTryBlock + 1] -match '^\s*(catch|finally)') {
                $hasHandler = $true
            }
        }
        
        if (-not $hasHandler) {
            Write-Host "  Adding catch block after try block ending at line $($endOfTryBlock + 1)" -ForegroundColor Green
            # Insert a catch block
            $catchBlock = @(
                "    }",
                "    catch {",
                "        Write-Error `"Error in Assess-DocumentationQuality: `$_`"",
                "        return `$null"
            )
            
            # Replace the closing brace with our catch block
            $lines[$endOfTryBlock] = $catchBlock -join "`n"
        }
    }
}

# Fix 3: Check for unmatched quotes around line 960
Write-Host "  Checking for unmatched quotes..." -ForegroundColor Green
for ($i = 955; $i -lt [Math]::Min($lines.Count, 965); $i++) {
    if ($lines[$i] -match '"[^"]*$' -and $lines[$i] -notmatch '^\s*#') {
        Write-Host "    Found potential unmatched quote at line $($i + 1)" -ForegroundColor Yellow
        # This line might have an unmatched quote, but it looks correct in the EXAMPLE section
    }
}

# Write the fixed content back
Write-Host "`nWriting fixed content back to file..." -ForegroundColor Cyan
$fixedContent = $lines -join "`n"
Set-Content -Path $modulePath -Value $fixedContent -Encoding UTF8

# Test if the module can now be parsed
Write-Host "`nTesting module syntax..." -ForegroundColor Cyan
$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $modulePath,
    [ref]$tokens,
    [ref]$errors
)

if ($errors.Count -eq 0) {
    Write-Host "Module now parses without errors!" -ForegroundColor Green
} else {
    Write-Host "Still has $($errors.Count) parse errors:" -ForegroundColor Red
    $errors | ForEach-Object {
        Write-Host "  Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
    }
}

# Try to import the module
Write-Host "`nTesting module loading..." -ForegroundColor Cyan
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module loaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Module failed to load: $_" -ForegroundColor Red
}