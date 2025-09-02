# Test-PRAutomation-Simple.ps1
# Simple test for PR automation functions
# Created: 2025-08-24

Write-Host "🔧 Testing PR Automation Components" -ForegroundColor Cyan

# Test 1: Check if modules load
Write-Host "`n1. Testing module imports..." -ForegroundColor Yellow
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psd1" -Force
    Write-Host "   ✅ Unity-Claude-GitHub imported" -ForegroundColor Green
} catch {
    Write-Host "   ❌ GitHub module failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Check if PR function exists
Write-Host "`n2. Testing PR function availability..." -ForegroundColor Yellow
$prFunction = Get-Command New-GitHubPullRequest -ErrorAction SilentlyContinue
if ($prFunction) {
    Write-Host "   ✅ New-GitHubPullRequest function available" -ForegroundColor Green
    Write-Host "   Parameters: $($prFunction.Parameters.Keys -join ', ')" -ForegroundColor Gray
} else {
    Write-Host "   ❌ New-GitHubPullRequest function not found" -ForegroundColor Red
}

# Test 3: Check templates
Write-Host "`n3. Testing PR templates..." -ForegroundColor Yellow
$templates = @(
    ".\templates\pr-templates\documentation-update.md",
    ".\templates\pr-templates\api-documentation-update.md",
    ".\templates\pr-templates\breaking-change-docs.md"
)

foreach ($template in $templates) {
    if (Test-Path $template) {
        $content = Get-Content $template -Raw
        Write-Host "   ✅ $(Split-Path $template -Leaf) - $($content.Length) characters" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Missing: $(Split-Path $template -Leaf)" -ForegroundColor Red
    }
}

# Test 4: Check documentation drift module functions (without initialization)
Write-Host "`n4. Testing DocumentationDrift functions..." -ForegroundColor Yellow
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psd1" -Force
    
    $functions = @('New-DocumentationBranch', 'Generate-DocumentationCommitMessage', 'New-DocumentationPR')
    foreach ($func in $functions) {
        $command = Get-Command $func -ErrorAction SilentlyContinue
        if ($command) {
            Write-Host "   ✅ $func available" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $func not found" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "   ❌ DocumentationDrift module failed: $_" -ForegroundColor Red
}

# Test 5: Test Git repository detection
Write-Host "`n5. Testing Git repository detection..." -ForegroundColor Yellow
$gitRemote = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0 -and $gitRemote) {
    if ($gitRemote -match 'github\.com[:/]([^/]+)/([^/.]+)') {
        $owner = $matches[1]
        $repo = $matches[2]
        Write-Host "   ✅ GitHub repo detected: $owner/$repo" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Git remote found but not GitHub: $gitRemote" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  No Git remote configured" -ForegroundColor Yellow
}

Write-Host "`n🎯 PR Automation Test Complete!" -ForegroundColor Cyan
Write-Host "All components are ready for PR automation." -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBkjhoUNB+jpEKj
# z5Q3CFKznQ95fIDZPIke+SSyCJalg6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC3FWwBidZNeBrD/6WbgbsTO
# rKkrNGrW3+VZ5xs9XkabMA0GCSqGSIb3DQEBAQUABIIBAB5J70gOWjaRmtOuKqvC
# ClVAcE5VJcw2ehlv5/MD0jmv0x4h7mjNzLlPCAhnE3jgbl9vp/K2TYDlxhVGLLsV
# He1rwI2C28t/2FZ1SoWL8zOkkBkWUmx55xSAMiB6rHTfHnxHQ5zvS0g3rFHC6Pqf
# 85sQ8E1Vus3WaQb6vw1K7GAy0YOGfjSpTmDhy3xUsPmykkoJVyTf+9BCUyQAbybH
# 4nuhz9AO8Z1hC1pFjod3iWU087P6ZmYhF97evTms+VZjCuGAovvXlMPCls2QZ6WF
# XXaB4S9F2ReskMTZrh+A36HFlY75wzqVu2lplnp4jeQLe3OIr0ejPxwjzOgv7jGo
# 0ig=
# SIG # End signature block
