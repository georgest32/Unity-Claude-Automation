# Test-EnhancedStartup.ps1
# Quick test of the enhanced Start-UnityClaudeSystem-Windowed.ps1 script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Enhanced System Startup" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test parameter combinations
$testCases = @(
    @{
        Name = "Start All Services"
        Command = ".\Start-UnityClaudeSystem-Windowed.ps1 -StartAllServices -UseManifestMode"
        Description = "Starts everything: Docker, Grafana, Visualization, Ollama, Python services"
    },
    @{
        Name = "Start Only Visualization"
        Command = ".\Start-UnityClaudeSystem-Windowed.ps1 -StartVisualization -UseManifestMode"
        Description = "Starts only the D3.js visualization dashboard"
    },
    @{
        Name = "Start Docker and Grafana"
        Command = ".\Start-UnityClaudeSystem-Windowed.ps1 -StartDockerServices -UseManifestMode"
        Description = "Starts Docker Desktop and monitoring stack"
    }
)

Write-Host "Available test commands:" -ForegroundColor Yellow
Write-Host ""

foreach ($i in 0..($testCases.Count - 1)) {
    $test = $testCases[$i]
    Write-Host "[$($i + 1)] $($test.Name)" -ForegroundColor Cyan
    Write-Host "    $($test.Description)" -ForegroundColor Gray
    Write-Host "    Command: $($test.Command)" -ForegroundColor White
    Write-Host ""
}

Write-Host "Which test would you like to run? (1-$($testCases.Count)) or 'q' to quit: " -NoNewline -ForegroundColor Yellow
$choice = Read-Host

if ($choice -eq 'q') {
    Write-Host "Test cancelled." -ForegroundColor Yellow
    exit
}

$index = [int]$choice - 1
if ($index -ge 0 -and $index -lt $testCases.Count) {
    $selectedTest = $testCases[$index]
    Write-Host ""
    Write-Host "Running: $($selectedTest.Name)" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Execute the command
    Invoke-Expression $selectedTest.Command
} else {
    Write-Host "Invalid choice." -ForegroundColor Red
}