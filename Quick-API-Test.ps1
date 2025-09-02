
Write-Host '=== Testing Complete System ===' -ForegroundColor Green

# Test login
Write-Host 'Testing JWT Authentication...' -ForegroundColor Yellow
try {
    $auth = Invoke-RestMethod -Uri 'http://localhost:8080/api/auth/login' -Method POST -ContentType 'application/json' -Body '{"username":"admin","password":"admin123"}'
    Write-Host '✅ Authentication successful' -ForegroundColor Green
    $token = $auth.token
    
    # Test agent operations
    Write-Host 'Testing Agent Operations...' -ForegroundColor Yellow
    $headers = @{ Authorization = "Bearer $token" }
    $agents = Invoke-RestMethod -Uri 'http://localhost:8080/api/agents' -Headers $headers
    Write-Host "✅ Found $($agents.Count) agents" -ForegroundColor Green
    
    if ($agents.Count -gt 0) {
        $agentId = $agents[0].id
        $result = Invoke-RestMethod -Uri "http://localhost:8080/api/agents/$agentId/restart" -Method POST -Headers $headers
        Write-Host "✅ Agent restart: $($result.message)" -ForegroundColor Green
    }
    
    Write-Host '✅ All tests passed!' -ForegroundColor Green
} catch {
    Write-Host "❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
}

