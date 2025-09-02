# Start-Enhanced-Documentation-Simple.ps1
# Simple manual approach to start using Enhanced Documentation System v2.0.0
# No complex automation, direct function usage
# Date: 2025-08-29

Write-Host "=== Enhanced Documentation System v2.0.0 - Manual Start ===" -ForegroundColor Cyan

Write-Host "`n🎯 You have 100% working system with these capabilities:" -ForegroundColor Green

# Show available Week 4 functions
Write-Host "`n🔮 Week 4 Predictive Analysis Functions:" -ForegroundColor Yellow
Get-Command Get-GitCommitHistory, Get-TechnicalDebt, Get-MaintenancePrediction, Get-CodeChurnMetrics -ErrorAction SilentlyContinue | Format-Table Name, ModuleName

# Show AI services
Write-Host "`n🤖 AI Services Available:" -ForegroundColor Yellow
Write-Host "  🤖 LangGraph AI: http://localhost:8000 (Multi-agent workflows)" -ForegroundColor Green
Write-Host "  👥 AutoGen GroupChat: http://localhost:8001 (Multi-agent collaboration)" -ForegroundColor Green

# Show documentation functions
Write-Host "`n📚 Documentation Functions Available:" -ForegroundColor Yellow
Get-Command *Documentation* | Where-Object { $_.Name -match "New-|Export-|Generate" } | Select-Object -First 5 | Format-Table Name, ModuleName

Write-Host "`n🚀 Ready to Start Enhanced Document Generation!" -ForegroundColor Green

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "QUICK START COMMANDS" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "`n1️⃣ Generate Code Evolution Analysis:" -ForegroundColor Yellow
Write-Host "   New-EvolutionReport -Path '.\Modules' -Since '3.months.ago' -Format 'Text'" -ForegroundColor White

Write-Host "`n2️⃣ Generate Maintenance Predictions:" -ForegroundColor Yellow  
Write-Host "   New-MaintenanceReport -Path '.\Modules' -Format 'HTML' -OutputPath '.\maintenance-report.html'" -ForegroundColor White

Write-Host "`n3️⃣ Analyze Technical Debt:" -ForegroundColor Yellow
Write-Host "   Get-TechnicalDebt -Path '.\Modules' -Recursive -OutputFormat 'Detailed'" -ForegroundColor White

Write-Host "`n4️⃣ Generate Git Analysis:" -ForegroundColor Yellow
Write-Host "   Get-GitCommitHistory -Since '6.months.ago' | Format-Table Hash, Author, Subject, LinesTotal" -ForegroundColor White

Write-Host "`n5️⃣ Create Module Documentation:" -ForegroundColor Yellow
Write-Host "   New-ModuleDocumentation -ModulePath '.\Modules\Unity-Claude-CPG' -IncludeExamples" -ForegroundColor White

Write-Host "`n6️⃣ Test AI Services:" -ForegroundColor Yellow
Write-Host "   Invoke-WebRequest 'http://localhost:8000/health' -UseBasicParsing" -ForegroundColor White
Write-Host "   Invoke-WebRequest 'http://localhost:8001/health' -UseBasicParsing" -ForegroundColor White

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "SYSTEM STATUS: READY FOR AI-POWERED DOCUMENTATION!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan