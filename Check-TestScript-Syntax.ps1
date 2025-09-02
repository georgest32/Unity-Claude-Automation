# Check-TestScript-Syntax.ps1
# Syntax checker for Test-MaintenancePrediction.ps1

param(
    [string]$TestScript = ".\Test-MaintenancePrediction.ps1"
)

try {
    Write-Host "Checking syntax for: $TestScript" -ForegroundColor Cyan
    
    # Parse the test script
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($TestScript, [ref]$null, [ref]$parseErrors)
    
    if ($parseErrors) {
        Write-Host "PARSER ERRORS FOUND:" -ForegroundColor Red
        foreach ($err in $parseErrors) {
            Write-Host "Line $($err.Extent.StartLineNumber): $($err.Message)" -ForegroundColor Red
            Write-Host "  Context: '$($err.Extent.Text)'" -ForegroundColor Yellow
        }
        return $false
    }
    else {
        Write-Host "Test script syntax is clean - no parser errors found" -ForegroundColor Green
        return $true
    }
}
catch {
    Write-Host "ERROR checking syntax: $($_.Exception.Message)" -ForegroundColor Red
    return $false
}