@echo off
title SystemStatusMonitoring
cd /d "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
powershell.exe -NoExit -ExecutionPolicy Bypass -File "Start-SystemStatusMonitoring-Enhanced.ps1"
pause