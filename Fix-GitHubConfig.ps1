# Fix-GitHubConfig.ps1
# Updates the GitHub configuration with repository settings
# Uses correct format: repositories as a hashtable with "owner/repo" keys

Import-Module ".\Modules\Unity-Claude-GitHub" -Force

Write-Host "Updating GitHub configuration..." -ForegroundColor Cyan

# Get current config
$currentConfig = Get-GitHubIntegrationConfig

# Create new configuration with proper structure
$newConfig = @{
    version = "1.0.0"
    global = $currentConfig.global
    repositories = @{
        "georgest32/Unity-Claude-Automation" = @{
            owner = "georgest32"
            name = "Unity-Claude-Automation"
            isDefault = $true
            priority = 10
            unityProjects = @(
                @{
                    name = "Sound-and-Shoal"
                    pathPattern = "*Sound-and-Shoal*"
                    category = "main"
                }
            )
            categories = @{
                graphics = @{
                    labels = @("graphics", "shader", "rendering")
                    priority = 2
                }
                networking = @{
                    labels = @("networking", "multiplayer")
                    priority = 2
                }
                physics = @{
                    labels = @("physics", "collision")
                    priority = 2
                }
                ui = @{
                    labels = @("ui", "interface")
                    priority = 1
                }
            }
            labels = @("unity", "automation")
        }
    }
    unityProjects = $currentConfig.unityProjects
    templates = $currentConfig.templates
    environments = $currentConfig.environments
}

# Save the updated config
Set-GitHubIntegrationConfig -Config $newConfig

# Verify it saved
$verifyConfig = Get-GitHubIntegrationConfig
Write-Host ""
Write-Host "Configuration updated!" -ForegroundColor Green

# Check repositories
if ($verifyConfig.repositories) {
    $repoCount = ($verifyConfig.repositories | Get-Member -MemberType NoteProperty).Count
    Write-Host "Repositories configured: $repoCount" -ForegroundColor White
    
    # Get first repository
    $repoKey = ($verifyConfig.repositories | Get-Member -MemberType NoteProperty | Select-Object -First 1).Name
    if ($repoKey) {
        $repo = $verifyConfig.repositories.$repoKey
        Write-Host "Default repository: $repoKey" -ForegroundColor Cyan
        if ($repo.unityProjects) {
            Write-Host "Unity projects: $($repo.unityProjects.Count)" -ForegroundColor Gray
        }
        if ($repo.categories) {
            $catNames = ($repo.categories | Get-Member -MemberType NoteProperty).Name -join ', '
            Write-Host "Categories: $catNames" -ForegroundColor Gray
        }
    }
}

# Test repository access
Write-Host ""
Write-Host "Testing repository access..." -ForegroundColor Yellow
try {
    $access = Test-GitHubRepositoryAccess -Owner "georgest32" -Repository "Unity-Claude-Automation" -ErrorAction Stop
    if ($access.Success) {
        Write-Host "Repository access confirmed!" -ForegroundColor Green
        Write-Host "  Permissions: $($access.Permissions -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "Could not access repository: $($access.Error)" -ForegroundColor Red
        Write-Host "  Note: Create the repository on GitHub if it doesn't exist" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error testing repository: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Run the test suite to verify everything works:" -ForegroundColor Cyan
Write-Host '  .\Test-Week9-AdvancedFeatures.ps1' -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCArc8A6F4kobVJk
# 8qm+MFFmDkJ7rD2aCAZR6ht3XlDYkaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEqmYry1/5dg0M2Smku2JGPp
# 89s9EYTgzJYQX33PJNA7MA0GCSqGSIb3DQEBAQUABIIBAHJ6oo4XHGSVLSJ7/Awy
# TLjkHbBSWXGnLzYH01j+Xca9PnjMKkiL49dxqxlj8V3sB0eOrnS+1yK6cx7s9hzB
# oYYvTmaAb6PsyVVFQw95RYPLpTfxilam6ExU7hLHkO+SYuon2BrOb8f1uSwoTKqd
# lUI0O6TeoauAYtmds488CQ1JQhK+J+/RWobS+SD1XqnMRDMZnLXOUFXRtxOTPxTJ
# r1/gd/dOBaN0hNEk1HHATAYQUE53KEHOCLemNk4jZUlMIP5Kqgb73gbHwLzCKtir
# wul0dnzH3OrHoqxoadZEURFQdMtMkl21uK/KwcxxH1rab2WojiKct0yR0n1Dx2OW
# 0s8=
# SIG # End signature block
