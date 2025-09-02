# Start-UnityClaudeSystem-Windowed.ps1
# Enhanced version that can run specified subsystems in separate PowerShell windows

param(
    [switch]$UseManifestMode,
    [switch]$UseLegacyMode,
    [switch]$Debug,
    [switch]$StartPythonServices,
    [switch]$SkipLangGraph,
    [switch]$SkipAutoGen,
    [string[]]$WindowedSubsystems = @('SystemMonitoring', 'CLIOrchestrator'),
    [string]$WindowTitle = "Unity-Claude Subsystem",
    [switch]$EnableSafeClaudeSession,
    [switch]$EnableAutoAccept,
    [switch]$EnableGitTracking,
    [switch]$StartAllServices,
    [switch]$StartDockerServices,
    [switch]$StartVisualization,
    [switch]$StartGrafana,
    [switch]$StartOllama
)

# Import required modules
Import-Module "$PSScriptRoot\Migration\Legacy-Compatibility.psm1" -Force
Import-Module "$PSScriptRoot\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force

# Function to start Docker Desktop if not running
function Start-DockerDesktop {
    Write-Host "Checking Docker Desktop status..." -ForegroundColor Cyan
    
    try {
        docker version 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Docker Desktop is already running" -ForegroundColor Green
            return $true
        }
    } catch {}
    
    Write-Host "  Starting Docker Desktop..." -ForegroundColor Yellow
    
    # Common Docker Desktop paths
    $dockerPaths = @(
        "C:\Program Files\Docker\Docker\Docker Desktop.exe",
        "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
    )
    
    $dockerPath = $dockerPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($dockerPath) {
        Start-Process -FilePath $dockerPath -WindowStyle Hidden
        Write-Host "  Waiting for Docker to initialize (30 seconds)..." -ForegroundColor Yellow
        
        # Wait for Docker to be ready
        $maxWait = 30
        $waited = 0
        while ($waited -lt $maxWait) {
            Start-Sleep -Seconds 5
            $waited += 5
            try {
                docker version 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✅ Docker Desktop started successfully" -ForegroundColor Green
                    return $true
                }
            } catch {}
            Write-Host "  Still waiting... ($waited/$maxWait seconds)" -ForegroundColor Gray
        }
        
        Write-Host "  ⚠️ Docker Desktop is starting but may not be fully ready" -ForegroundColor Yellow
        return $false
    } else {
        Write-Host "  ❌ Docker Desktop not found. Please install from: https://www.docker.com/products/docker-desktop" -ForegroundColor Red
        return $false
    }
}

# Function to start Ollama service
function Start-OllamaService {
    Write-Host "Checking Ollama service..." -ForegroundColor Cyan
    
    try {
        $ollamaList = ollama list 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Ollama is already running" -ForegroundColor Green
            Write-Host "  Available models:" -ForegroundColor Gray
            $ollamaList | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
            return $true
        }
    } catch {}
    
    Write-Host "  Starting Ollama service..." -ForegroundColor Yellow
    
    # Start Ollama serve in background
    $ollamaCommand = @"
`$host.UI.RawUI.WindowTitle = 'Ollama Service'
Write-Host 'Starting Ollama Service...' -ForegroundColor Green
try {
    ollama serve
} catch {
    Write-Host "Error starting Ollama: `$(`$_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close window'
}
"@
    
    $ollamaParams = @{
        FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
        ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$ollamaCommand`""
        WindowStyle = "Minimized"
        PassThru = $true
    }
    
    $ollamaProcess = Start-Process @ollamaParams
    Write-Host "  Ollama service started (PID: $($ollamaProcess.Id))" -ForegroundColor Green
    
    Start-Sleep -Seconds 3
    return $true
}

