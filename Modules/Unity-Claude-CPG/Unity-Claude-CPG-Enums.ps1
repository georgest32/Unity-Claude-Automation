# Unity-Claude-CPG Enum Definitions
# These enums need to be loaded before the module to be available in tests

# Node type enumeration
enum CPGNodeType {
    Module
    Function
    Class
    Method
    Variable
    Parameter
    File
    Property
    Field
    Namespace
    Interface
    Enum
    Constant
    Label
    Comment
    Unknown
}

# Edge type enumeration (must match Unity-Claude-CPG.psm1)
enum CPGEdgeType {
    Calls           # Function/method calls
    Uses            # Variable usage
    Imports         # Module imports
    Extends         # Class inheritance
    Implements      # Interface implementation
    DependsOn       # General dependency
    References      # Object references
    Assigns         # Variable assignment
    Returns         # Return values
    Throws          # Exception throwing
    Catches         # Exception handling
    Contains        # Containment relationship
    Follows         # Control flow
    DataFlow        # Data flow
    Overrides       # Method overriding
}

# Edge direction enumeration
enum EdgeDirection {
    Forward
    Backward
    Bidirectional
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC22AxuPpsJPuMn
# 6VbhkfEIzTx9r7R5uy+DusPx72jyh6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGQ2jmZPYMCG27+G43O9Sl8T
# elkYoDiT8WzzbribbJEIMA0GCSqGSIb3DQEBAQUABIIBAGgrWnScKKFnwi2+fP2j
# yjiFzvzGNcjxgOpxQr7A4PdT/Xhyk//p22lg0lqpGOwsmWVdIb2CSuvjpkeVq3VL
# fXtCGY20N7S884qP6Ru/SYIEGD/uHYCsYwclGahS8x9hW+lTCilCjZrngq5IZUc1
# TzfXxicfL3VBClkiFsPBCrrZE2uGLmVjaHY4h0KMjV3yyuyUfeVfqK6YM/RdMgRr
# e0WzAfqCtmt/6JBgxz1V4HU9dr2RTj2S7EgIxEylUTK/UrWBWEbT6Oz4C6BLH7DT
# fCcR8FzVEtz6lGIoUH0+LzXDANHnLADMpG0Yt8FCdbdBf6eezOu2t5yfDid0GjAg
# /G4=
# SIG # End signature block
