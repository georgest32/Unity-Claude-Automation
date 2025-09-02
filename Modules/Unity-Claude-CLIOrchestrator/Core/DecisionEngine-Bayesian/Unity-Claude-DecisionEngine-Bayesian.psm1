#
# Unity-Claude-DecisionEngine-Bayesian Main Module
# Refactored component-based Bayesian decision engine
#

# Module self-registration for session visibility
if (-not $ExecutionContext.SessionState.Module) {
    $ModuleName = 'DecisionEngine-Bayesian'
    if (-not (Get-Module -Name $ModuleName)) {
        # Module is being imported but not yet visible in session
        Write-Verbose "[$ModuleName] Ensuring module registration in session" -Verbose:$false
    }
} else {
    # Module context is properly established
    Write-Verbose "[$($ExecutionContext.SessionState.Module.Name)] Module context established" -Verbose:$false
}

Write-Verbose "[DecisionEngine-Bayesian] Loading components..." -Verbose

$ComponentsPath = $PSScriptRoot
$Components = @(
    'BayesianConfiguration.psm1',
    'BayesianInference.psm1', 
    'ConfidenceBands.psm1',
    'EnhancedPatternIntegration.psm1',
    'EntityRelationshipManagement.psm1',
    'LearningAdaptation.psm1',
    'PatternAnalysis.psm1',
    'TemporalContextTracking.psm1'
)

$LoadedComponents = 0
foreach ($Component in $Components) {
    $ComponentPath = Join-Path $ComponentsPath $Component
    if (Test-Path $ComponentPath) {
        try {
            . $ComponentPath
            $LoadedComponents++
            Write-Verbose "[DecisionEngine-Bayesian] Loaded component: $Component" -Verbose
        } catch {
            Write-Warning "[DecisionEngine-Bayesian] Failed to load component $Component : $($_.Exception.Message)"
        }
    } else {
        Write-Warning "[DecisionEngine-Bayesian] Component not found: $ComponentPath"
    }
}

Write-Verbose "[DecisionEngine-Bayesian] Loaded $LoadedComponents/$($Components.Count) components successfully" -Verbose

# Export functions as declared in manifest
Export-ModuleMember -Function @(
    'Invoke-BayesianDecisionAnalysis',
    'Get-BayesianConfidenceScore',
    'Update-BayesianPriors',
    'Calculate-PosteriorProbabilities',
    'Get-DecisionTreeAnalysis',
    'Invoke-MonteCarloSimulation',
    'Get-RiskAssessmentMatrix',
    'Calculate-ExpectedValue'
)

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD61aCNcFCvbdpq
# ujHEORQUMYTS+cMqhFb3MiF/kCkJdKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFly/rw6E0qelAhSOyS4lcDA
# xFl0xC+pVfp6DMAKYU7yMA0GCSqGSIb3DQEBAQUABIIBAHoMBE+fOwT9c3NcDUwD
# A5DtGxjiqGX5tWSgIRDnWrsOaMCPQD6ujgfUO7kuepLG9C8d+2ws3sk8q+e8nTb6
# SyJE1cCDx+Mt6Ooc/mLxCuHZLJIdQZ2M+Nd+qRCas88yUsjNicIgvj6m9BudkPSa
# ycQpoTru7pFNPIRkeMKjvMA7zghwHPtofJxC3l61KoCAKR7oKCXm2UK8eFHESWIF
# 7HxPs2GoDqHz1RUVrFgu5IixpU1jlfdCn2a7qk1JICG+yGA7wgHFaMlD+fl8FnMU
# A2mheboWMxtkDMbs43/m2PhvNnoZKI6/+KFPOjhrCZ02F+WlL3yrWleWjiBxrBaj
# t+Q=
# SIG # End signature block
