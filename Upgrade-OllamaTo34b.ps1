# Upgrade Ollama configuration from 13b to 34b model across all modules
Write-Host "Upgrading Ollama model configuration from codellama:13b to codellama:34b..." -ForegroundColor Cyan

$filesToUpdate = @(
    ".\Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1",
    ".\Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Enhanced.psm1",
    ".\Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized.psm1",
    ".\Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama-Optimized-Fixed.psm1",
    ".\Modules\Unity-Claude-DocumentationSuggestions\Unity-Claude-DocumentationSuggestions.psm1",
    ".\Modules\Unity-Claude-AutonomousDocumentationEngine\Unity-Claude-AutonomousDocumentationEngine.psm1",
    ".\Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1",
    ".\Modules\Unity-Claude-LLM\Unity-Claude-LLM.psm1",
    ".\Modules\Unity-Claude-LLM\Core\LLM-ResponseCache.psm1"
)

$filesUpdated = 0
foreach ($file in $filesToUpdate) {
    if (Test-Path $file) {
        Write-Host "  Updating: $file" -ForegroundColor Yellow
        try {
            $content = Get-Content $file -Raw -Encoding UTF8
            
            # Replace codellama:13b with codellama:34b
            $updatedContent = $content -replace 'codellama:13b', 'codellama:34b'
            
            # Check if any changes were made
            if ($updatedContent -ne $content) {
                Set-Content -Path $file -Value $updatedContent -Encoding UTF8
                Write-Host "    [UPDATED] Model configuration changed to codellama:34b" -ForegroundColor Green
                $filesUpdated++
            } else {
                Write-Host "    [SKIP] No codellama:13b references found" -ForegroundColor Gray
            }
        } catch {
            Write-Host "    [ERROR] Failed to update: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "    [SKIP] File not found: $file" -ForegroundColor Gray
    }
}

Write-Host "`nUpdate Summary:" -ForegroundColor Cyan
Write-Host "  Files updated: $filesUpdated" -ForegroundColor Green
Write-Host "  Model upgraded: codellama:13b -> codellama:34b" -ForegroundColor Green

# Test the upgraded configuration
Write-Host "`nTesting upgraded Ollama configuration..." -ForegroundColor Blue
try {
    Import-Module ".\Modules\Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1" -Force
    Write-Host "  [PASS] Ollama module loaded with updated configuration" -ForegroundColor Green
    
    # Check the default model setting
    if ($script:OllamaConfig.DefaultModel -eq "codellama:34b") {
        Write-Host "  [PASS] Default model correctly set to codellama:34b" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Default model is: $($script:OllamaConfig.DefaultModel)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Failed to test updated configuration: $_" -ForegroundColor Red
}

Write-Host "`nOllama upgrade complete!" -ForegroundColor Cyan
Write-Host "The system will now use the more capable codellama:34b model for better AI-enhanced documentation quality assessment." -ForegroundColor Green