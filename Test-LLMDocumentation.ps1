# Test LLM Documentation Generation
Import-Module "$PSScriptRoot\Modules\Unity-Claude-LLM\Unity-Claude-LLM.psd1" -Force

# Create a sample function for documentation
$sampleFunction = @'
function Get-SystemHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [int]$TimeoutSeconds = 30,
        [switch]$IncludeDetails
    )
    
    try {
        $pingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
        if ($pingResult) {
            $services = Get-Service -ComputerName $ComputerName | Where-Object Status -eq 'Running'
            return @{
                Status = 'Healthy'
                ServicesRunning = $services.Count
                Timestamp = Get-Date
            }
        } else {
            return @{Status = 'Unreachable'}
        }
    }
    catch {
        return @{Status = 'Error'; Message = $_.Exception.Message}
    }
}
'@

Write-Host "Generating documentation for sample function..." -ForegroundColor Cyan

# Generate documentation for the function
$prompt = New-DocumentationPrompt -Type 'Function' -Code $sampleFunction -Requirements @('Include parameter validation details', 'Add error handling explanation')
$result = Invoke-OllamaGenerate -Prompt $prompt -MaxTokens 2048

if ($result.Success) {
    Write-Host "Documentation generated successfully!" -ForegroundColor Green
    Write-Host "--- GENERATED DOCUMENTATION ---" -ForegroundColor Yellow
    Write-Host $result.Response
    Write-Host "--- END DOCUMENTATION ---" -ForegroundColor Yellow
    
    # Save to file
    $docFile = "$PSScriptRoot\Sample-Function-Documentation.md"
    $result.Response | Out-File -FilePath $docFile -Encoding UTF8
    Write-Host "Documentation saved to: $docFile" -ForegroundColor Green
    
    return $result
} else {
    Write-Host "Documentation generation failed: $($result.Error)" -ForegroundColor Red
    return $null
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEctrIF/4a/9eE
# vZclnHdh7Ju6g8G7EGhTa8CUg84fAaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMJC829SObTn8zTKCzwmZtd7
# 3bfdImzTcmkwSAA7gvnnMA0GCSqGSIb3DQEBAQUABIIBABJEFwHVDmvV4/leCKr8
# mdAo9mF9a9AJHkfk6OL4JPjqT0TpL5R0w5MbMfduCqWUDImlR23x1JAAD4DE3t6W
# tkVy7SBBYWtUxCN40jGf9k6EdYsM67N71eO68sVV7xgpLhz1GepeqKq1TZGfzvNk
# OvHiVoZj/vEU8Gd7STfSwwAlIqVt/3pzrCgCRqxfmV0vK7Kz/zBUbMwqQ3hp3fZm
# kev3rTL6u1Z9oI3KfJ6oqlwqZczeF4yQMjpyJ9MhBxmm8WAGKndF+VcEWbkhYDln
# g+hb425ppcl/3JoawVVpo6W/O7nbUNd/5S064G3ySMiWU4dKtAmb7pWdSs4cOyqT
# kh8=
# SIG # End signature block
