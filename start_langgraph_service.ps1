# Start LangGraph REST API Service
Write-Host "Starting LangGraph REST API Server on port 8000..." -ForegroundColor Green
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
python -m uvicorn langgraph_rest_server:app --host 0.0.0.0 --port 8000 --reload