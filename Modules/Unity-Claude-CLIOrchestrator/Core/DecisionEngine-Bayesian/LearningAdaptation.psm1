# LearningAdaptation.psm1
# Phase 7 Day 3-4 Hours 5-8: Bayesian Learning and Adaptation
# Learning from outcomes and persistent storage management
# Date: 2025-08-25

#region Learning and Adaptation

# Update Bayesian learning based on outcome
function Update-BayesianLearning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter()]
        [double]$ObservedConfidence = 0.0,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionLog "Updating Bayesian learning for $DecisionType - Success: $Success" "DEBUG"
    
    try {
        # Update outcome history
        $history = $script:BayesianConfig.OutcomeHistory[$DecisionType]
        if ($history) {
            $history.Total++
            if ($Success) {
                $history.Success++
            } else {
                $history.Failure++
            }
            
            # Apply decay to old observations
            if ($history.Total -gt 100) {
                $decay = $script:BayesianConfig.ConfidenceDecay
                $history.Success = [Math]::Floor($history.Success * $decay)
                $history.Failure = [Math]::Floor($history.Failure * $decay)
                $history.Total = $history.Success + $history.Failure
            }
        }
        
        # Update prior probabilities based on new evidence
        if ($history.Total -ge $script:BayesianConfig.MinimumSamples) {
            $currentPrior = $script:BayesianConfig.PriorProbabilities[$DecisionType]
            $observedRate = $history.Success / $history.Total
            $learningRate = $script:BayesianConfig.LearningRate
            
            # Exponential moving average update
            $newPrior = ($currentPrior * (1 - $learningRate)) + ($observedRate * $learningRate)
            $script:BayesianConfig.PriorProbabilities[$DecisionType] = [Math]::Round($newPrior, 4)
            
            Write-DecisionLog "Updated prior for $DecisionType from $currentPrior to $newPrior" "INFO"
        }
        
        # Persist learning to storage
        Save-BayesianLearning
        
        return @{
            Updated = $true
            DecisionType = $DecisionType
            NewStats = $history
            UpdatedPrior = $script:BayesianConfig.PriorProbabilities[$DecisionType]
        }
        
    } catch {
        Write-DecisionLog "Failed to update Bayesian learning: $($_.Exception.Message)" "ERROR"
        return @{
            Updated = $false
            Error = $_.Exception.Message
        }
    }
}

# Save Bayesian learning data to persistent storage
function Save-BayesianLearning {
    [CmdletBinding()]
    param()
    
    try {
        $data = @{
            PriorProbabilities = $script:BayesianConfig.PriorProbabilities
            OutcomeHistory = $script:BayesianConfig.OutcomeHistory
            LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = "1.0"
        }
        
        # Create directory if it doesn't exist
        $directory = Split-Path -Path $script:BayesianStoragePath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:BayesianStoragePath -Encoding UTF8
        Write-DecisionLog "Bayesian learning data saved successfully" "DEBUG"
        
    } catch {
        Write-DecisionLog "Failed to save Bayesian learning data: $($_.Exception.Message)" "ERROR"
    }
}

# Load Bayesian learning data from persistent storage
function Initialize-BayesianLearning {
    [CmdletBinding()]
    param()
    
    try {
        if (Test-Path $script:BayesianStoragePath) {
            $data = Get-Content -Path $script:BayesianStoragePath -Raw | ConvertFrom-Json
            
            # Update configuration with loaded data
            if ($data.PriorProbabilities) {
                foreach ($key in $data.PriorProbabilities.PSObject.Properties.Name) {
                    $script:BayesianConfig.PriorProbabilities[$key] = $data.PriorProbabilities.$key
                }
            }
            
            if ($data.OutcomeHistory) {
                foreach ($key in $data.OutcomeHistory.PSObject.Properties.Name) {
                    $history = $data.OutcomeHistory.$key
                    $script:BayesianConfig.OutcomeHistory[$key] = @{
                        Success = $history.Success
                        Failure = $history.Failure
                        Total = $history.Total
                    }
                }
            }
            
            Write-DecisionLog "Bayesian learning data loaded from $($data.LastUpdate)" "INFO"
            return $true
        } else {
            Write-DecisionLog "No existing Bayesian learning data found - using defaults" "INFO"
            return $false
        }
        
    } catch {
        Write-DecisionLog "Failed to load Bayesian learning data: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

#endregion

# Export learning and adaptation functions
Export-ModuleMember -Function Update-BayesianLearning, Save-BayesianLearning, Initialize-BayesianLearning
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAzZ9/HVAi58WB9
# VXVbD6jWf9NRYYb44virxSP5Km3WLKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINs66IGyTDDaflruzKJpMQln
# yapsIKA8gsNXXfpIDMqkMA0GCSqGSIb3DQEBAQUABIIBAFzjMxma/x5eIsrY8uyz
# hSJnjN5AZMb2G+pyIYqPoaDtRdKGgvY2g5nhnmMfdUQ1ANAfGLLxasrTVuU8++EN
# l+1lSu+SXM8PvrkMybv4D1RWr76HcKe61p2hXYqDtx2sEwrTUZdFXO6pHQV2qvnN
# cfQpeg9THSvwt+VoZItAUt++UPYSxMCA7KVkYWXKxHjYckjraVHRsJnImkLBlZJH
# ofNCiiJMjDB9Yc34vnZFp/NunRJFT0fjeZ59qEpecDZkbbTfkAYe7FarR8blVH+F
# Sgwcmm5iAwFV39ATqbkvzNYrcu//JUCUv6BoTldhLJdBmAFT17eVf9RKNMkruMTO
# IrE=
# SIG # End signature block
