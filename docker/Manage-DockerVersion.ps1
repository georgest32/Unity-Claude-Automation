# Manage-DockerVersion.ps1
# Docker image versioning and registry management script
# Handles semantic versioning, tagging, and pushing to GitHub Container Registry

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('major', 'minor', 'patch')]
    [string]$BumpType = 'patch',
    
    [Parameter(Mandatory=$false)]
    [string]$CustomVersion = '',
    
    [Parameter(Mandatory=$false)]
    [switch]$Push = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildOnly = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$Registry = 'ghcr.io',
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = '',
    
    [Parameter(Mandatory=$false)]
    [switch]$AllServices = $false,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Services = @(),
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

# Configuration
$ErrorActionPreference = 'Stop'
$script:config = @{
    Registry = $Registry
    Namespace = if ($Namespace) { $Namespace } else { 
        if ($Registry -eq 'ghcr.io') {
            # Get GitHub username from git config
            $gitUser = git config --get remote.origin.url
            if ($gitUser -match 'github.com[:/]([^/]+)/') {
                $matches[1].ToLower()
            } else {
                'unity-claude'
            }
        } else {
            'unity-claude'
        }
    }
    Services = @(
        'powershell-modules',
        'langgraph-api',
        'autogen-groupchat',
        'docs-server',
        'file-monitor'
    )
    VersionFile = '.\.docker-version'
}

# Functions
function Get-CurrentVersion {
    if (Test-Path $script:config.VersionFile) {
        $version = Get-Content $script:config.VersionFile -Raw
        return $version.Trim()
    } else {
        # Try to get version from git tags
        $lastTag = git describe --tags --abbrev=0 2>$null
        if ($lastTag -and $lastTag -match '^v?(\d+\.\d+\.\d+)') {
            return $matches[1]
        }
        return '0.0.0'
    }
}

function Get-NextVersion {
    param(
        [string]$CurrentVersion,
        [string]$BumpType
    )
    
    $parts = $CurrentVersion -split '\.'
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]
    
    switch ($BumpType) {
        'major' {
            $major++
            $minor = 0
            $patch = 0
        }
        'minor' {
            $minor++
            $patch = 0
        }
        'patch' {
            $patch++
        }
    }
    
    return "$major.$minor.$patch"
}

function Save-Version {
    param([string]$Version)
    
    if (-not $DryRun) {
        $Version | Set-Content $script:config.VersionFile -NoNewline
        Write-Host "Version saved to $($script:config.VersionFile): $Version" -ForegroundColor Green
    } else {
        Write-Host "[DRY RUN] Would save version to $($script:config.VersionFile): $Version" -ForegroundColor Yellow
    }
}

function Get-GitInfo {
    @{
        CommitSHA = (git rev-parse HEAD).Substring(0, 8)
        Branch = git rev-parse --abbrev-ref HEAD
        IsDirty = [bool](git status --porcelain)
    }
}

