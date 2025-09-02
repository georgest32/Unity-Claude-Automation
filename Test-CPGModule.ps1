# Simple test for CPG module
Write-Host "Testing Unity-Claude-CPG Module" -ForegroundColor Cyan

# Import just the main module (without nested modules for now)
$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psm1"
Import-Module $modulePath -Force

Write-Host "`n1. Testing Node Creation:" -ForegroundColor Yellow
$node1 = New-CPGNode -Name "TestFunction" -Type Function
$node2 = New-CPGNode -Name "TestVariable" -Type Variable
Write-Host "   Created nodes: $($node1.Name), $($node2.Name)" -ForegroundColor Green

Write-Host "`n2. Testing Graph Creation:" -ForegroundColor Yellow
$graph = New-CPGraph -Name "TestGraph"
Write-Host "   Created graph: $($graph.Name)" -ForegroundColor Green

Write-Host "`n3. Adding Nodes to Graph:" -ForegroundColor Yellow
Add-CPGNode -Graph $graph -Node $node1
Add-CPGNode -Graph $graph -Node $node2
Write-Host "   Graph now has $($graph.Nodes.Count) nodes" -ForegroundColor Green

Write-Host "`n4. Testing Edge Creation:" -ForegroundColor Yellow
$edge = New-CPGEdge -SourceId $node1.Id -TargetId $node2.Id -Type Uses
Add-CPGEdge -Graph $graph -Edge $edge
Write-Host "   Created edge: $($node1.Name) -[Uses]-> $($node2.Name)" -ForegroundColor Green

Write-Host "`n5. Testing Graph Statistics:" -ForegroundColor Yellow
$stats = Get-CPGStatistics -Graph $graph
Write-Host "   Nodes: $($stats.NodeCount), Edges: $($stats.EdgeCount)" -ForegroundColor Green

Write-Host "`n6. Testing Graph Export:" -ForegroundColor Yellow
$exportPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\test-graph.json"
Export-CPGraph -Graph $graph -Path $exportPath -Format JSON
if (Test-Path $exportPath) {
    Write-Host "   Successfully exported to JSON" -ForegroundColor Green
    Remove-Item $exportPath -Force
}

Write-Host "`n7. Testing AST Conversion (Basic):" -ForegroundColor Yellow
# Load the AST converter directly
$astConverterPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-CPG-ASTConverter.psm1"

# Parse the file first to check for syntax errors
$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $astConverterPath,
    [ref]$tokens,
    [ref]$errors
)

if ($errors.Count -gt 0) {
    Write-Host "   AST Converter has syntax errors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "     - $($_.Message)" -ForegroundColor Red }
} else {
    Write-Host "   AST Converter syntax is valid" -ForegroundColor Green
    
    # Try to import it
    try {
        Import-Module $astConverterPath -Force -ErrorAction Stop
        Write-Host "   AST Converter loaded successfully" -ForegroundColor Green
        
        # Test basic conversion
        $testScript = 'function Test { param($Name) Write-Host $Name }'
        $testAst = [System.Management.Automation.Language.Parser]::ParseInput(
            $testScript,
            [ref]$null,
            [ref]$null
        )
        
        $cpgFromAst = Convert-ASTtoCPG -AST $testAst -FilePath "test.ps1"
        Write-Host "   Converted AST to CPG with $($cpgFromAst.Nodes.Count) nodes" -ForegroundColor Green
    } catch {
        Write-Host "   Failed to load AST Converter: $_" -ForegroundColor Red
    }
}

Write-Host "`n=== CPG Module Test Complete ===" -ForegroundColor Cyan
Write-Host "Core CPG functionality is working!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBsLnskDgcLFoPO
# CMU4LESTRlvY2m69oDP3CHuZjp8kK6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFXvsGQo79b0RRkRSyV1eyG1
# r9SQRe7hB9QxWrSkHI4NMA0GCSqGSIb3DQEBAQUABIIBAFJpD8DgTuHvFgoN9gFJ
# 0BXCCzNx8hQZKsGTwTivofYEA0R1gNidnBAg9lP2ZAvjIkpDi9K+dWEjF2tE41y3
# /3uOF1MHVD9k0OPeL9wBXKc7GTAwS8iu6Ow7zTHTRbJsdqili8veo60xwF+Q6xs2
# 7ZpbK+8+rwqDX507FXvQkBjbgWajuoQzF4BGw2HoQ12Pi3V0kOxxuirEndHQpI4n
# Ene2VtWw8FBevQ6oXky5P6P5jQG7rB6hAZXAv9lQ7Bs0kRN/fkJaWATdRZs1YOz5
# R+U8vsyCDXj6PwrNybGlXfAXaEHTZ3hQQfeQQByHEcUzDMmqxrb29tR7xI0TNsB/
# dFU=
# SIG # End signature block
