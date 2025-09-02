# setup-d3-dashboard.ps1
# Unity-Claude Automation - D3.js Visualization Setup Script
# Automates the setup and initialization of the D3.js dashboard for CPG visualization

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$InstallDependencies,
    
    [Parameter()]
    [switch]$StartServer,
    
    [Parameter()]
    [switch]$OpenBrowser,
    
    [Parameter()]
    [int]$Port = 3000,
    
    [Parameter()]
    [switch]$DevMode
)

$ErrorActionPreference = "Stop"

Write-Host "Unity-Claude D3.js Visualization Setup" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Join-Path $ScriptDir ".."

Write-Host "`nProject Root: $ProjectRoot" -ForegroundColor Green
Write-Host "Visualization Directory: $ScriptDir" -ForegroundColor Green

#region Node.js Verification

Write-Host "`n[1/5] Checking Node.js installation..." -ForegroundColor Yellow

try {
    $nodeVersion = node --version 2>$null
    if ($nodeVersion) {
        Write-Host "  Node.js found: $nodeVersion" -ForegroundColor Green
        
        # Check minimum version (14.0.0)
        $versionNumber = [version]($nodeVersion -replace 'v', '')
        if ($versionNumber -lt [version]"14.0.0") {
            Write-Warning "  Node.js version $nodeVersion is below recommended v14.0.0"
            Write-Warning "  Please consider updating Node.js for best compatibility"
        }
    }
} catch {
    Write-Error "Node.js is not installed or not in PATH"
    Write-Host "`nTo install Node.js:" -ForegroundColor Yellow
    Write-Host "  1. Visit https://nodejs.org/" -ForegroundColor White
    Write-Host "  2. Download LTS version (18.x recommended)" -ForegroundColor White
    Write-Host "  3. Run installer and restart PowerShell" -ForegroundColor White
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version 2>$null
    Write-Host "  npm found: v$npmVersion" -ForegroundColor Green
} catch {
    Write-Error "npm is not available"
    exit 1
}

#endregion

#region Project Structure Verification

Write-Host "`n[2/5] Verifying project structure..." -ForegroundColor Yellow

# Check if package.json exists
if (-not (Test-Path "$ScriptDir\package.json")) {
    Write-Error "package.json not found in $ScriptDir"
    Write-Host "Please ensure you're running this from the Visualization directory" -ForegroundColor Red
    exit 1
}

Write-Host "  package.json found" -ForegroundColor Green

# Verify required directories exist
$requiredDirs = @(
    "views",
    "public",
    "public\static",
    "public\static\js",
    "public\static\css",
    "public\static\data"
)

