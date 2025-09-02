# Debug-ModuleSyntax.ps1
# Quick syntax test for the PermissionHandler module

Write-Host "Testing PermissionHandler module syntax..." -ForegroundColor Cyan

try {
    # Test the syntax by parsing without executing
    $content = Get-Content ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Raw
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$parseErrors)
    
    if ($parseErrors.Count -eq 0) {
        Write-Host "✅ Syntax is valid" -ForegroundColor Green
        
        # Try to import
        Write-Host "Testing import..." -ForegroundColor Gray
        Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force -ErrorAction Stop
        Write-Host "✅ Import successful" -ForegroundColor Green
        
        # Test function availability
        $functions = @(
            'Initialize-PermissionHandler',
            'Get-PermissionDecision',
            'Get-PermissionStatistics'
        )
        
        foreach ($func in $functions) {
            if (Get-Command $func -ErrorAction SilentlyContinue) {
                Write-Host "✅ Function available: $func" -ForegroundColor Green
            } else {
                Write-Host "❌ Function missing: $func" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "❌ Syntax errors found:" -ForegroundColor Red
        foreach ($error in $parseErrors) {
            Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "❌ Error testing module: $_" -ForegroundColor Red
}