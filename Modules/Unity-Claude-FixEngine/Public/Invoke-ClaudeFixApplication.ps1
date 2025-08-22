function Invoke-ClaudeFixApplication {
    <#
    .SYNOPSIS
    Main fix application orchestrator powered by Claude's code analysis
    
    .DESCRIPTION
    Orchestrates the complete fix application workflow:
    1. Gather error context and file content
    2. Submit to Claude for analysis and fix generation
    3. Apply Claude's fix with safety checks
    4. Verify compilation success
    5. Learn from results
    
    .PARAMETER FilePath
    Path to the file containing the compilation error
    
    .PARAMETER ErrorMessage
    The compilation error message from Unity
    
    .PARAMETER DryRun
    If specified, shows what would be done without applying changes
    
    .PARAMETER Force
    If specified, bypasses safety framework checks
    
    .EXAMPLE
    Invoke-ClaudeFixApplication -FilePath "Assets/Scripts/Player.cs" -ErrorMessage "CS0246: The type or namespace 'GameObject' could not be found"
    
    .EXAMPLE
    Invoke-ClaudeFixApplication -FilePath "Assets/Scripts/Player.cs" -ErrorMessage "CS0246: The type or namespace 'GameObject' could not be found" -DryRun
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_})]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$Force
    )
    
    Write-FixEngineLog -Message "Starting Claude-powered fix application for: $FilePath" -Level "INFO"
    Write-FixEngineLog -Message "Error: $ErrorMessage" -Level "DEBUG"
    
    $result = @{
        Success = $false
        FilePath = $FilePath
        ErrorMessage = $ErrorMessage
        ClaudeResponse = ""
        AppliedFix = ""
        BackupPath = ""
        ValidationResults = @()
        CompilationResult = @{}
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ExecutionTime = 0
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Step 1: Gather comprehensive error context
        Write-FixEngineLog -Message "Step 1: Gathering error context" -Level "DEBUG"
        $context = Get-ErrorContext -FilePath $FilePath -ErrorMessage $ErrorMessage
        
        # Step 2: Submit to Claude for analysis and fix generation
        Write-FixEngineLog -Message "Step 2: Submitting to Claude for analysis" -Level "DEBUG"
        $claudeResult = Submit-ErrorToClaude -Context $context
        
        if (-not $claudeResult.Success) {
            $result.Message = "Failed to get fix from Claude: $($claudeResult.Error)"
            Write-FixEngineLog -Message $result.Message -Level "ERROR"
            return $result
        }
        
        $result.ClaudeResponse = $claudeResult.Response
        $suggestedFix = $claudeResult.ExtractedFix
        
        if (-not $suggestedFix) {
            $result.Message = "Claude did not provide a usable fix"
            Write-FixEngineLog -Message $result.Message -Level "WARN"
            return $result
        }
        
        $result.AppliedFix = $suggestedFix
        
        # Step 3: Safety framework validation
        if (-not $Force) {
            Write-FixEngineLog -Message "Step 3: Safety framework validation" -Level "DEBUG"
            $safetyResult = Test-ClaudeFixSafety -FilePath $FilePath -SuggestedFix $suggestedFix -ClaudeResponse $claudeResult.Response
            
            if (-not $safetyResult.IsSafe) {
                $result.Message = "Safety check failed: $($safetyResult.Reason)"
                Write-FixEngineLog -Message $result.Message -Level "WARN"
                return $result
            }
        }
        
        # Step 4: Apply fix or perform dry run
        if ($DryRun) {
            Write-FixEngineLog -Message "Dry run mode: Fix would be applied" -Level "INFO"
            $result.Success = $true
            $result.Message = "Dry run successful - Claude's fix would be applied"
            $result.PreviewContent = Apply-FixToContent -FilePath $FilePath -Fix $suggestedFix -Preview
        } else {
            Write-FixEngineLog -Message "Step 4: Applying Claude's fix" -Level "INFO"
            $applyResult = Apply-ClaudeFix -FilePath $FilePath -Fix $suggestedFix
            
            if ($applyResult.Success) {
                $result.BackupPath = $applyResult.BackupPath
                
                # Step 5: Compilation verification
                Write-FixEngineLog -Message "Step 5: Verifying compilation" -Level "DEBUG"
                $compilationResult = Test-PostFixCompilation -FilePath $FilePath -OriginalError $ErrorMessage
                $result.CompilationResult = $compilationResult
                
                if ($compilationResult.Success) {
                    $result.Success = $true
                    $result.Message = "Fix applied successfully and compilation verified"
                    Write-FixEngineLog -Message "Claude fix applied successfully!" -Level "INFO"
                } else {
                    $result.Success = $false
                    $result.Message = "Fix applied but compilation still has errors"
                    Write-FixEngineLog -Message "Fix applied but compilation verification failed" -Level "WARN"
                    
                    # Optionally rollback here
                    # Restore-FixFromBackup -BackupPath $result.BackupPath
                }
            } else {
                $result.Message = "Failed to apply Claude's fix: $($applyResult.Error)"
                Write-FixEngineLog -Message $result.Message -Level "ERROR"
            }
        }
        
        # Step 6: Send results to learning module
        Write-FixEngineLog -Message "Step 6: Recording results for learning" -Level "DEBUG"
        Record-FixAttempt -Context $context -ClaudeResponse $claudeResult.Response -Result $result
        
    }
    catch {
        Write-FixEngineLog -Message "Exception in Claude fix application: $_" -Level "ERROR"
        $result.Message = "Exception during fix application: $_"
    }
    finally {
        $stopwatch.Stop()
        $result.ExecutionTime = $stopwatch.ElapsedMilliseconds
        Write-FixEngineLog -Message "Fix application completed in $($result.ExecutionTime)ms" -Level "DEBUG"
    }
    
    return $result
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzogkJwyN1Fxft+n8YK1cK9R9
# wD2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUIBZEiKWeBjAqrVovM7RbK8EWeDAwDQYJKoZIhvcNAQEBBQAEggEALqlk
# cyj1t31ebFe8dcUblx7VjSpMZmNFwgMC/AomSbCmxxY5AKzfc7w5LQG2RO35Fhlv
# 9IwRJZioH4Hf5TmNo/9rnrZg3nwnq9l408sOW9U1QMB6/UZJiw4Vh0mZaeK9oE5Z
# nKMPglMsprDtmGF3ddIaWOPSbFDLxsAWs98nZ7KYYXkw94FdlhuU4z7ylSd8V/4d
# Kw2yjvbpzAKhcecx6u2YD3ZldBPFK48etovMLVmbfCu3mYNtgt5B4cvh5BvL7yKK
# x6d/5FVqsKmaTkHOkJ+JQ7FwgWTBdzzZjRvauHr6mo7YP8XcTnWVUoW/kbKze3c0
# QUwgui+yRf3ND7z6VQ==
# SIG # End signature block
