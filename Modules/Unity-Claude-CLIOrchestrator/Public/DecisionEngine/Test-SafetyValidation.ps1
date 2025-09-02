function Test-SafetyValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult
    )
    
    Write-DecisionLog "Starting safety validation" "DEBUG"
    
    $validationResult = @{
        IsSafe = $true
        Reason = "All safety checks passed"
        Warnings = @()
        Details = @{}
    }
    
    try {
        # Check for dangerous patterns
        if ($AnalysisResult.ContainsKey('ResponseText')) {
            $responseText = $AnalysisResult.ResponseText
            
            # Dangerous command patterns
            $dangerousPatterns = @(
                'Remove-Item.*-Recurse.*-Force',
                'rm\s+-rf',
                'del\s+/s\s+/q',
                'format\s+c:',
                'shutdown',
                'reboot',
                'restart-computer'
            )
            
            foreach ($pattern in $dangerousPatterns) {
                if ($responseText -match $pattern) {
                    $validationResult.IsSafe = $false
                    $validationResult.Reason = "Contains dangerous pattern: $pattern"
                    Write-DecisionLog "SAFETY VIOLATION: $pattern detected" "ERROR"
                    return $validationResult
                }
            }
        }
        
        # Check file operations
        if ($AnalysisResult.ContainsKey('Recommendations')) {
            foreach ($rec in $AnalysisResult.Recommendations) {
                if ($rec.Type -eq 'FIX' -and $rec.FilePath) {
                    $fileValidation = Test-SafeFilePath -FilePath $rec.FilePath
                    if (-not $fileValidation.IsSafe) {
                        $validationResult.IsSafe = $false
                        $validationResult.Reason = "Unsafe file operation: $($fileValidation.Reason)"
                        return $validationResult
                    }
                }
            }
        }
        
        Write-DecisionLog "Safety validation completed - SAFE" "SUCCESS"
        return $validationResult
        
    } catch {
        Write-DecisionLog "Safety validation error: $($_.Exception.Message)" "ERROR"
        $validationResult.IsSafe = $false
        $validationResult.Reason = "Safety validation failed: $($_.Exception.Message)"
        return $validationResult
    }
}