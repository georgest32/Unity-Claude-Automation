# Start AutoGen REST API Service
Write-Host "Starting AutoGen REST API Server on port 8001..." -ForegroundColor Green
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
python -m uvicorn autogen_rest_server:app --host 0.0.0.0 --port 8001 --reload