function Merge-GitHubConfiguration {
    <#
    .SYNOPSIS
    Merges GitHub configuration objects with deep property overrides
    
    .DESCRIPTION
    Recursively merges configuration objects, with override config taking precedence.
    Handles nested objects, arrays, and null values appropriately.
    
    .PARAMETER BaseConfig
    The base configuration object
    
    .PARAMETER OverrideConfig  
    The override configuration object
    
    .EXAMPLE
    $merged = Merge-GitHubConfiguration -BaseConfig $defaultConfig -OverrideConfig $userConfig
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$BaseConfig,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$OverrideConfig
    )
    
    begin {
        Write-Debug "MERGE-CONFIG: Starting configuration merge"
    }
    
    process {
        try {
            # Convert base config to hashtable for easier manipulation
            $result = $BaseConfig | ConvertTo-Json -Depth 20 | ConvertFrom-Json
            Write-Debug "MERGE-CONFIG: Created working copy of base configuration"
            
            # Recursively apply overrides
            $result = Merge-ConfigurationRecursive -Target $result -Source $OverrideConfig
            Write-Debug "MERGE-CONFIG: Recursive merge completed"
            
            return $result
        }
        catch {
            Write-Error "Failed to merge configurations: $_"
            throw
        }
    }
}

function Merge-ConfigurationRecursive {
    <#
    .SYNOPSIS
    Recursively merges configuration properties
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Target,
        
        [Parameter(Mandatory = $true)]
        $Source
    )
    
    Write-Debug "MERGE-RECURSIVE: Merging configuration level"
    
    # Get all properties from source
    $sourceProperties = $Source.PSObject.Properties
    
    foreach ($property in $sourceProperties) {
        $propertyName = $property.Name
        $sourceValue = $property.Value
        
        Write-Debug "MERGE-RECURSIVE: Processing property: $propertyName"
        
        # Check if target has this property
        if ($Target.PSObject.Properties[$propertyName]) {
            $targetValue = $Target.$propertyName
            
            # If both are objects (not arrays or primitives), recurse
            if ($targetValue -is [PSCustomObject] -and $sourceValue -is [PSCustomObject]) {
                Write-Debug "MERGE-RECURSIVE: Recursing into nested object: $propertyName"
                $Target.$propertyName = Merge-ConfigurationRecursive -Target $targetValue -Source $sourceValue
            }
            # If source is array, replace entirely (don't merge arrays)
            elseif ($sourceValue -is [Array]) {
                Write-Debug "MERGE-RECURSIVE: Replacing array property: $propertyName"
                $Target.$propertyName = $sourceValue
            }
            # For primitives, override
            else {
                Write-Debug "MERGE-RECURSIVE: Overriding primitive property: $propertyName = $sourceValue"
                $Target.$propertyName = $sourceValue
            }
        }
        else {
            # Property doesn't exist in target, add it
            Write-Debug "MERGE-RECURSIVE: Adding new property: $propertyName = $sourceValue"
            $Target | Add-Member -NotePropertyName $propertyName -NotePropertyValue $sourceValue -Force
        }
    }
    
    Write-Debug "MERGE-RECURSIVE: Completed merge for this level"
    return $Target
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDRdLe1n+0oEjbz
# CbjvwCgBAiGLLtRBxDc8NJcCMfFI46CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF4ZGAIwDALxp/dw7QRUJwbb
# 4aWs9zMSK0XBYWtkPeLlMA0GCSqGSIb3DQEBAQUABIIBAAlTwK7sb95I3uB4jKwr
# aJ52T1xFcpLuugK/XLBIwjiBuLMw7pvh9Lr3PqciINl9A9T6PH0aBT5MyW4432ZO
# TgmP2n8AHs0Yf994VOeA6YvD6TFnrFbk+gU+k/PGLpCiSNBSzU/UY37EKpGbaVXY
# U5viQcQHHEe+Gz383MtONxTL5wE3/krcY/XaNUTWiFYO4hXR+5iGksc8zL+l7I78
# UbzAPPirRtJCGV55c34bs1wYE+qyH/IV3bZDVNyxnIl2l39CzFxHN/tL6GQNtnxU
# qTzM68P7LJDJTp52ICrspnoHB/DKmdLuQQszEYlZar7HxInTEUW0np/+E91beDck
# i6s=
# SIG # End signature block
