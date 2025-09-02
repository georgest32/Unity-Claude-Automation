function Get-UnityErrorTemplateType {
    <#
    .SYNOPSIS
    Determines the appropriate template type for a Unity error
    
    .DESCRIPTION
    Analyzes Unity error properties to determine the most appropriate
    issue template type for GitHub issue generation.
    
    .PARAMETER UnityError
    Unity error object to analyze
    
    .EXAMPLE
    $templateType = Get-UnityErrorTemplateType -UnityError $error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UnityError
    )
    
    begin {
        Write-Debug "GET-ERROR-TYPE: Starting Unity error template type detection"
    }
    
    process {
        try {
            # Extract error information for classification
            $errorText = $UnityError.ErrorText
            $errorCode = $UnityError.Code
            $errorMessage = $UnityError.Message
            
            Write-Debug "GET-ERROR-TYPE: Analyzing error - Code: $errorCode, Message: $errorMessage"
            
            # Parse error text if individual fields not available
            if (-not $errorCode -and $errorText) {
                if ($errorText -match 'error\s+(\w+):') {
                    $errorCode = $Matches[1]
                    Write-Debug "GET-ERROR-TYPE: Extracted error code from text: $errorCode"
                }
            }
            
            if (-not $errorMessage -and $errorText) {
                if ($errorText -match 'error\s+\w+:\s*(.+)$') {
                    $errorMessage = $Matches[1]
                    Write-Debug "GET-ERROR-TYPE: Extracted error message from text"
                }
            }
            
            # Classification logic
            $templateType = "compilationError"  # Default
            
            # Check for null reference errors
            if ($errorMessage -match 'null reference|NullReferenceException|Object reference not set' -or
                $errorCode -match 'NullReference') {
                $templateType = "nullReferenceError"
                Write-Debug "GET-ERROR-TYPE: Classified as null reference error"
            }
            # Check for compilation errors (CS codes)
            elseif ($errorCode -match '^CS\d+' -or $errorText -match 'compilation failed|syntax error|expected|missing') {
                $templateType = "compilationError"
                Write-Debug "GET-ERROR-TYPE: Classified as compilation error"
            }
            # Check for runtime errors
            elseif ($errorMessage -match 'exception|runtime|execution|ArgumentException|InvalidOperationException' -or
                    $errorText -match 'runtime error|execution failed') {
                $templateType = "runtimeError"
                Write-Debug "GET-ERROR-TYPE: Classified as runtime error"
            }
            # Unity-specific errors
            elseif ($errorMessage -match 'MonoBehaviour|GameObject|Component|Transform|missing component') {
                $templateType = "runtimeError"
                Write-Debug "GET-ERROR-TYPE: Classified as Unity runtime error"
            }
            
            Write-Debug "GET-ERROR-TYPE: Final template type: $templateType"
            return $templateType
        }
        catch {
            Write-Warning "Failed to determine template type: $_"
            Write-Debug "GET-ERROR-TYPE: Error in classification, returning default"
            return "compilationError"  # Safe default
        }
    }
    
    end {
        Write-Debug "GET-ERROR-TYPE: Completed Get-UnityErrorTemplateType"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChEqoY5GJ3q6t6
# fuS7zcjg0TvqLOjgl/0qKhe9KirdtqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICbGLoO/j8PAc4CrlLndUwP3
# 5YS0RAfanaoAMmgPp+DPMA0GCSqGSIb3DQEBAQUABIIBAKGwuJOVxqQJZK7I8jzR
# sZNLDzaPu8uzRdSb/mdUNrT07xZq6bgBkcqUzQqgoCA7fdtQC1mHNvZAeirrXz4+
# af7kIdXMzbk2zQoQOgigyaFY3LoQbW4fiNP52uV1n46SqtkNAw88JZ2Avhv5VFAb
# QwOnmb9rKa2YkkQErgIQXCGFMLA3JuXk48xosP53dRFnSEVnse6mON6kcOLlDUav
# EAwK69nrMM5GHJPrnrr0O+q9DkKjp+budhoKS5bXil+j5Ec2QJuTHX2+w8RYaRM0
# GutmBbK6u7lW+LUdYCjOVK8OF9aE3T6n2UdcUGQrjkwAwz6Jn5m6ULVV9K9YmYyV
# qVs=
# SIG # End signature block