# Function to start Docker services
function Start-DockerServicesStack {
    Write-Host "Starting Docker services..." -ForegroundColor Cyan
    
    if (-not (Start-DockerDesktop)) {
        Write-Host "  ⚠️ Docker Desktop not fully ready, services may fail to start" -ForegroundColor Yellow
    }
    
    # Start main docker-compose services
    Write-Host "  Starting main services..." -ForegroundColor Yellow
    docker-compose up -d 2>&1 | Out-String | Write-Debug
    
    # Start monitoring stack (Grafana, Prometheus, etc.)
    Write-Host "  Starting monitoring stack (Grafana on port 3000)..." -ForegroundColor Yellow
    docker-compose -f docker-compose.monitoring.yml up -d 2>&1 | Out-String | Write-Debug
    
    Write-Host "  ✅ Docker services started" -ForegroundColor Green
    return $true
}

# Function to start D3.js Visualization
function Start-VisualizationDashboard {
    Write-Host "Starting D3.js Visualization Dashboard..." -ForegroundColor Cyan
    
    # Check if Node.js is available
    try {
        $nodeVersion = node --version 2>$null
        if (-not $nodeVersion) {
            Write-Host "  ❌ Node.js not found. Install from: https://nodejs.org/" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ❌ Node.js not found. Install from: https://nodejs.org/" -ForegroundColor Red
        return $false
    }
    
    # Check if visualization directory exists
    if (-not (Test-Path "$PSScriptRoot\Visualization")) {
        Write-Host "  ❌ Visualization directory not found" -ForegroundColor Red
        return $false
    }
    
    # Install dependencies if needed
    if (-not (Test-Path "$PSScriptRoot\Visualization\node_modules")) {
        Write-Host "  Installing Node.js dependencies..." -ForegroundColor Yellow
        Push-Location "$PSScriptRoot\Visualization"
        npm install 2>&1 | Out-String | Write-Debug
        Pop-Location
    }
    
    # Start visualization server on port 3001 (to avoid conflict with Grafana)
    $vizCommand = @"
`$host.UI.RawUI.WindowTitle = 'D3.js Visualization Dashboard'
Set-Location -Path '$PSScriptRoot\Visualization'
Write-Host 'Starting D3.js Visualization Dashboard on port 3001...' -ForegroundColor Green
Write-Host 'URL: http://localhost:3001' -ForegroundColor Cyan
try {
    npm start
} catch {
    Write-Host "Error starting visualization: `$(`$_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close window'
}
"@
    
    $vizParams = @{
        FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
        ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$vizCommand`""
        WindowStyle = "Normal"
        PassThru = $true
    }
    
    $vizProcess = Start-Process @vizParams
    Write-Host "  ✅ Visualization Dashboard started (PID: $($vizProcess.Id))" -ForegroundColor Green
    Write-Host "  📊 URL: http://localhost:3001" -ForegroundColor Cyan
    
    return $true
}

function Start-PythonServices {
    param(
        [switch]$SkipLangGraph,
        [switch]$SkipAutoGen,
        [string]$WorkingDirectory = $PWD.Path,
        [string]$WindowTitle = "Python AI Services"
    )
    
    Write-Host "Starting Python AI Services..." -ForegroundColor Cyan
    
    # Find conda Python executable
    $condaPython = "C:\Users\georg\miniconda3\python.exe"
    if (-not (Test-Path $condaPython)) {
        # Fallback to system Python
        $condaPython = Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if (-not $condaPython) {
            Write-Host "ERROR: Python executable not found" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "Using Python: $condaPython" -ForegroundColor Yellow
    
    $services = @()
    
    # Start LangGraph Service
    if (-not $SkipLangGraph) {
        Write-Host "Starting LangGraph REST API Service (port 8000)..." -ForegroundColor Green
        
        $langGraphCommand = @"
`$host.UI.RawUI.WindowTitle = '$WindowTitle - LangGraph'
Set-Location -Path '$WorkingDirectory'
Write-Host 'Starting LangGraph REST API Server on port 8000...' -ForegroundColor Green
Write-Host 'Working Directory:' `$PWD.Path -ForegroundColor Yellow
try {
    & '$condaPython' -m uvicorn langgraph_rest_server:app --host 0.0.0.0 --port 8000 --reload
} catch {
    Write-Host "Error starting LangGraph service: `$(`$_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close window'
}
"@
        
        $langGraphParams = @{
            FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
            ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$langGraphCommand`""
            WindowStyle = "Normal"
            PassThru = $true
        }
        
        $langGraphProcess = Start-Process @langGraphParams
        Write-Host "  LangGraph service started in window (PID: $($langGraphProcess.Id))" -ForegroundColor Green
        
        $services += @{
            Name = "LangGraph"
            Process = $langGraphProcess
            Port = 8000
            HealthEndpoint = "http://localhost:8000/health"
        }
    }
    
    # Start AutoGen Service
    if (-not $SkipAutoGen) {
        Write-Host "Starting AutoGen REST API Service (port 8001)..." -ForegroundColor Green
        
        $autoGenCommand = @"
`$host.UI.RawUI.WindowTitle = '$WindowTitle - AutoGen'
Set-Location -Path '$WorkingDirectory'
Write-Host 'Starting AutoGen REST API Server on port 8001...' -ForegroundColor Green
Write-Host 'Working Directory:' `$PWD.Path -ForegroundColor Yellow
try {
    & '$condaPython' -m uvicorn autogen_rest_server:app --host 0.0.0.0 --port 8001 --reload
} catch {
    Write-Host "Error starting AutoGen service: `$(`$_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close window'
}
"@
        
        $autoGenParams = @{
            FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
            ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$autoGenCommand`""
            WindowStyle = "Normal"
            PassThru = $true
        }
        
        $autoGenProcess = Start-Process @autoGenParams
        Write-Host "  AutoGen service started in window (PID: $($autoGenProcess.Id))" -ForegroundColor Green
        
        $services += @{
            Name = "AutoGen"
            Process = $autoGenProcess
            Port = 8001
            HealthEndpoint = "http://localhost:8001/health"
        }
    }
    
    # Wait for services to initialize
    if ($services.Count -gt 0) {
        Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
        
        # Test service health
        foreach ($service in $services) {
            try {
                $response = Invoke-RestMethod -Uri $service.HealthEndpoint -TimeoutSec 5 -ErrorAction Stop
                Write-Host "  ✅ $($service.Name) service healthy on port $($service.Port)" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️ $($service.Name) service starting on port $($service.Port) (health check failed)" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "Python AI Services startup complete" -ForegroundColor Cyan
    Write-Host ""
    
    return $services
}

function Start-SubsystemInWindow {
    param(
        [string]$SubsystemName,
        [string]$StartScriptPath,
        [string]$WorkingDirectory = $PWD.Path,
        [string]$WindowTitle = "Unity-Claude Subsystem"
    )
    
    Write-Host "Starting $SubsystemName in separate PowerShell window..." -ForegroundColor Cyan
    
    # Create the command to run in the new window
    $windowCommand = @"
`$host.UI.RawUI.WindowTitle = '$WindowTitle - $SubsystemName'
Set-Location -Path '$WorkingDirectory'
`$env:PSModulePath = '$WorkingDirectory\Modules;' + `$env:PSModulePath
Write-Host 'Starting $SubsystemName...' -ForegroundColor Green
Write-Host 'Working Directory:' `$PWD.Path -ForegroundColor Yellow
Write-Host 'Script Path: $StartScriptPath' -ForegroundColor Yellow
try {
    & '$StartScriptPath'
} catch {
    Write-Host "Error starting $SubsystemName : `$(`$_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close window'
}
"@
    
    # Start new PowerShell window
    $startParams = @{
        FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
        ArgumentList = "-ExecutionPolicy Bypass -NoExit -Command `"$windowCommand`""
        WindowStyle = "Normal"
        PassThru = $true
    }
    
    $process = Start-Process @startParams
    Write-Host "  Started $SubsystemName in window (PID: $($process.Id))" -ForegroundColor Green
    
    return $process
}

function Register-SubsystemFromManifest-Windowed {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Manifest,
        [string[]]$WindowedSubsystems = @(),
        [string]$WindowTitle = "Unity-Claude Subsystem"
    )
    
    $subsystemName = $Manifest.Data.Name
    $useWindow = $subsystemName -in $WindowedSubsystems
    
    Write-Host "Registering $subsystemName (Windowed: $useWindow)..." -ForegroundColor Yellow
    
    # Handle mutex if configured
    $mutexAcquired = $false
    $mutexObject = $null
    
    if ($Manifest.Data.UseMutex -or $Manifest.Data.MutexName) {
        $mutexName = if ($Manifest.Data.MutexName) { 
            $Manifest.Data.MutexName 
        } else { 
            "Global\UnityClaudeSubsystem_$subsystemName" 
        }
        
        Write-Host "  Checking mutex: $mutexName" -ForegroundColor Gray
        
        # Try to acquire mutex
        $mutexResult = New-SubsystemMutex -SubsystemName $subsystemName -MutexName $mutexName -TimeoutMs 5000
        
        if ($mutexResult.Acquired) {
            $mutexAcquired = $true
            $mutexObject = $mutexResult.Mutex
            Write-Host "  Mutex acquired" -ForegroundColor Green
            
            # Store mutex
            if (-not $script:SubsystemMutexes) {
                $script:SubsystemMutexes = @{}
            }
            $script:SubsystemMutexes[$subsystemName] = $mutexObject
            
        } else {
            Write-Host "  WARNING: Mutex already exists for $subsystemName" -ForegroundColor Yellow
            Write-Host "  This might indicate another instance is running, but launching anyway..." -ForegroundColor Yellow
            # Continue with process launch instead of skipping
        }
    }
    
    # Start the subsystem
    $ProcessId = $null
    
    if ($Manifest.Data.StartScript) {
        $startScriptPath = if ([System.IO.Path]::IsPathRooted($Manifest.Data.StartScript)) {
            $Manifest.Data.StartScript
        } else {
            $projectRoot = Split-Path $Manifest.Directory -Parent
            $testPath = Join-Path $projectRoot $Manifest.Data.StartScript
            
            if (Test-Path $testPath) {
                $testPath
            } else {
                Join-Path $Manifest.Directory $Manifest.Data.StartScript
            }
        }
        
        if (-not (Test-Path $startScriptPath)) {
            Write-Host "  Start script not found: $startScriptPath" -ForegroundColor Red
            
            if ($mutexAcquired -and $mutexObject) {
                Remove-SubsystemMutex -SubsystemName $subsystemName
            }
            
            throw "Start script not found: $startScriptPath"
        }
        
        $workingDir = if ($Manifest.Data.WorkingDirectory) { 
            $Manifest.Data.WorkingDirectory 
        } else { 
            $PWD.Path 
        }
        
        if ($useWindow) {
            # Start in separate window
            $process = Start-SubsystemInWindow -SubsystemName $subsystemName -StartScriptPath $startScriptPath -WorkingDirectory $workingDir -WindowTitle $WindowTitle
            $ProcessId = $process.Id
        } else {
            # Use original background process method
            $startParams = @{
                FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
                ArgumentList = "-ExecutionPolicy Bypass -File `"$startScriptPath`""
                WindowStyle = "Hidden"
                PassThru = $true
            }
            
            if ($workingDir) {
                $startParams.WorkingDirectory = $workingDir
            }
            
            $process = Start-Process @startParams
            $ProcessId = $process.Id
            Write-Host "  Started $subsystemName as background process (PID: $ProcessId)" -ForegroundColor Green
        }
        
        # Give the process more time to initialize before registration
        # This is especially important for windowed processes
        if ($useWindow) {
            Start-Sleep -Milliseconds 3000  # 3 seconds for windowed processes
        } else {
            Start-Sleep -Milliseconds 1000  # 1 second for background processes
        }
    }
    
    # Register with system
    try {
        $modulePath = if ($Manifest.Data.StartScript) {
            $Manifest.Data.StartScript
        } else {
            ".\Modules\Unity-Claude-$subsystemName\Unity-Claude-$subsystemName.psm1"
        }
        
        Register-Subsystem -SubsystemName $subsystemName -ModulePath $modulePath -ProcessId $ProcessId
        
        Write-Host "  Successfully registered $subsystemName" -ForegroundColor Green
        
        return @{
            Success = $true
            SubsystemName = $subsystemName
            ProcessId = $ProcessId
            MutexAcquired = $mutexAcquired
            WindowedMode = $useWindow
        }
        
    } catch {
        Write-Host "  Failed to register $subsystemName : $_" -ForegroundColor Red
        
        if ($mutexAcquired -and $mutexObject) {
            Remove-SubsystemMutex -SubsystemName $subsystemName
        }
        
        throw
    }
}

function Start-ManifestBasedSystemWithWindows {
    param(
        [string]$ManifestPath = ".\Manifests",
        [string[]]$WindowedSubsystems = @(),
        [string]$WindowTitle = "Unity-Claude Subsystem"
    )
    
    Write-Host "Starting Unity-Claude-Automation with windowed subsystems..." -ForegroundColor Cyan
    Write-Host "Windowed subsystems: $($WindowedSubsystems -join ', ')" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor White
    
    if (-not (Test-Path $ManifestPath)) {
        throw "Manifest directory not found: $ManifestPath"
    }
    
    $manifests = Get-SubsystemManifests -Path $ManifestPath
    if (-not $manifests -or $manifests.Count -eq 0) {
        throw "No valid manifests found in: $ManifestPath"
    }
    
    Write-Host "Found $($manifests.Count) subsystem manifests" -ForegroundColor Cyan
    
    # Get startup order with dependency resolution
    $startupOrderResult = Get-SubsystemStartupOrder -Manifests $manifests
    Write-Host "Startup order: $($startupOrderResult.StartupOrder -join ' -> ')" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    
    # Start subsystems in order
    $startedSubsystems = @()
    $windowedCount = 0
    $backgroundCount = 0
    
    foreach ($subsystemName in $startupOrderResult.StartupOrder) {
        $manifest = $manifests | Where-Object { $_.Name -eq $subsystemName } | Select-Object -First 1
        
        if ($manifest) {
            try {
                $result = Register-SubsystemFromManifest-Windowed -Manifest $manifest -WindowedSubsystems $WindowedSubsystems -WindowTitle $WindowTitle
                
                if ($result.Success) {
                    $startedSubsystems += $subsystemName
                    if ($result.WindowedMode) {
                        $windowedCount++
                    } else {
                        $backgroundCount++
                    }
                } elseif ($result.Skipped) {
                    Write-Host "  ${subsystemName}: Already running (skipped)" -ForegroundColor Yellow
                    $startedSubsystems += $subsystemName
                }
                
            } catch {
                Write-Host "  Failed to start ${subsystemName}: $_" -ForegroundColor Red
            }
        }
        
        Write-Host "" -ForegroundColor White
    }
    
    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Unity-Claude-Automation Startup Complete" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total subsystems: $($manifests.Count)" -ForegroundColor White
    Write-Host "Started successfully: $($startedSubsystems.Count)" -ForegroundColor Green
    Write-Host "Windowed processes: $windowedCount" -ForegroundColor Yellow
    Write-Host "Background processes: $backgroundCount" -ForegroundColor Gray
    Write-Host "" -ForegroundColor White
    
    if ($windowedCount -gt 0) {
        Write-Host "IMPORTANT: Windowed subsystems are running in separate PowerShell windows." -ForegroundColor Yellow
        Write-Host "Do not close these windows unless you want to stop those subsystems." -ForegroundColor Yellow
        Write-Host "" -ForegroundColor White
    }
    
    return @{
        Success = $true
        Message = "System startup completed with windowed processes"
        StartedSubsystems = $startedSubsystems
        WindowedCount = $windowedCount
        BackgroundCount = $backgroundCount
        TotalSubsystems = $manifests.Count
    }
}

# Main execution
try {
    Write-Host "Unity-Claude-Automation System Startup (Windowed Mode)" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Validate parameters
    if ($UseLegacyMode -and $UseManifestMode) {
        throw "Cannot specify both -UseLegacyMode and -UseManifestMode"
    }
    
    # Determine mode
    if ($UseLegacyMode) {
        Write-Host "ERROR: Legacy mode does not support windowed subsystems." -ForegroundColor Red
        Write-Host "Please use -UseManifestMode for windowed functionality." -ForegroundColor Yellow
        exit 1
    }
    
    if (-not $UseManifestMode) {
        # Auto-detect
        $manifestsExist = (Test-Path ".\Manifests") -and 
                         (Get-ChildItem ".\Manifests" -Filter "*.manifest.psd1" | Measure-Object).Count -gt 0
        
        if (-not $manifestsExist) {
            Write-Host "ERROR: No manifests found. Windowed mode requires manifest-based configuration." -ForegroundColor Red
            Write-Host "Please run the migration script first:" -ForegroundColor Yellow
            Write-Host "  .\Migration\Migrate-ToManifestSystem.ps1" -ForegroundColor White
            exit 1
        }
    }
    
    Write-Host "Mode: Manifest-based with windowed subsystems" -ForegroundColor Green
    Write-Host "Windowed subsystems: $($WindowedSubsystems -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    
    # Start all services if requested
    if ($StartAllServices) {
        $StartDockerServices = $true
        $StartVisualization = $true
        $StartGrafana = $true
        $StartOllama = $true
        $StartPythonServices = $true
    }
    
    # Start Ollama if requested
    if ($StartOllama -or $StartAllServices) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Starting Ollama AI Service" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        Start-OllamaService
        Write-Host ""
    }
    
    # Start Docker services if requested
    if ($StartDockerServices -or $StartGrafana -or $StartAllServices) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Starting Docker Services" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        Start-DockerServicesStack
        Write-Host ""
    }
    
    # Start Visualization if requested
    if ($StartVisualization -or $StartAllServices) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Starting Visualization Dashboard" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        Start-VisualizationDashboard
        Write-Host ""
    }
    
    # Start Python services if requested
    $pythonServices = @()
    if ($StartPythonServices -or $StartAllServices) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Starting Python AI Services" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        $pythonServices = Start-PythonServices -SkipLangGraph:$SkipLangGraph -SkipAutoGen:$SkipAutoGen -WindowTitle $WindowTitle
        
        if ($pythonServices -and $pythonServices.Count -gt 0) {
            Write-Host "Python services started successfully!" -ForegroundColor Green
        } else {
            Write-Host "No Python services started" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Start the system
    $result = Start-ManifestBasedSystemWithWindows -WindowedSubsystems $WindowedSubsystems -WindowTitle $WindowTitle
    
    if ($result.Success) {
        Write-Host "System startup completed successfully!" -ForegroundColor Green
        
        # Check if user wants to enable Safe Claude Session
        if (-not $EnableSafeClaudeSession -and -not $EnableAutoAccept -and -not $EnableGitTracking) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "SAFE CLAUDE SESSION OPTIONS" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Would you like to enable Safe Claude Session features?" -ForegroundColor White
            Write-Host "This provides:" -ForegroundColor Gray
            Write-Host "  • Auto-approval for safe operations only" -ForegroundColor Gray
            Write-Host "  • File archiving before modifications" -ForegroundColor Gray
            Write-Host "  • Automatic git commits after features" -ForegroundColor Gray
            Write-Host "  • Blocking of destructive operations" -ForegroundColor Gray
            Write-Host ""
            
            $response = Read-Host "Enable Safe Claude Session? (y/n) [default: n]"
            if ($response -eq 'y' -or $response -eq 'Y') {
                $EnableSafeClaudeSession = $true
                
                # Ask about auto-accept
                Write-Host ""
                $autoResponse = Read-Host "Enable auto-accept mode (shift+tab in Claude)? (y/n) [default: y]"
                if ($autoResponse -ne 'n' -and $autoResponse -ne 'N') {
                    $EnableAutoAccept = $true
                }
                
                # Ask about git tracking
                Write-Host ""
                $gitResponse = Read-Host "Enable automatic git commits? (y/n) [default: y]"
                if ($gitResponse -ne 'n' -and $gitResponse -ne 'N') {
                    $EnableGitTracking = $true
                }
            }
        }
        
        # Start Safe Claude Session if requested
        if ($EnableSafeClaudeSession -or $EnableAutoAccept -or $EnableGitTracking) {
            Write-Host ""
            Write-Host "Starting Safe Claude Session..." -ForegroundColor Cyan
            
            # Build command arguments
            $safeSessionArgs = @()
            if ($EnableAutoAccept) {
                $safeSessionArgs += "-EnableAutoAccept"
            }
            if ($EnableGitTracking) {
                $safeSessionArgs += "-EnableGitTracking"
            }
            
            # Start in a new window
            $safeSessionCommand = @"
`$host.UI.RawUI.WindowTitle = 'Safe Claude Session Monitor'
Set-Location -Path '$($PWD.Path)'
Write-Host 'Safe Claude Session Monitor' -ForegroundColor Cyan
Write-Host '=============================' -ForegroundColor Cyan
& '.\Start-SafeClaudeSession.ps1' $($safeSessionArgs -join ' ')
"@
            
            $safeSessionParams = @{
                FilePath = "C:\Program Files\PowerShell\7\pwsh.exe"
                ArgumentList = "-NoExit", "-Command", $safeSessionCommand
                WindowStyle = "Normal"
                PassThru = $true
            }
            
            $safeSessionProcess = Start-Process @safeSessionParams
            Write-Host "✅ Safe Claude Session started in window (PID: $($safeSessionProcess.Id))" -ForegroundColor Green
            
            if ($EnableAutoAccept) {
                Write-Host ""
                Write-Host "⚠️ IMPORTANT: In your Claude Code CLI window:" -ForegroundColor Yellow
                Write-Host "   Press shift+tab to enable 'auto-accept edit on' mode" -ForegroundColor Cyan
                Write-Host "   This will auto-approve only safe operations defined in .claude\settings.json" -ForegroundColor Gray
            }
        }
        
        # Show Python services summary if started
        if ($pythonServices -and $pythonServices.Count -gt 0) {
            Write-Host "" -ForegroundColor White
            Write-Host "Python AI Services Summary:" -ForegroundColor Cyan
            foreach ($service in $pythonServices) {
                Write-Host "  • $($service.Name): http://localhost:$($service.Port)" -ForegroundColor White
            }
            Write-Host "" -ForegroundColor White
            Write-Host "IMPORTANT: Python services are running in separate windows." -ForegroundColor Yellow
            Write-Host "Do not close these windows unless you want to stop the AI services." -ForegroundColor Yellow
        }
        
        # Show all service URLs if everything was started
        if ($StartAllServices -or ($StartDockerServices -and $StartVisualization)) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "ALL SERVICES RUNNING" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "📊 Dashboards:" -ForegroundColor Yellow
            Write-Host "  • Grafana Monitoring: http://localhost:3000 (admin/admin)" -ForegroundColor White
            Write-Host "  • D3.js Visualization: http://localhost:3001" -ForegroundColor White
            Write-Host ""
            Write-Host "🔧 API Services:" -ForegroundColor Yellow
            Write-Host "  • LangGraph API: http://localhost:8000" -ForegroundColor White
            Write-Host "  • AutoGen GroupChat: http://localhost:8001" -ForegroundColor White
            Write-Host "  • Documentation Server: http://localhost:8080" -ForegroundColor White
            Write-Host "  • Docs API: http://localhost:8091" -ForegroundColor White
            Write-Host ""
            Write-Host "🤖 AI Services:" -ForegroundColor Yellow
            Write-Host "  • Ollama: Running (codellama:34b, codellama:13b)" -ForegroundColor White
            if ($pythonServices.Count -gt 0) {
                foreach ($service in $pythonServices) {
                    Write-Host "  • $($service.Name): http://localhost:$($service.Port)" -ForegroundColor White
                }
            }
            Write-Host ""
            Write-Host "⚠️ IMPORTANT: Multiple windows are running. Do not close them." -ForegroundColor Yellow
        }
    } else {
        Write-Host "System startup completed with warnings." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "SYSTEM STARTUP FAILED:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}