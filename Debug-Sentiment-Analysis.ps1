# Debug-Sentiment-Analysis.ps1
# Debug sentiment analysis for CS0246 text

Write-Host "Debug Sentiment Analysis" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

$testText = "CS0246: The type or namespace name could not be found"

Write-Host ""
Write-Host "Test Text: $testText" -ForegroundColor Yellow
Write-Host ""

# Check sentiment terms
$sentimentIndicators = @{
    "Positive" = @{
        Terms = @("success", "working", "correct", "good", "excellent", "perfect", "fixed", "resolved", "completed")
        Weight = 1.0
    }
    
    "Negative" = @{
        Terms = @("error", "failed", "broken", "issue", "problem", "incorrect", "wrong", "bad")
        Weight = -1.0
    }
    
    "Neutral" = @{
        Terms = @("information", "note", "update", "change", "modify", "adjust", "consider")
        Weight = 0.0
    }
}

Write-Host "Sentiment Analysis Debug:" -ForegroundColor Cyan
$sentimentScore = 0.0
$termCounts = @{
    Positive = 0
    Negative = 0
    Neutral = 0
}

foreach ($category in $sentimentIndicators.Keys) {
    Write-Host "  $category terms:" -ForegroundColor Yellow
    foreach ($term in $sentimentIndicators[$category].Terms) {
        $matches = [regex]::Matches($testText, "\b$term\b", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($matches.Count -gt 0) {
            Write-Host "    MATCH: '$term' ($($matches.Count) times)" -ForegroundColor Green
            $termCounts[$category] += $matches.Count
            $sentimentScore += $matches.Count * $sentimentIndicators[$category].Weight
        } else {
            Write-Host "    NO MATCH: '$term'" -ForegroundColor Red
        }
    }
}

# Calculate final sentiment
$totalTerms = $termCounts.Positive + $termCounts.Negative + $termCounts.Neutral
if ($totalTerms -gt 0) {
    $sentimentScore = $sentimentScore / $totalTerms
}

$finalSentiment = if ($sentimentScore -gt 0.2) { "Positive" } 
                 elseif ($sentimentScore -lt -0.2) { "Negative" } 
                 else { "Neutral" }

Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Positive terms found: $($termCounts.Positive)" -ForegroundColor Gray
Write-Host "  Negative terms found: $($termCounts.Negative)" -ForegroundColor Gray  
Write-Host "  Neutral terms found: $($termCounts.Neutral)" -ForegroundColor Gray
Write-Host "  Total terms: $totalTerms" -ForegroundColor Gray
Write-Host "  Raw score: $sentimentScore" -ForegroundColor Gray
Write-Host "  Final sentiment: $finalSentiment" -ForegroundColor Gray
Write-Host "  Expected: Negative" -ForegroundColor Gray

if ($finalSentiment -eq "Negative") {
    Write-Host ""
    Write-Host "SUCCESS: Correctly identified as Negative" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILURE: Expected Negative, got $finalSentiment" -ForegroundColor Red
}

Write-Host ""
Write-Host "Debug complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMq7ZZnEpw3t+zKeJE+C9xPLD
# /SGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUvN4r1v+TjULRaWomHvPu10Ob30kwDQYJKoZIhvcNAQEBBQAEggEADMRW
# 1c4QMdSvD6ofZTfQx6OCqz/yilKdHJhJYbLC67S8hBupMHjLlhED/uZov70MQT3V
# Ks8xaqRi2Uf2OgfhDPdBf4en5Ub95R0+Rq+kO8M0j4uqkJS/mwrPwbtBdJP7CANm
# w2K/NkD2VlsHoAC83Ilp3zmZa+Sj+VlTn8OqqkSprE9wPbCmJ1uErmKjFQvWMLNP
# 9EfK9i5wytQVR5OGvRbX9shUitFlUDUjSz2q550nEx+wtBRMqoN8dI519ocHm8C9
# alrGoeCsFeIqZLl0O2/6qLq0VeVwN7lu4ygQkjkqpXHb3Pg5fJuGm38qmpFIu9pR
# x7KvBBC0Hu43sRNiLA==
# SIG # End signature block
