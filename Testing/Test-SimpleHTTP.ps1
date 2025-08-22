# Test-SimpleHTTP.ps1
# Simple test for HTTP functionality

param(
    [int]$Port = 5560
)

Write-Host "Testing HTTP Server on port $Port" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Body = $null,
        [scriptblock]$Validation
    )
    
    Write-Host "`n[$Name]" -ForegroundColor Yellow
    Write-Host "  URL: $Url" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $Url
            Method = $Method
            TimeoutSec = 3
            UseBasicParsing = $true
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json)
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-RestMethod @params
        
        if (& $Validation $response) {
            Write-Host "  PASSED" -ForegroundColor Green
            $script:passed++
            return $true
        } else {
            Write-Host "  FAILED - Validation failed" -ForegroundColor Red
            Write-Host "  Response: $($response | ConvertTo-Json -Compress)" -ForegroundColor Gray
            $script:failed++
            return $false
        }
    } catch {
        Write-Host "  FAILED - $_" -ForegroundColor Red
        $script:failed++
        return $false
    }
}

# Run tests
Write-Host "`nNote: Start-SimpleServer.ps1 should be running on port $Port" -ForegroundColor Yellow
Write-Host "="*50

Test-Endpoint -Name "Health Check" `
              -Url "http://localhost:$Port/api/health" `
              -Validation { param($r) $r.status -eq "healthy" }

Test-Endpoint -Name "Status Check" `
              -Url "http://localhost:$Port/api/status" `
              -Validation { param($r) $r.status -eq "running" -and $r.port -eq $Port }

Test-Endpoint -Name "Get Errors" `
              -Url "http://localhost:$Port/api/errors" `
              -Validation { param($r) $r.queue_length -eq 0 }

Test-Endpoint -Name "Post Error" `
              -Url "http://localhost:$Port/api/errors" `
              -Method "POST" `
              -Body @{type="test"; message="test error"} `
              -Validation { param($r) $r.success -eq $true }

Test-Endpoint -Name "404 Test" `
              -Url "http://localhost:$Port/api/nonexistent" `
              -Validation { param($r) $r.error -ne $null }  # Just check error exists

# Summary
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "SUMMARY: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -eq 0) {
    Write-Host "`nAll tests passed! The HTTP server is working correctly." -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed. Check the server output for details." -ForegroundColor Yellow
}

exit $(if ($failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUs5F7m4cQSxjUDmoPk22cojT6
# 0y2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUqCYC6EGO6DuY9K6Pv12RXCwUxgwwDQYJKoZIhvcNAQEBBQAEggEAa96l
# fUc7DzEHp3EXJOiXtX1CdIsz73Z7o11yRDf01ZnnRnUFWCqGEjX4VKhNWinHiPR1
# pe/VI1bC/oZFqUtzjO662E8cWfrmzBvoMi5r2gekPVF69K/A5VlTpIr4bAuWQ5Iu
# d7xfmYQfUBkiCXfdOcNb3to3Q9bunuua+uZVx0od6PUcUCF5SF1PozoRRjh6usEl
# d81j5glwOQL/MrR1N7bCKwmpSYB1GLVt9RpYr52b0YgplKHqXGiThdb0e64dvQKe
# AP7o5GMyhUOFtAl0vbEajLYJbhtqm8Ui3P2J3E4id9bOp4yx6kcx6qyjLFm/hCLB
# IqMyqDL3rD1+9ekgNg==
# SIG # End signature block
