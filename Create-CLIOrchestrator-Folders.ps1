# Create-CLIOrchestrator-Folders.ps1
# Creates Public/Private folder structure for full-featured CLIOrchestrator

Write-Host 'Creating Public/Private folder structure for CLIOrchestrator...' -ForegroundColor Cyan

$moduleRoot = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator'

# Create Public folder structure
$publicFolders = @(
    'Public\Core',
    'Public\WindowManager', 
    'Public\PromptSubmission',
    'Public\AutonomousOperations',
    'Public\OrchestrationManager',
    'Public\DecisionEngine',
    'Public\CircuitBreaker',
    'Public\PatternRecognition',
    'Public\ResponseAnalysis',
    'Public\ActionExecution'
)

# Create Private folder structure  
$privateFolders = @(
    'Private\Configuration',
    'Private\Validation',
    'Private\Utilities'
)

# Create all folders
$allFolders = $publicFolders + $privateFolders
foreach ($folder in $allFolders) {
    $fullPath = Join-Path $moduleRoot $folder
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Created: $folder" -ForegroundColor Green
    } else {
        Write-Host "Exists: $folder" -ForegroundColor Yellow
    }
}

Write-Host 'Folder structure created successfully!' -ForegroundColor Green