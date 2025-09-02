# Remove-SignatureBlocks.ps1
# Remove signature blocks from refactored modules

param(
    [string]$ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
)

Write-Host "Removing signature blocks from refactored modules..." -ForegroundColor Cyan

# List of files to process
$filesToProcess = @(
    "$ModulePath\Unity-Claude-AutonomousAgent\Core\AgentLogging.psm1",
    "$ModulePath\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psm1",
    "$ModulePath\Unity-Claude-PredictiveAnalysis\Core\RiskAssessment.psm1",
    "$ModulePath\Unity-Claude-CPG\Core\DocumentationAccuracy.psm1"
)

$processedCount = 0
foreach ($file in $filesToProcess) {
    if (Test-Path $file) {
        Write-Host "Processing: $(Split-Path $file -Leaf)" -ForegroundColor Yellow
        
        $content = Get-Content $file
        $sigStart = -1
        
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match '^# SIG # Begin signature block') {
                $sigStart = $i
                break
            }
        }
        
        if ($sigStart -ge 0) {
            $newContent = $content[0..($sigStart-1)]
            $newContent | Out-File $file -Encoding UTF8
            Write-Host "  Signature block removed" -ForegroundColor Green
            $processedCount++
        } else {
            Write-Host "  No signature block found" -ForegroundColor Gray
        }
    } else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nProcessed $processedCount files successfully" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAJ+Jy6Rn5AtSjo
# HqAxIRhdq1EOmrwrKc0O5uKTgazl4aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHICsz3gYSXEsnORepgkjPNB
# MB9UrQLEVXYlo+/v5JlnMA0GCSqGSIb3DQEBAQUABIIBABjNqri5f+u7uKCc+oGH
# s+jFEItf67kaakHWkGgDfS3p25mo7vGZoaa2s4pr6EAro7kHx0gwKwdzg9xraNRg
# A0l5msLUdH6jks9312bHoJzJ/jNmlt7agL0kamhGZWaSFVCxku45qgwV8k0BCg+g
# sLYzSc30CjLzLL7y3LfDXzSvJL2FQdlWRUTR+afErm9q1CXa4vdzbF0zloMA9jfM
# Hg1U0fLr5CF2U7mGsneqrmC0X8LjU5VxTu6Mxdg7oemKmmB/YPojACZTYr9kSGhk
# yyA4F2aAU8xjRg3v4GE3vmUsVG07okwK9SxSHkYhtId7GsGClAX5/+xaW8RotGLm
# OmM=
# SIG # End signature block
