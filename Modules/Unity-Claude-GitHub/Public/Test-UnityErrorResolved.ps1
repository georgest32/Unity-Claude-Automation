function Test-UnityErrorResolved {
    <#
    .SYNOPSIS
    Tests if a Unity error associated with a GitHub issue has been resolved
    
    .DESCRIPTION
    Checks Unity compilation logs and error patterns to determine if an error
    that was previously reported in a GitHub issue has been resolved
    
    .PARAMETER IssueNumber
    GitHub issue number to check
    
    .PARAMETER ErrorSignature
    Unity error signature/hash to look for
    
    .PARAMETER UnityLogPath
    Path to Unity Editor.log file
    
    .PARAMETER CurrentErrorsPath
    Path to current_errors.json file
    
    .PARAMETER CheckCompilationSuccess
    Also check if Unity compilation succeeded without any errors
    
    .PARAMETER Owner
    Repository owner (for getting issue details)
    
    .PARAMETER Repository
    Repository name (for getting issue details)
    
    .EXAMPLE
    Test-UnityErrorResolved -IssueNumber 123 -ErrorSignature "CS0246_MissingType" -UnityLogPath "C:\Users\user\AppData\Local\Unity\Editor\Editor.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,
        
        [string]$ErrorSignature,
        
        [string]$UnityLogPath = "C:\Users\$env:USERNAME\AppData\Local\Unity\Editor\Editor.log",
        
        [string]$CurrentErrorsPath = ".\current_errors.json",
        
        [switch]$CheckCompilationSuccess,
        
        [string]$Owner,
        
        [string]$Repository
    )
    
    try {
        $resolutionResult = [PSCustomObject]@{
            IssueNumber = $IssueNumber
            IsResolved = $false
            ResolutionConfidence = 0.0
            Indicators = @()
            ErrorStillPresent = $false
            CompilationSucceeded = $false
            LastCompilationTime = $null
            ResolutionDetails = ""
        }
        
        # Get issue details if owner/repo provided
        $issueDetails = $null
        if ($Owner -and $Repository) {
            try {
                $issueDetails = Get-GitHubIssueStatus -Owner $Owner -Repository $Repository -IssueNumber $IssueNumber
                
                # Extract error signature from issue if not provided
                if (-not $ErrorSignature -and $issueDetails.Title) {
                    # Try to extract error code from title
                    if ($issueDetails.Title -match '(CS\d{4})') {
                        $ErrorSignature = $Matches[1]
                        Write-Verbose "Extracted error signature from issue title: $ErrorSignature"
                    }
                }
            } catch {
                Write-Warning "Could not get issue details: $_"
            }
        }
        
        # Check current errors file
        if (Test-Path $CurrentErrorsPath) {
            Write-Verbose "Checking current errors file: $CurrentErrorsPath"
            $currentErrors = Get-Content $CurrentErrorsPath -Raw | ConvertFrom-Json
            
            # Look for the error signature in current errors
            $errorFound = $false
            if ($ErrorSignature) {
                foreach ($error in $currentErrors.errors) {
                    if ($error.errorCode -eq $ErrorSignature -or 
                        $error.message -like "*$ErrorSignature*" -or
                        $error.signature -eq $ErrorSignature) {
                        $errorFound = $true
                        $resolutionResult.Indicators += "Error signature still present in current_errors.json"
                        break
                    }
                }
            }
            
            $resolutionResult.ErrorStillPresent = $errorFound
            
            if (-not $errorFound -and $ErrorSignature) {
                $resolutionResult.Indicators += "Error signature not found in current_errors.json"
                $resolutionResult.ResolutionConfidence += 0.4
            }
            
            # Check if compilation succeeded
            if ($currentErrors.compilationSucceeded -eq $true -or $currentErrors.errorCount -eq 0) {
                $resolutionResult.CompilationSucceeded = $true
                $resolutionResult.Indicators += "Unity compilation succeeded"
                $resolutionResult.ResolutionConfidence += 0.3
            }
            
            $resolutionResult.LastCompilationTime = $currentErrors.timestamp
        }
        
        # Check Unity log file
        if (Test-Path $UnityLogPath) {
            Write-Verbose "Checking Unity log file: $UnityLogPath"
            
            # Get last 1000 lines of log
            $logContent = Get-Content $UnityLogPath -Tail 1000
            
            # Look for compilation success indicators
            $compilationSuccess = $false
            $recentCompilation = $false
            
            foreach ($line in $logContent) {
                if ($line -match "Compilation succeeded") {
                    $compilationSuccess = $true
                    $resolutionResult.Indicators += "Found 'Compilation succeeded' in Unity log"
                }
                
                if ($line -match "Refresh completed in .* seconds") {
                    $recentCompilation = $true
                }
                
                # Check if error signature appears in recent log
                if ($ErrorSignature -and $line -like "*$ErrorSignature*") {
                    $resolutionResult.ErrorStillPresent = $true
                    $resolutionResult.Indicators += "Error signature found in recent Unity log"
                }
            }
            
            if ($compilationSuccess -and $recentCompilation) {
                $resolutionResult.CompilationSucceeded = $true
                $resolutionResult.ResolutionConfidence += 0.2
            }
        }
        
        # Check if issue has resolution labels
        if ($issueDetails -and $issueDetails.Labels) {
            $resolutionLabels = @("fixed", "resolved", "completed", "verified", "tested")
            foreach ($label in $issueDetails.Labels) {
                foreach ($resLabel in $resolutionLabels) {
                    if ($label -like "*$resLabel*") {
                        $resolutionResult.Indicators += "Issue has resolution label: $label"
                        $resolutionResult.ResolutionConfidence += 0.1
                        break
                    }
                }
            }
        }
        
        # Determine final resolution status
        if ($CheckCompilationSuccess) {
            # Strict mode: require compilation success AND no error present
            $resolutionResult.IsResolved = $resolutionResult.CompilationSucceeded -and (-not $resolutionResult.ErrorStillPresent)
        } else {
            # Normal mode: error not present is sufficient
            $resolutionResult.IsResolved = -not $resolutionResult.ErrorStillPresent
        }
        
        # Adjust confidence based on available data
        if (-not $ErrorSignature) {
            $resolutionResult.ResolutionConfidence *= 0.5  # Lower confidence without specific signature
            $resolutionResult.Indicators += "No specific error signature provided (lower confidence)"
        }
        
        # Cap confidence at 1.0
        if ($resolutionResult.ResolutionConfidence -gt 1.0) {
            $resolutionResult.ResolutionConfidence = 1.0
        }
        
        # Build resolution details
        if ($resolutionResult.IsResolved) {
            $resolutionResult.ResolutionDetails = "Error appears to be resolved. "
            if ($resolutionResult.CompilationSucceeded) {
                $resolutionResult.ResolutionDetails += "Unity compilation succeeded. "
            }
            if (-not $resolutionResult.ErrorStillPresent) {
                $resolutionResult.ResolutionDetails += "Error signature no longer present. "
            }
        } else {
            $resolutionResult.ResolutionDetails = "Error not yet resolved. "
            if ($resolutionResult.ErrorStillPresent) {
                $resolutionResult.ResolutionDetails += "Error signature still present in logs. "
            }
            if (-not $resolutionResult.CompilationSucceeded) {
                $resolutionResult.ResolutionDetails += "Unity compilation has not succeeded. "
            }
        }
        
        $resolutionResult.ResolutionDetails += "Confidence: $([Math]::Round($resolutionResult.ResolutionConfidence * 100, 1))%"
        
        Write-Verbose "Resolution check complete: IsResolved=$($resolutionResult.IsResolved), Confidence=$($resolutionResult.ResolutionConfidence)"
        return $resolutionResult
        
    } catch {
        Write-Error "Failed to test Unity error resolution: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Test-UnityErrorResolved
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBhhvqu8OOicwmC
# ReaRWMUyiK3i+JUUfpPuIR5ZOhSm5KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIInrzhcof4yJivaizcuEVFvS
# VESrutJEOMBK8S4JlI5EMA0GCSqGSIb3DQEBAQUABIIBABgUBaydasrUC9hMooUk
# Frm08nL2jjSeSmvdmj4PxL2ZUnMxIqXMWDZNyzRjtNVnUcSQptJF9FHI9lzy+VqT
# 9Y5ZaHMwKWoVVirQnBtX2Vibtzqb7JJlbXCB8HhFzIvEJuc7A79gBAWECFE6zXmh
# M07aFX5SbpM0kmfy6kYWagM06RTKiLmlOeD+DBSbSFkwF+HzkI+UvaMd5hs9BhwF
# QuiRJk5rQuzChSx7s1VRnvbe4wn5/xGZ/udKdZNqBw8Zkdl50aKNBBpAcM8VgRF+
# rhnA3c2FoXYNh7Y5HQoLUpkRPDg2ta3RdFFR8Djuew2VaNq4Uxfw3id3nX+YaAdh
# xdo=
# SIG # End signature block
