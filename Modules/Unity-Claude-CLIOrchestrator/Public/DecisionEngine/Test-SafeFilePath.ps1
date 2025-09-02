function Test-SafeFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $result = @{
        IsSafe = $true
        Reason = "File path is safe"
        Warnings = @()
    }
    
    try {
        # Initialize config if not set
        if (-not $script:DecisionConfig) {
            $script:DecisionConfig = @{
                SafetyThresholds = @{
                    BlockedPaths = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)')
                    AllowedFileExtensions = @('.ps1', '.psm1', '.psd1', '.json', '.txt', '.md', '.yml', '.yaml')
                    MaxFileSize = 10MB
                }
            }
        }
        
        # Normalize path
        $normalizedPath = [System.IO.Path]::GetFullPath($FilePath)
        
        # Check blocked paths
        foreach ($blockedPath in $script:DecisionConfig.SafetyThresholds.BlockedPaths) {
            if ($normalizedPath.StartsWith($blockedPath, [StringComparison]::OrdinalIgnoreCase)) {
                $result.IsSafe = $false
                $result.Reason = "Path is in blocked directory: $blockedPath"
                return $result
            }
        }
        
        # Check file extension
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        if ($extension -and $extension -notin $script:DecisionConfig.SafetyThresholds.AllowedFileExtensions) {
            $result.IsSafe = $false
            $result.Reason = "File extension not allowed: $extension"
            return $result
        }
        
        # Check if file exists and size
        if (Test-Path $FilePath) {
            $fileInfo = Get-Item $FilePath
            if ($fileInfo.Length -gt $script:DecisionConfig.SafetyThresholds.MaxFileSize) {
                $result.IsSafe = $false
                $result.Reason = "File too large: $($fileInfo.Length) bytes"
                return $result
            }
        }
        
        Write-DecisionLog "File path validation passed: $FilePath" "DEBUG"
        return $result
        
    } catch {
        $result.IsSafe = $false
        $result.Reason = "File path validation error: $($_.Exception.Message)"
        return $result
    }
}