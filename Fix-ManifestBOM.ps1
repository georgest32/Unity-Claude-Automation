# Fix-ManifestBOM.ps1
# Removes UTF-8 BOM from manifest files

$manifestFiles = @(
    ".\Manifests\SystemMonitoring.manifest.psd1",
    ".\Manifests\AutonomousAgent.manifest.psd1",
    ".\Manifests\CLISubmission.manifest.psd1"
)

foreach ($file in $manifestFiles) {
    if (Test-Path $file) {
        Write-Host "Processing: $file"
        
        # Read content as bytes
        $bytes = [System.IO.File]::ReadAllBytes($file)
        
        # Check for UTF-8 BOM (EF BB BF)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Host "  BOM detected, removing..." -ForegroundColor Yellow
            
            # Remove first 3 bytes (BOM)
            $newBytes = $bytes[3..($bytes.Length-1)]
            
            # Write back without BOM
            [System.IO.File]::WriteAllBytes($file, $newBytes)
            Write-Host "  BOM removed successfully" -ForegroundColor Green
        } else {
            Write-Host "  No BOM found" -ForegroundColor Gray
        }
    } else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nDone! Manifests cleaned." -ForegroundColor Green