# Check-ModuleSyntax-Maintenance.ps1
# Quick syntax checker for Predictive-Maintenance.psm1

param(
    [string]$ModulePath = ".\Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1"
)

try {
    Write-Host "Checking syntax for: $ModulePath" -ForegroundColor Cyan
    
    # Method 1: Try to parse the file using PowerShell AST
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ModulePath, [ref]$null, [ref]$errors)
    
    if ($errors) {
        Write-Host "PARSER ERRORS FOUND:" -ForegroundColor Red
        foreach ($parseError in $errors) {
            Write-Host "Line $($parseError.Extent.StartLineNumber): $($parseError.Message)" -ForegroundColor Red
            Write-Host "  Text: '$($parseError.Extent.Text)'" -ForegroundColor Yellow
        }
        return $false
    }
    else {
        Write-Host "No parser errors found in AST analysis" -ForegroundColor Green
    }
    
    # Method 2: Try to import the module
    Write-Host "Attempting module import..." -ForegroundColor Cyan
    
    # Remove if already loaded
    if (Get-Module -Name "Predictive-Maintenance" -ErrorAction SilentlyContinue) {
        Remove-Module -Name "Predictive-Maintenance" -Force
    }
    
    Import-Module $ModulePath -Force -DisableNameChecking -ErrorAction Stop
    
    $module = Get-Module -Name "Predictive-Maintenance"
    if ($module) {
        Write-Host "Module imported successfully!" -ForegroundColor Green
        Write-Host "Functions: $($module.ExportedFunctions.Keys -join ', ')" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Module import failed - module not found after import" -ForegroundColor Red
        return $false
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Position: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Red
    return $false
}