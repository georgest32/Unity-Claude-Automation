cd 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

# Clean and reload
Get-Module Unity-Claude* | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1' -Force -Global
Import-Module '.\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1' -Force

# Create a simple test graph
$testCode = {
    class Singleton {
        static [Singleton] $instance
        hidden Singleton() { }
        static [Singleton] GetInstance() {
            if (-not [Singleton]::instance) {
                [Singleton]::instance = [Singleton]::new()
            }
            return [Singleton]::instance
        }
    }
    
    function Get-UserData {
        param([int]$id)
        return @{ Id = $id; Name = 'Test' }
    }
}

$g = ConvertTo-CPGFromScriptBlock -ScriptBlock $testCode -Verbose:$false
Write-Host 'Graph nodes:' $g.Nodes.Values.Count

# Debug what nodes we have
Write-Host 'Node types:'
$g.Nodes.Values | ForEach-Object { $_.Type } | Group-Object | Select-Object Name, Count

# Test that the live view works
Write-Host ''
Write-Host 'Testing live view of Nodes.Values:'
$nodeCount1 = $g.Nodes.Values.Count
Write-Host "  Initial count: $nodeCount1"

# Test pattern detection with verbose
$VerbosePreference = 'Continue'
$patterns = Find-DesignPatterns -Graph $g -Verbose
Write-Host ''
Write-Host 'Patterns found:' $patterns.Count
if ($patterns) {
    $patterns | ForEach-Object { Write-Host "  Pattern: $($_.Type) Confidence: $($_.Confidence)" }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAoimEuj/FFTZ3B
# ByrJX+XpyHPLLjp0egJ+7GcSoapjx6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINL/3mBc9oMXRCPqrenr5/pV
# /Qu3c3zLhhNDT0cxPaPoMA0GCSqGSIb3DQEBAQUABIIBAGmaRzetheEBEqLQDsgT
# KlLUQAOwmZx4toMPvbKcrJsLRszojsKR2Hh10+thFqO4/gku/0mSZiXnSobGzYGV
# 6eAODdQbIJr2MiNC6H4Gi1L2m4+vHteszFsGNp3I/dYcq/bb++6YtM6zE0rESlwH
# gXtJkPtjVvoyfDUCON3jHk4wwX3SdyGK4snRaDKdo6sdkzg7+6SrPYLaOpcFTJOD
# 36AQIdQglZBwR/Yn1c1sprPhQDAj8f1ZeXj8559tDx38imLPfex/8x9SLu8xwb1l
# oV7iu8b/1FFmXkhdV+jO8MZVACzzc4A5WQ0ksu9wgJLicDaam7sQOHyfYf0oZKrE
# ReU=
# SIG # End signature block