foreach ($dir in $requiredDirs) {
    $fullPath = Join-Path $ScriptDir $dir
    if (Test-Path $fullPath) {
        Write-Host "  Directory exists: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Creating directory: $dir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}

# Verify required files
$requiredFiles = @(
    @{Path="server.js"; Required=$true},
    @{Path="views\index.html"; Required=$true},
    @{Path="public\static\js\graph-renderer.js"; Required=$true},
    @{Path="public\static\js\graph-controls.js"; Required=$true},
    @{Path="public\static\css\index.css"; Required=$true}
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $ScriptDir $file.Path
    if (Test-Path $fullPath) {
        Write-Host "  File exists: $($file.Path)" -ForegroundColor Green
    } else {
        if ($file.Required) {
            $missingFiles += $file.Path
            Write-Host "  Missing required file: $($file.Path)" -ForegroundColor Red
        } else {
            Write-Host "  Optional file missing: $($file.Path)" -ForegroundColor Yellow
        }
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "Missing required files. Please ensure all visualization files are in place."
    exit 1
}

#endregion

#region Dependency Installation

if ($InstallDependencies -or -not (Test-Path "$ScriptDir\node_modules")) {
    Write-Host "`n[3/5] Installing dependencies..." -ForegroundColor Yellow
    
    Push-Location $ScriptDir
    try {
        Write-Host "  Running npm install..." -ForegroundColor White
        
        # Run npm install
        $npmProcess = Start-Process -FilePath "npm" -ArgumentList "install" -NoNewWindow -Wait -PassThru
        
        if ($npmProcess.ExitCode -eq 0) {
            Write-Host "  Dependencies installed successfully" -ForegroundColor Green
            
            # Check for vulnerabilities
            Write-Host "  Checking for vulnerabilities..." -ForegroundColor Yellow
            npm audit --audit-level=high 2>$null | Out-String | Write-Host
        } else {
            Write-Error "npm install failed with exit code $($npmProcess.ExitCode)"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "`n[3/5] Dependencies already installed" -ForegroundColor Green
}

#endregion

#region Configuration

Write-Host "`n[4/5] Configuring visualization..." -ForegroundColor Yellow

# Create sample data file if it doesn't exist
$sampleDataPath = Join-Path $ScriptDir "public\static\data\sample-graph.json"
if (-not (Test-Path $sampleDataPath)) {
    Write-Host "  Creating sample data file..." -ForegroundColor Yellow
    
    $sampleData = @{
        nodes = @(
            @{id = "Unity-Claude-Core"; group = "module"; type = "powershell"},
            @{id = "Unity-Claude-CPG"; group = "module"; type = "powershell"},
            @{id = "Unity-Claude-LLM"; group = "module"; type = "powershell"},
            @{id = "CPG-CallGraphBuilder"; group = "component"; type = "powershell"},
            @{id = "CPG-DataFlowTracker"; group = "component"; type = "powershell"},
            @{id = "LLM-QueryEngine"; group = "component"; type = "powershell"},
            @{id = "Performance-Cache"; group = "component"; type = "powershell"}
        )
        links = @(
            @{source = "Unity-Claude-Core"; target = "Unity-Claude-CPG"; strength = 0.8},
            @{source = "Unity-Claude-Core"; target = "Unity-Claude-LLM"; strength = 0.7},
            @{source = "Unity-Claude-CPG"; target = "CPG-CallGraphBuilder"; strength = 0.9},
            @{source = "Unity-Claude-CPG"; target = "CPG-DataFlowTracker"; strength = 0.9},
            @{source = "Unity-Claude-LLM"; target = "LLM-QueryEngine"; strength = 0.9},
            @{source = "Unity-Claude-CPG"; target = "Performance-Cache"; strength = 0.6}
        )
        metadata = @{
            generated = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            source = "Unity-Claude Automation System"
            version = "1.0.0"
        }
    } | ConvertTo-Json -Depth 10
    
    $sampleData | Set-Content -Path $sampleDataPath -Encoding UTF8
    Write-Host "  Sample data created" -ForegroundColor Green
} else {
    Write-Host "  Sample data already exists" -ForegroundColor Green
}

# Check for environment configuration
$envPath = Join-Path $ScriptDir ".env"
if (-not (Test-Path $envPath)) {
    Write-Host "  Creating .env file..." -ForegroundColor Yellow
    @"
# D3.js Visualization Environment Configuration
NODE_ENV=$( if ($DevMode) { 'development' } else { 'production' })
PORT=$Port
DATA_DIR=./public/static/data
ENABLE_HOT_RELOAD=$( if ($DevMode) { 'true' } else { 'false' })
"@ | Set-Content -Path $envPath -Encoding UTF8
    Write-Host "  .env file created" -ForegroundColor Green
} else {
    Write-Host "  .env file already exists" -ForegroundColor Green
}

#endregion

#region Server Management

Write-Host "`n[5/5] Server management..." -ForegroundColor Yellow

if ($StartServer) {
    Write-Host "  Starting visualization server..." -ForegroundColor Yellow
    
    Push-Location $ScriptDir
    try {
        # Kill any existing Node.js processes on the port
        $existingProcess = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        if ($existingProcess) {
            $pid = $existingProcess.OwningProcess
            Write-Host "  Stopping existing process on port $Port (PID: $pid)..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        # Start the server
        if ($DevMode) {
            Write-Host "  Starting in development mode with hot reload..." -ForegroundColor Cyan
            $serverProcess = Start-Process -FilePath "npm" -ArgumentList "run", "dev" -NoNewWindow -PassThru
        } else {
            Write-Host "  Starting in production mode..." -ForegroundColor Cyan
            $serverProcess = Start-Process -FilePath "npm" -ArgumentList "start" -NoNewWindow -PassThru
        }
        
        Write-Host "  Server process started (PID: $($serverProcess.Id))" -ForegroundColor Green
        
        # Wait for server to be ready
        Write-Host "  Waiting for server to be ready..." -ForegroundColor Yellow
        $maxAttempts = 30
        $attempt = 0
        $serverReady = $false
        
        while ($attempt -lt $maxAttempts -and -not $serverReady) {
            Start-Sleep -Seconds 1
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 1 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $serverReady = $true
                }
            } catch {
                # Server not ready yet
            }
            $attempt++
        }
        
        if ($serverReady) {
            Write-Host "  Server is ready!" -ForegroundColor Green
            Write-Host "`n========================================" -ForegroundColor Cyan
            Write-Host "D3.js Visualization Dashboard Ready" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "Dashboard URL: http://localhost:$Port" -ForegroundColor White
            Write-Host "WebSocket URL: ws://localhost:$Port" -ForegroundColor White
            Write-Host "Data Directory: $ScriptDir\public\static\data" -ForegroundColor White
            
            if ($OpenBrowser) {
                Write-Host "`nOpening dashboard in browser..." -ForegroundColor Yellow
                Start-Process "http://localhost:$Port"
            }
            
            Write-Host "`nPress Ctrl+C to stop the server" -ForegroundColor Yellow
            
            # Keep the script running
            while ($serverProcess.HasExited -eq $false) {
                Start-Sleep -Seconds 1
            }
        } else {
            Write-Error "Server failed to start within 30 seconds"
            if (-not $serverProcess.HasExited) {
                Stop-Process -Id $serverProcess.Id -Force
            }
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "  Server not started (use -StartServer to start)" -ForegroundColor Yellow
    Write-Host "`nTo start the server manually:" -ForegroundColor Cyan
    Write-Host "  cd $ScriptDir" -ForegroundColor White
    Write-Host "  npm start" -ForegroundColor White
    Write-Host "`nOr for development mode with hot reload:" -ForegroundColor Cyan
    Write-Host "  npm run dev" -ForegroundColor White
}

#endregion

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Display quick start guide
if (-not $StartServer) {
    Write-Host "`nQuick Start Guide:" -ForegroundColor Yellow
    Write-Host "  1. Install dependencies: .\setup-d3-dashboard.ps1 -InstallDependencies" -ForegroundColor White
    Write-Host "  2. Start server: .\setup-d3-dashboard.ps1 -StartServer -OpenBrowser" -ForegroundColor White
    Write-Host "  3. Dev mode: .\setup-d3-dashboard.ps1 -StartServer -DevMode -OpenBrowser" -ForegroundColor White
    Write-Host "`nData Integration:" -ForegroundColor Yellow
    Write-Host "  Export CPG/semantic analysis data as JSON to:" -ForegroundColor White
    Write-Host "  $ScriptDir\public\static\data\" -ForegroundColor Green
}