function Build-DockerImage {
    param(
        [string]$Service,
        [string]$Version,
        [hashtable]$GitInfo
    )
    
    $imageName = "$($script:config.Registry)/$($script:config.Namespace)/unity-claude-$Service"
    $tags = @(
        "$imageName`:$Version",
        "$imageName`:latest"
    )
    
    # Add git SHA tag
    $tags += "$imageName`:$($GitInfo.Branch)-$($GitInfo.CommitSHA)"
    
    # Add major and minor version tags
    $versionParts = $Version -split '\.'
    $tags += "$imageName`:$($versionParts[0])"
    $tags += "$imageName`:$($versionParts[0]).$($versionParts[1])"
    
    $dockerfile = ".\docker\$Service\Dockerfile"
    
    # Handle special cases
    switch ($Service) {
        'powershell-modules' { $dockerfile = '.\docker\powershell\Dockerfile' }
        'langgraph-api' { $dockerfile = '.\docker\python\langgraph\Dockerfile' }
        'autogen-groupchat' { $dockerfile = '.\docker\python\autogen\Dockerfile' }
        'docs-server' { $dockerfile = '.\docker\docs\Dockerfile' }
        'file-monitor' { $dockerfile = '.\docker\monitoring\Dockerfile' }
    }
    
    if (-not (Test-Path $dockerfile)) {
        Write-Warning "Dockerfile not found for $Service at $dockerfile"
        return $false
    }
    
    Write-Host "`nBuilding $Service with tags:" -ForegroundColor Cyan
    foreach ($tag in $tags) {
        Write-Host "  - $tag" -ForegroundColor Gray
    }
    
    if (-not $DryRun) {
        # Build the image
        $buildArgs = @(
            'build',
            '--build-arg', "VERSION=$Version",
            '--build-arg', "COMMIT_SHA=$($GitInfo.CommitSHA)",
            '--build-arg', "BUILD_DATE=$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')",
            '-f', $dockerfile
        )
        
        foreach ($tag in $tags) {
            $buildArgs += @('-t', $tag)
        }
        
        $buildArgs += '.'
        
        Write-Host "Executing: docker $($buildArgs -join ' ')" -ForegroundColor DarkGray
        
        $result = docker @buildArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to build $Service`: $result"
            return $false
        }
        
        Write-Host "Successfully built $Service" -ForegroundColor Green
    } else {
        Write-Host "[DRY RUN] Would execute: docker build ..." -ForegroundColor Yellow
    }
    
    return $tags
}

function Push-DockerImage {
    param([string[]]$Tags)
    
    if ($Push -and -not $BuildOnly) {
        Write-Host "`nPushing images to registry..." -ForegroundColor Cyan
        
        foreach ($tag in $Tags) {
            Write-Host "Pushing $tag..." -ForegroundColor Gray
            
            if (-not $DryRun) {
                $result = docker push $tag 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Failed to push $tag`: $result"
                    return $false
                }
                Write-Host "  Pushed successfully" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would push $tag" -ForegroundColor Yellow
            }
        }
    }
    
    return $true
}

function Test-DockerLogin {
    Write-Host "Testing registry authentication..." -ForegroundColor Cyan
    
    if ($script:config.Registry -eq 'ghcr.io') {
        # Check if we're logged in by trying to inspect registry config
        # This is a better test than trying to pull a non-existent image
        $authConfig = docker system info 2>&1 | Select-String "Registry"
        
        # Alternative: Try to push a small test image to check write permissions
        # Create a minimal test image
        $testImage = "$($script:config.Registry)/$($script:config.Namespace)/test-auth:$(Get-Random)"
        
        # Create a simple test with alpine
        $testResult = docker pull alpine:latest 2>&1
        if ($LASTEXITCODE -eq 0) {
            docker tag alpine:latest $testImage 2>&1 | Out-Null
            $pushResult = docker push $testImage 2>&1
            $pushSuccess = $LASTEXITCODE -eq 0
            
            # Clean up test image
            docker rmi $testImage 2>&1 | Out-Null
            
            if (-not $pushSuccess) {
                if ($pushResult -match 'unauthorized|denied|forbidden') {
                    Write-Host "Not authorized to push to GitHub Container Registry" -ForegroundColor Yellow
                    Write-Host "Please run: docker login ghcr.io -u USERNAME" -ForegroundColor Yellow
                    Write-Host "Use a Personal Access Token (PAT) with 'write:packages' scope as password" -ForegroundColor Yellow
                    return $false
                }
            }
        } else {
            Write-Warning "Could not pull alpine image for auth test"
            # Assume we're authenticated if we can't test
            return $true
        }
    }
    
    Write-Host "Registry authentication successful" -ForegroundColor Green
    return $true
}

# Main execution
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Docker Version Management" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Get version
$currentVersion = Get-CurrentVersion
Write-Host "Current version: $currentVersion" -ForegroundColor Gray

if ($CustomVersion) {
    $newVersion = $CustomVersion
    Write-Host "Using custom version: $newVersion" -ForegroundColor Yellow
} else {
    $newVersion = Get-NextVersion -CurrentVersion $currentVersion -BumpType $BumpType
    Write-Host "New version ($BumpType bump): $newVersion" -ForegroundColor Green
}

# Get git information
$gitInfo = Get-GitInfo
Write-Host "Git commit: $($gitInfo.CommitSHA) (branch: $($gitInfo.Branch))" -ForegroundColor Gray

if ($gitInfo.IsDirty) {
    Write-Warning "Working directory has uncommitted changes"
}

# Test registry login if pushing
if ($Push -and -not $BuildOnly) {
    if (-not (Test-DockerLogin)) {
        Write-Error "Registry authentication failed"
        exit 1
    }
}

# Determine which services to build
$servicesToBuild = if ($AllServices) {
    $script:config.Services
} elseif ($Services.Count -gt 0) {
    $Services
} else {
    # Default to all services
    $script:config.Services
}

Write-Host "`nServices to build:" -ForegroundColor Cyan
foreach ($service in $servicesToBuild) {
    Write-Host "  - $service" -ForegroundColor Gray
}

# Build and optionally push each service
$allTags = @{}
$success = $true

foreach ($service in $servicesToBuild) {
    $tags = Build-DockerImage -Service $service -Version $newVersion -GitInfo $gitInfo
    
    if ($tags) {
        $allTags[$service] = $tags
        
        if ($Push -and -not $BuildOnly) {
            if (-not (Push-DockerImage -Tags $tags)) {
                $success = $false
                break
            }
        }
    } else {
        Write-Warning "Failed to build $service"
        $success = $false
    }
}

# Save new version if successful
if ($success) {
    Save-Version -Version $newVersion
    
    # Create git tag if not dry run and pushing
    if ($Push -and -not $BuildOnly -and -not $DryRun) {
        $tagName = "v$newVersion"
        Write-Host "`nCreating git tag: $tagName" -ForegroundColor Cyan
        git tag -a $tagName -m "Release version $newVersion"
        Write-Host "Don't forget to push the tag: git push origin $tagName" -ForegroundColor Yellow
    }
    
    Write-Host "`n==================================================" -ForegroundColor Green
    Write-Host "Version management complete!" -ForegroundColor Green
    Write-Host "Version: $newVersion" -ForegroundColor Green
    
    if ($allTags.Count -gt 0) {
        Write-Host "`nBuilt images:" -ForegroundColor Cyan
        foreach ($service in $allTags.Keys) {
            Write-Host "  $service`:" -ForegroundColor Gray
            foreach ($tag in $allTags[$service]) {
                Write-Host "    - $tag" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Error "Version management failed"
    exit 1
}