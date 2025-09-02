# Access-Documentation.ps1
# Quick access to complete Enhanced Documentation System documentation

Write-Host "=== Enhanced Documentation System v2.0.0 - Complete Documentation ===" -ForegroundColor Cyan

Write-Host "
📚 Documentation Access:" -ForegroundColor Yellow
Write-Host "  🌐 Complete HTML Site: file:///./docs/unified-documentation/index.html" -ForegroundColor Green
Write-Host "  📋 Master Inventory: .\docs\unified-documentation\README.md" -ForegroundColor Green
Write-Host "  🏗️ System Architecture: .\docs\unified-documentation\Complete-System-Architecture.md" -ForegroundColor Green

Write-Host "
🚀 Live Services:" -ForegroundColor Yellow
Write-Host "  📚 Documentation: http://localhost:8080" -ForegroundColor Green
Write-Host "  🔌 API: http://localhost:8091" -ForegroundColor Green
Write-Host "  🤖 LangGraph AI: http://localhost:8000" -ForegroundColor Green
Write-Host "  👥 AutoGen: http://localhost:8001" -ForegroundColor Green
Write-Host "  🧠 Ollama: http://localhost:11434" -ForegroundColor Green
Write-Host "  📊 Visualization: http://localhost:3000" -ForegroundColor Green

# Open documentation site
Start-Process "file:///./docs/unified-documentation/index.html"
