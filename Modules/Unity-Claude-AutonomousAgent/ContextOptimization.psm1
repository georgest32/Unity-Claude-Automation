# ContextOptimization.psm1
# Phase 3 Day 16: Advanced Context Optimization and Cross-Conversation Memory Systems
# Provides advanced memory optimization, multimodal context integration, user profiles, and cross-conversation memory tracking

# Module-level variables
$script:WorkingMemoryPath = Join-Path $PSScriptRoot "CLAUDE_CONTEXT.json"
$script:SessionArchivePath = Join-Path $PSScriptRoot "SessionArchive"
$script:MaxContextSize = 4000  # Maximum characters for context
$script:ContextRelevanceThreshold = 0.5
$script:SessionExpirationHours = 24

# Day 16 Enhancement: Advanced Memory Systems Variables
$script:UserProfilesPath = Join-Path $PSScriptRoot "UserProfiles"
$script:ConversationPatternsPath = Join-Path $PSScriptRoot "ConversationPatterns.json"
$script:CrossConversationMemoryPath = Join-Path $PSScriptRoot "CrossConversationMemory.json"
$script:UserProfiles = @{}
$script:ConversationPatterns = @{}
$script:CrossConversationMemory = @{}
$script:MaxUserProfileHistory = 100
$script:MaxPatternStorage = 200
$script:ContextCompressionRatio = 0.3

# Logging configuration
$script:LogPath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "unity_claude_automation.log"
$script:LogMutex = [System.Threading.Mutex]::new($false, "UnityClaudeAutomationLogMutex")

function Write-ContextLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "ContextOptimization"
    )
    
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] [$Component] $Message"
        
        # Thread-safe file writing
        $acquired = $script:LogMutex.WaitOne(1000)
        if ($acquired) {
            try {
                Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue
            }
            finally {
                $script:LogMutex.ReleaseMutex()
            }
        }
    }
    catch {
        Write-Verbose "Failed to write log: $_"
    }
}

function Initialize-WorkingMemory {
    <#
    .SYNOPSIS
    Initializes the working memory system
    
    .DESCRIPTION
    Creates or loads the working memory file for context storage
    
    .PARAMETER Clean
    Start with clean working memory
    #>
    param(
        [switch]$Clean
    )
    
    Write-ContextLog "Initializing working memory system" -Level "INFO"
    
    try {
        if ($Clean -or -not (Test-Path $script:WorkingMemoryPath)) {
            # Create new working memory structure
            $workingMemory = @{
                Version = "2.0.0"
                Created = Get-Date
                LastModified = Get-Date
                SessionId = $null
                Context = @{
                    CurrentTask = ""
                    PreviousCommands = @()
                    RecentErrors = @()
                    KeyInsights = @()
                    UnityState = @{}
                    ClaudeResponses = @()
                }
                Statistics = @{
                    TotalInteractions = 0
                    CompressionCount = 0
                    LastCompression = $null
                }
            }
            
            $workingMemory | ConvertTo-Json -Depth 10 | Set-Content -Path $script:WorkingMemoryPath -Force
            Write-ContextLog "Created new working memory file" -Level "SUCCESS"
        }
        else {
            Write-ContextLog "Working memory file already exists" -Level "INFO"
        }
        
        # Ensure session archive directory exists
        if (-not (Test-Path $script:SessionArchivePath)) {
            New-Item -ItemType Directory -Path $script:SessionArchivePath -Force | Out-Null
            Write-ContextLog "Created session archive directory" -Level "INFO"
        }
        
        return @{
            Success = $true
            MemoryPath = $script:WorkingMemoryPath
        }
    }
    catch {
        Write-ContextLog "Failed to initialize working memory: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Add-ContextItem {
    <#
    .SYNOPSIS
    Adds an item to working memory context
    
    .DESCRIPTION
    Intelligently adds context items with relevance scoring and compression
    
    .PARAMETER Type
    Type of context item
    
    .PARAMETER Content
    The content to add
    
    .PARAMETER Priority
    Priority level (High, Medium, Low)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Command", "Error", "Insight", "Response", "State")]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [ValidateSet("High", "Medium", "Low")]
        [string]$Priority = "Medium"
    )
    
    Write-ContextLog "Adding context item of type: $Type" -Level "DEBUG"
    
    try {
        # Load current working memory
        $workingMemory = Get-Content $script:WorkingMemoryPath -Raw | ConvertFrom-Json
        
        # Create context item with metadata
        $contextItem = @{
            Content = $Content
            Timestamp = Get-Date
            Priority = $Priority
            Relevance = 1.0  # Initial relevance is maximum
        }
        
        # Add to appropriate context section
        switch ($Type) {
            "Command" {
                # Convert to proper array if needed
                if ($null -eq $workingMemory.Context.PreviousCommands) {
                    $workingMemory.Context.PreviousCommands = @()
                }
                $commands = @($workingMemory.Context.PreviousCommands)
                $commands += $contextItem
                
                # Keep only recent high-relevance commands
                if ($commands.Count -gt 10) {
                    $commands = $commands | Select-Object -Last 10
                }
                $workingMemory.Context.PreviousCommands = $commands
            }
            "Error" {
                if ($null -eq $workingMemory.Context.RecentErrors) {
                    $workingMemory.Context.RecentErrors = @()
                }
                $errors = @($workingMemory.Context.RecentErrors)
                $errors += $contextItem
                
                # Keep only recent errors
                if ($errors.Count -gt 5) {
                    $errors = $errors | Select-Object -Last 5
                }
                $workingMemory.Context.RecentErrors = $errors
            }
            "Insight" {
                if ($null -eq $workingMemory.Context.KeyInsights) {
                    $workingMemory.Context.KeyInsights = @()
                }
                $insights = @($workingMemory.Context.KeyInsights)
                $insights += $contextItem
                
                # Keep high-priority insights
                if ($insights.Count -gt 15) {
                    $insights = $insights | Sort-Object { $_.Priority } -Descending | Select-Object -First 15
                }
                $workingMemory.Context.KeyInsights = $insights
            }
            "Response" {
                if ($null -eq $workingMemory.Context.ClaudeResponses) {
                    $workingMemory.Context.ClaudeResponses = @()
                }
                $responses = @($workingMemory.Context.ClaudeResponses)
                $responses += $contextItem
                
                # Keep only recent responses
                if ($responses.Count -gt 5) {
                    $responses = $responses | Select-Object -Last 5
                }
                $workingMemory.Context.ClaudeResponses = $responses
            }
            "State" {
                # Update Unity state information
                $workingMemory.Context.UnityState = $contextItem
            }
        }
        
        # Update statistics
        $workingMemory.LastModified = Get-Date
        $workingMemory.Statistics.TotalInteractions = [int]$workingMemory.Statistics.TotalInteractions + 1
        
        # Check if compression needed
        $contextSize = ($workingMemory | ConvertTo-Json -Depth 10).Length
        if ($contextSize -gt ($script:MaxContextSize * 2)) {
            Write-ContextLog "Context size ($contextSize) exceeds threshold, compressing" -Level "INFO"
            $compressionResult = Compress-Context -WorkingMemory $workingMemory
            if ($compressionResult.Success) {
                $workingMemory = $compressionResult.CompressedMemory
            }
        }
        
        # Save working memory
        $workingMemory | ConvertTo-Json -Depth 10 | Set-Content -Path $script:WorkingMemoryPath -Force
        
        Write-ContextLog "Added context item successfully" -Level "SUCCESS"
        
        return @{
            Success = $true
            ContextSize = $contextSize
            Type = $Type
        }
    }
    catch {
        Write-ContextLog "Failed to add context item: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Compress-Context {
    <#
    .SYNOPSIS
    Compresses working memory context
    
    .DESCRIPTION
    Applies intelligent compression to reduce context size while preserving important information
    
    .PARAMETER WorkingMemory
    The working memory object to compress
    #>
    param(
        [Parameter(Mandatory = $true)]
        $WorkingMemory
    )
    
    Write-ContextLog "Compressing context" -Level "INFO"
    
    try {
        # Summarize previous commands (keep only unique patterns)
        if ($WorkingMemory.Context.PreviousCommands.Count -gt 5) {
            $uniqueCommands = @{}
            foreach ($cmd in $WorkingMemory.Context.PreviousCommands) {
                # Extract command pattern (first word)
                $pattern = if ($cmd.Content -match '^(\S+)') { $matches[1] } else { "unknown" }
                if (-not $uniqueCommands.ContainsKey($pattern)) {
                    $uniqueCommands[$pattern] = $cmd
                }
            }
            $WorkingMemory.Context.PreviousCommands = @($uniqueCommands.Values) | Select-Object -Last 5
        }
        
        # Compress errors (keep only unique error codes)
        if ($WorkingMemory.Context.RecentErrors.Count -gt 3) {
            $uniqueErrors = @{}
            foreach ($err in $WorkingMemory.Context.RecentErrors) {
                # Extract error code if present
                $errorCode = if ($err.Content -match 'CS\d{4}') { $matches[0] } else { "general" }
                if (-not $uniqueErrors.ContainsKey($errorCode)) {
                    $uniqueErrors[$errorCode] = $err
                }
            }
            $WorkingMemory.Context.RecentErrors = @($uniqueErrors.Values) | Select-Object -Last 3
        }
        
        # Filter insights by relevance
        if ($WorkingMemory.Context.KeyInsights.Count -gt 10) {
            $WorkingMemory.Context.KeyInsights = @($WorkingMemory.Context.KeyInsights) | 
                Where-Object { $_.Priority -in @("High", "Medium") } |
                Select-Object -Last 10
        }
        
        # Truncate Claude responses (keep summary only)
        if ($WorkingMemory.Context.ClaudeResponses.Count -gt 3) {
            $compressedResponses = @()
            foreach ($response in ($WorkingMemory.Context.ClaudeResponses | Select-Object -Last 3)) {
                $compressed = @{
                    Timestamp = $response.Timestamp
                    Priority = $response.Priority
                    Content = if ($response.Content.Length -gt 200) {
                        $response.Content.Substring(0, 197) + "..."
                    } else {
                        $response.Content
                    }
                }
                $compressedResponses += $compressed
            }
            $WorkingMemory.Context.ClaudeResponses = $compressedResponses
        }
        
        # Update compression statistics
        $WorkingMemory.Statistics.CompressionCount++
        $WorkingMemory.Statistics.LastCompression = Get-Date
        
        Write-ContextLog "Context compression completed" -Level "SUCCESS"
        
        return @{
            Success = $true
            CompressedMemory = $WorkingMemory
        }
    }
    catch {
        Write-ContextLog "Failed to compress context: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-OptimizedContext {
    <#
    .SYNOPSIS
    Gets optimized context for prompt generation
    
    .DESCRIPTION
    Returns intelligently selected and formatted context within size limits
    
    .PARAMETER MaxSize
    Maximum size of context in characters
    
    .PARAMETER Focus
    Focus area for context selection
    #>
    param(
        [int]$MaxSize = 2000,
        
        [ValidateSet("", "Errors", "Commands", "Insights", "Recent")]
        [string]$Focus = ""
    )
    
    Write-ContextLog "Getting optimized context (MaxSize: $MaxSize, Focus: $Focus)" -Level "DEBUG"
    
    try {
        # Load working memory
        $workingMemory = Get-Content $script:WorkingMemoryPath -Raw | ConvertFrom-Json
        
        # Build prioritized context
        $context = @{
            SessionInfo = @{
                SessionId = $workingMemory.SessionId
                LastModified = $workingMemory.LastModified
            }
            CurrentTask = $workingMemory.Context.CurrentTask
            Context = @{}
        }
        
        # Add focused content first
        $currentSize = 0
        
        switch ($Focus) {
            "Errors" {
                if ($workingMemory.Context.RecentErrors.Count -gt 0) {
                    $context.Context.RecentErrors = @($workingMemory.Context.RecentErrors) | Select-Object -Last 3
                    $currentSize = ($context | ConvertTo-Json -Depth 10).Length
                }
            }
            "Commands" {
                if ($workingMemory.Context.PreviousCommands.Count -gt 0) {
                    $context.Context.PreviousCommands = @($workingMemory.Context.PreviousCommands) | Select-Object -Last 5
                    $currentSize = ($context | ConvertTo-Json -Depth 10).Length
                }
            }
            "Insights" {
                if ($workingMemory.Context.KeyInsights.Count -gt 0) {
                    $context.Context.KeyInsights = @($workingMemory.Context.KeyInsights) | 
                        Where-Object { $_.Priority -eq "High" } |
                        Select-Object -Last 5
                    $currentSize = ($context | ConvertTo-Json -Depth 10).Length
                }
            }
            "Recent" {
                if ($workingMemory.Context.ClaudeResponses.Count -gt 0) {
                    $context.Context.LastResponse = @($workingMemory.Context.ClaudeResponses) | Select-Object -Last 1
                    $currentSize = ($context | ConvertTo-Json -Depth 10).Length
                }
            }
            default {
                # Balanced context selection
                if ($workingMemory.Context.RecentErrors.Count -gt 0) {
                    $context.Context.LastError = @($workingMemory.Context.RecentErrors) | Select-Object -Last 1
                }
                if ($workingMemory.Context.PreviousCommands.Count -gt 0) {
                    $context.Context.LastCommand = @($workingMemory.Context.PreviousCommands) | Select-Object -Last 1
                }
                if ($workingMemory.Context.KeyInsights.Count -gt 0) {
                    $context.Context.TopInsight = @($workingMemory.Context.KeyInsights) | 
                        Where-Object { $_.Priority -eq "High" } |
                        Select-Object -First 1
                }
                $currentSize = ($context | ConvertTo-Json -Depth 10).Length
            }
        }
        
        # Add Unity state if space available
        if ($currentSize -lt $MaxSize -and $workingMemory.Context.UnityState) {
            $context.Context.UnityState = $workingMemory.Context.UnityState
            $currentSize = ($context | ConvertTo-Json -Depth 10).Length
        }
        
        # Trim if still too large
        if ($currentSize -gt $MaxSize) {
            Write-ContextLog "Context size ($currentSize) exceeds max ($MaxSize), trimming" -Level "DEBUG"
            
            # Remove lowest priority items
            if ($context.Context.KeyInsights) {
                $context.Context.KeyInsights = @($context.Context.KeyInsights) | Select-Object -First 3
            }
            if ($context.Context.PreviousCommands) {
                $context.Context.PreviousCommands = @($context.Context.PreviousCommands) | Select-Object -Last 3
            }
        }
        
        Write-ContextLog "Generated optimized context (Size: $currentSize)" -Level "INFO"
        
        return @{
            Success = $true
            Context = $context
            Size = $currentSize
        }
    }
    catch {
        Write-ContextLog "Failed to get optimized context: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Calculate-ContextRelevance {
    <#
    .SYNOPSIS
    Calculates relevance score for context items
    
    .DESCRIPTION
    Scores context items based on age, frequency, and importance
    
    .PARAMETER Item
    The context item to score
    
    .PARAMETER CurrentTask
    Current task for relevance comparison
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Item,
        
        [string]$CurrentTask = ""
    )
    
    Write-ContextLog "Calculating context relevance" -Level "DEBUG"
    
    try {
        $relevance = 1.0
        
        # Age decay (items older than 1 hour lose relevance)
        if ($Item.Timestamp) {
            $age = (Get-Date) - [datetime]$Item.Timestamp
            if ($age.TotalHours -gt 1) {
                $relevance *= [Math]::Max(0.1, 1.0 - ($age.TotalHours / 24))
            }
        }
        
        # Priority boost
        if ($Item.Priority) {
            switch ($Item.Priority) {
                "High" { $relevance *= 1.5 }
                "Medium" { $relevance *= 1.0 }
                "Low" { $relevance *= 0.5 }
            }
        }
        
        # Task relevance (if content matches current task keywords)
        if (![string]::IsNullOrEmpty($CurrentTask) -and $Item.Content) {
            $taskWords = $CurrentTask -split '\s+' | Where-Object { $_.Length -gt 3 }
            $matches = 0
            foreach ($word in $taskWords) {
                if ($Item.Content -match "\b$word\b") {
                    $matches++
                }
            }
            if ($matches -gt 0) {
                $relevance *= (1.0 + ($matches * 0.2))
            }
        }
        
        # Cap relevance at reasonable maximum
        $relevance = [Math]::Min(2.0, $relevance)
        
        Write-ContextLog "Calculated relevance: $relevance" -Level "DEBUG"
        
        return @{
            Success = $true
            Relevance = [Math]::Round($relevance, 2)
        }
    }
    catch {
        Write-ContextLog "Failed to calculate relevance: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function New-SessionIdentifier {
    <#
    .SYNOPSIS
    Generates a new session identifier
    
    .DESCRIPTION
    Creates unique session ID with metadata
    #>
    
    Write-ContextLog "Generating new session identifier" -Level "DEBUG"
    
    try {
        $sessionId = [Guid]::NewGuid().ToString()
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fullSessionId = "$timestamp-$sessionId"
        
        Write-ContextLog "Generated session ID: $fullSessionId" -Level "INFO"
        
        return @{
            Success = $true
            SessionId = $fullSessionId
            ShortId = $sessionId.Substring(0, 8)
        }
    }
    catch {
        Write-ContextLog "Failed to generate session ID: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Save-SessionState {
    <#
    .SYNOPSIS
    Saves current session state
    
    .DESCRIPTION
    Persists session information for recovery
    
    .PARAMETER SessionId
    The session identifier
    
    .PARAMETER State
    Session state data to save
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$State
    )
    
    Write-ContextLog "Saving session state for: $SessionId" -Level "DEBUG"
    
    try {
        $sessionFile = Join-Path $script:SessionArchivePath "$SessionId.json"
        
        $sessionData = @{
            SessionId = $SessionId
            SavedAt = Get-Date
            State = $State
        }
        
        $sessionData | ConvertTo-Json -Depth 10 | Set-Content -Path $sessionFile -Force
        
        Write-ContextLog "Session state saved to: $sessionFile" -Level "SUCCESS"
        
        return @{
            Success = $true
            FilePath = $sessionFile
        }
    }
    catch {
        Write-ContextLog "Failed to save session state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Restore-SessionState {
    <#
    .SYNOPSIS
    Restores a previous session state
    
    .DESCRIPTION
    Loads session information from archive
    
    .PARAMETER SessionId
    The session identifier to restore
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId
    )
    
    Write-ContextLog "Restoring session state for: $SessionId" -Level "DEBUG"
    
    try {
        $sessionFile = Join-Path $script:SessionArchivePath "$SessionId.json"
        
        if (-not (Test-Path $sessionFile)) {
            Write-ContextLog "Session file not found: $sessionFile" -Level "WARNING"
            return @{
                Success = $false
                Error = "Session file not found"
            }
        }
        
        $sessionData = Get-Content $sessionFile -Raw | ConvertFrom-Json
        
        # Check if session is expired
        $savedAt = [datetime]$sessionData.SavedAt
        $age = (Get-Date) - $savedAt
        
        if ($age.TotalHours -gt $script:SessionExpirationHours) {
            Write-ContextLog "Session expired (Age: $($age.TotalHours) hours)" -Level "WARNING"
            return @{
                Success = $false
                Error = "Session expired"
                Age = $age.TotalHours
            }
        }
        
        Write-ContextLog "Session state restored successfully" -Level "SUCCESS"
        
        return @{
            Success = $true
            State = $sessionData.State
            SavedAt = $savedAt
            AgeHours = [Math]::Round($age.TotalHours, 2)
        }
    }
    catch {
        Write-ContextLog "Failed to restore session state: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-SessionList {
    <#
    .SYNOPSIS
    Gets list of available sessions
    
    .DESCRIPTION
    Returns information about archived sessions
    
    .PARAMETER IncludeExpired
    Include expired sessions in the list
    #>
    param(
        [switch]$IncludeExpired
    )
    
    Write-ContextLog "Getting session list" -Level "DEBUG"
    
    try {
        $sessions = @()
        $sessionFiles = Get-ChildItem -Path $script:SessionArchivePath -Filter "*.json" -ErrorAction SilentlyContinue
        
        foreach ($file in $sessionFiles) {
            try {
                $sessionData = Get-Content $file.FullName -Raw | ConvertFrom-Json
                $savedAt = [datetime]$sessionData.SavedAt
                $age = (Get-Date) - $savedAt
                $expired = $age.TotalHours -gt $script:SessionExpirationHours
                
                if (-not $expired -or $IncludeExpired) {
                    $sessions += @{
                        SessionId = $sessionData.SessionId
                        SavedAt = $savedAt
                        AgeHours = [Math]::Round($age.TotalHours, 2)
                        Expired = $expired
                        FilePath = $file.FullName
                    }
                }
            }
            catch {
                Write-ContextLog "Failed to read session file: $($file.Name)" -Level "WARNING"
            }
        }
        
        # Sort by save time (newest first)
        $sessions = $sessions | Sort-Object SavedAt -Descending
        
        Write-ContextLog "Found $($sessions.Count) sessions" -Level "INFO"
        
        return @{
            Success = $true
            Sessions = $sessions
            TotalCount = $sessions.Count
        }
    }
    catch {
        Write-ContextLog "Failed to get session list: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Clear-ExpiredSessions {
    <#
    .SYNOPSIS
    Removes expired session files
    
    .DESCRIPTION
    Cleans up old session archives to save space
    #>
    
    Write-ContextLog "Clearing expired sessions" -Level "INFO"
    
    try {
        $removedCount = 0
        $sessionFiles = Get-ChildItem -Path $script:SessionArchivePath -Filter "*.json" -ErrorAction SilentlyContinue
        
        foreach ($file in $sessionFiles) {
            try {
                $sessionData = Get-Content $file.FullName -Raw | ConvertFrom-Json
                $savedAt = [datetime]$sessionData.SavedAt
                $age = (Get-Date) - $savedAt
                
                if ($age.TotalHours -gt $script:SessionExpirationHours) {
                    Remove-Item $file.FullName -Force
                    $removedCount++
                    Write-ContextLog "Removed expired session: $($sessionData.SessionId)" -Level "DEBUG"
                }
            }
            catch {
                Write-ContextLog "Failed to process session file: $($file.Name)" -Level "WARNING"
            }
        }
        
        Write-ContextLog "Removed $removedCount expired sessions" -Level "SUCCESS"
        
        return @{
            Success = $true
            RemovedCount = $removedCount
        }
    }
    catch {
        Write-ContextLog "Failed to clear expired sessions: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ContextSummary {
    <#
    .SYNOPSIS
    Gets a summary of current context state
    
    .DESCRIPTION
    Returns statistics and overview of working memory
    #>
    
    Write-ContextLog "Getting context summary" -Level "DEBUG"
    
    try {
        # Load working memory
        $workingMemory = Get-Content $script:WorkingMemoryPath -Raw | ConvertFrom-Json
        
        $summary = @{
            SessionId = $workingMemory.SessionId
            Created = $workingMemory.Created
            LastModified = $workingMemory.LastModified
            Statistics = $workingMemory.Statistics
            ContextCounts = @{
                Commands = if ($workingMemory.Context.PreviousCommands) { @($workingMemory.Context.PreviousCommands).Count } else { 0 }
                Errors = if ($workingMemory.Context.RecentErrors) { @($workingMemory.Context.RecentErrors).Count } else { 0 }
                Insights = if ($workingMemory.Context.KeyInsights) { @($workingMemory.Context.KeyInsights).Count } else { 0 }
                Responses = if ($workingMemory.Context.ClaudeResponses) { @($workingMemory.Context.ClaudeResponses).Count } else { 0 }
            }
            MemorySize = (Get-Item $script:WorkingMemoryPath).Length
        }
        
        Write-ContextLog "Generated context summary" -Level "INFO"
        
        return @{
            Success = $true
            Summary = $summary
        }
    }
    catch {
        Write-ContextLog "Failed to get context summary: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Day 16 Enhancement: Advanced Memory Systems Functions

function Initialize-UserProfile {
    <#
    .SYNOPSIS
    Initializes or loads user profile with preference tracking
    
    .DESCRIPTION
    Creates comprehensive user profiles with interaction patterns, preferences, and historical data
    
    .PARAMETER UserId
    Unique identifier for the user
    
    .PARAMETER LoadExisting
    Whether to load existing profile data
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserId,
        
        [switch]$LoadExisting
    )
    
    Write-ContextLog "Initializing user profile for: $UserId" -Level "INFO"
    
    try {
        # Ensure user profiles directory exists
        if (-not (Test-Path $script:UserProfilesPath)) {
            New-Item -Path $script:UserProfilesPath -ItemType Directory -Force | Out-Null
            Write-ContextLog "Created user profiles directory" -Level "INFO"
        }
        
        $userProfilePath = Join-Path $script:UserProfilesPath "$UserId.json"
        
        # Initialize default user profile
        $userProfile = @{
            UserId = $UserId
            CreatedAt = Get-Date
            LastActive = Get-Date
            InteractionCount = 0
            Preferences = @{
                CommunicationStyle = "Professional"
                VerbosityLevel = "Medium"
                PreferredTopics = @()
                AvoidedTopics = @()
                ResponseFormat = "Structured"
                TechnicalLevel = "Intermediate"
            }
            BehaviorPatterns = @{
                AverageSessionLength = 0
                CommonQuestionTypes = @{}
                PreferredTimeSlots = @{}
                ConversationStyles = @{}
                SuccessfulInteractionPatterns = @()
            }
            HistoricalData = @{
                TotalConversations = 0
                SuccessfulOutcomes = 0
                AverageResponseTime = 0
                MostEffectivePrompts = @()
                LearningProgression = @()
            }
            ContextMemory = @{
                FrequentlyUsedTerms = @{}
                ImportantFileReferences = @()
                RecurringProblems = @()
                SolutionPreferences = @{}
            }
        }
        
        # Load existing profile if requested and available
        if ($LoadExisting -and (Test-Path $userProfilePath)) {
            Write-ContextLog "Loading existing user profile from: $userProfilePath" -Level "INFO"
            $existingProfile = Get-Content $userProfilePath -Raw | ConvertFrom-Json
            
            # Merge with default structure to ensure all fields exist
            foreach ($key in $userProfile.Keys) {
                if ($existingProfile.PSObject.Properties.Name -contains $key) {
                    $userProfile[$key] = $existingProfile.$key
                }
            }
            
            Write-ContextLog "Loaded existing user profile with $($existingProfile.InteractionCount) interactions" -Level "INFO"
        }
        
        # Store in memory
        $script:UserProfiles[$UserId] = $userProfile
        
        # Save profile
        Save-UserProfile -UserId $UserId
        
        Write-ContextLog "User profile initialized successfully: $UserId" -Level "SUCCESS"
        
        return @{
            Success = $true
            UserId = $UserId
            Profile = $userProfile
            IsNew = -not ($LoadExisting -and (Test-Path $userProfilePath))
        }
    }
    catch {
        Write-ContextLog "Failed to initialize user profile: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Update-UserProfile {
    <#
    .SYNOPSIS
    Updates user profile with interaction data and learned preferences
    
    .DESCRIPTION
    Updates user profile based on conversation patterns, preferences, and effectiveness
    
    .PARAMETER UserId
    User identifier
    
    .PARAMETER InteractionData
    Data from the current interaction
    
    .PARAMETER PreferenceUpdates
    Updated preferences discovered during interaction
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$UserId,
        
        [hashtable]$InteractionData = @{},
        
        [hashtable]$PreferenceUpdates = @{}
    )
    
    Write-ContextLog "Updating user profile for: $UserId" -Level "DEBUG"
    
    try {
        if (-not $script:UserProfiles.ContainsKey($UserId)) {
            Write-ContextLog "User profile not found, initializing: $UserId" -Level "WARNING"
            Initialize-UserProfile -UserId $UserId | Out-Null
        }
        
        $profile = $script:UserProfiles[$UserId]
        $updated = $false
        
        # Update basic activity tracking
        $profile.LastActive = Get-Date
        $profile.InteractionCount = [int]$profile.InteractionCount + 1
        $updated = $true
        
        # Update interaction data
        if ($InteractionData.Count -gt 0) {
            if ($InteractionData.ContainsKey("SessionLength")) {
                $currentAvg = $profile.BehaviorPatterns.AverageSessionLength
                $newLength = $InteractionData.SessionLength
                $profile.BehaviorPatterns.AverageSessionLength = ($currentAvg + $newLength) / 2
                $updated = $true
            }
            
            if ($InteractionData.ContainsKey("QuestionType")) {
                $questionType = $InteractionData.QuestionType
                if (-not $profile.BehaviorPatterns.CommonQuestionTypes.ContainsKey($questionType)) {
                    $profile.BehaviorPatterns.CommonQuestionTypes[$questionType] = 0
                }
                $currentValue = $profile.BehaviorPatterns.CommonQuestionTypes[$questionType]
                $profile.BehaviorPatterns.CommonQuestionTypes[$questionType] = [int]$currentValue + 1
                $updated = $true
            }
            
            if ($InteractionData.ContainsKey("ResponseTime")) {
                $currentAvg = $profile.HistoricalData.AverageResponseTime
                $newTime = $InteractionData.ResponseTime
                $profile.HistoricalData.AverageResponseTime = ($currentAvg + $newTime) / 2
                $updated = $true
            }
        }
        
        # Update preferences
        if ($PreferenceUpdates.Count -gt 0) {
            foreach ($prefKey in $PreferenceUpdates.Keys) {
                if ($profile.Preferences.ContainsKey($prefKey)) {
                    $profile.Preferences[$prefKey] = $PreferenceUpdates[$prefKey]
                    $updated = $true
                    Write-ContextLog "Updated preference $prefKey to $($PreferenceUpdates[$prefKey])" -Level "DEBUG"
                }
            }
        }
        
        if ($updated) {
            Save-UserProfile -UserId $UserId
            Write-ContextLog "User profile updated successfully: $UserId" -Level "SUCCESS"
        }
        
        return @{
            Success = $true
            Updated = $updated
            Profile = $profile
        }
    }
    catch {
        Write-ContextLog "Failed to update user profile: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Add-ConversationPattern {
    <#
    .SYNOPSIS
    Adds conversation pattern for learning and recognition
    
    .DESCRIPTION
    Tracks conversation patterns for future optimization and personalization
    
    .PARAMETER PatternType
    Type of pattern (Flow, Intent, Response, Effectiveness)
    
    .PARAMETER PatternData
    Pattern data and metadata
    
    .PARAMETER EffectivenessScore
    Effectiveness score for this pattern
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Flow", "Intent", "Response", "Effectiveness")]
        [string]$PatternType,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$PatternData,
        
        [double]$EffectivenessScore = 0.0
    )
    
    Write-ContextLog "Adding conversation pattern: $PatternType" -Level "DEBUG"
    
    try {
        if (-not $script:ConversationPatterns.ContainsKey($PatternType)) {
            $script:ConversationPatterns[$PatternType] = @()
        }
        
        $pattern = @{
            Id = [Guid]::NewGuid().ToString()
            Type = $PatternType
            Data = $PatternData
            EffectivenessScore = $EffectivenessScore
            Frequency = 1
            FirstSeen = Get-Date
            LastSeen = Get-Date
            UsageCount = 1
        }
        
        # Check if similar pattern exists
        $existingPattern = $script:ConversationPatterns[$PatternType] | Where-Object {
            $similarity = Calculate-PatternSimilarity -Pattern1 $_.Data -Pattern2 $PatternData
            $similarity -gt 0.8
        } | Select-Object -First 1
        
        if ($existingPattern) {
            # Update existing pattern
            $existingPattern.Frequency = [int]$existingPattern.Frequency + 1
            $existingPattern.UsageCount = [int]$existingPattern.UsageCount + 1
            $existingPattern.LastSeen = Get-Date
            $existingPattern.EffectivenessScore = ($existingPattern.EffectivenessScore + $EffectivenessScore) / 2
            Write-ContextLog "Updated existing pattern: $($existingPattern.Id)" -Level "DEBUG"
        } else {
            # Add new pattern
            $script:ConversationPatterns[$PatternType] += $pattern
            
            # Maintain pattern storage limit
            if ($script:ConversationPatterns[$PatternType].Count -gt $script:MaxPatternStorage) {
                $script:ConversationPatterns[$PatternType] = $script:ConversationPatterns[$PatternType] | 
                    Sort-Object LastSeen -Descending | 
                    Select-Object -First $script:MaxPatternStorage
                Write-ContextLog "Pruned old patterns, keeping $script:MaxPatternStorage most recent" -Level "DEBUG"
            }
            
            Write-ContextLog "Added new conversation pattern: $($pattern.Id)" -Level "SUCCESS"
        }
        
        # Save patterns
        Save-ConversationPatterns
        
        return @{
            Success = $true
            PatternId = if ($existingPattern) { $existingPattern.Id } else { $pattern.Id }
            IsNew = -not $existingPattern
        }
    }
    catch {
        Write-ContextLog "Failed to add conversation pattern: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-CrossConversationMemory {
    <#
    .SYNOPSIS
    Retrieves cross-conversation memory with relevance scoring
    
    .DESCRIPTION
    Returns relevant information from previous conversations with time decay and relevance scoring
    
    .PARAMETER Query
    Query string for memory retrieval
    
    .PARAMETER MaxResults
    Maximum number of results to return
    
    .PARAMETER MinRelevance
    Minimum relevance threshold
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [int]$MaxResults = 10,
        
        [double]$MinRelevance = 0.3
    )
    
    Write-ContextLog "Retrieving cross-conversation memory for query: $Query" -Level "DEBUG"
    
    try {
        $relevantMemories = @()
        
        if ($script:CrossConversationMemory.Count -eq 0) {
            Write-ContextLog "No cross-conversation memory available" -Level "DEBUG"
            return @{
                Success = $true
                Memories = @()
                TotalFound = 0
            }
        }
        
        foreach ($memoryKey in $script:CrossConversationMemory.Keys) {
            $memory = $script:CrossConversationMemory[$memoryKey]
            
            # Calculate relevance score
            $relevanceScore = Calculate-MemoryRelevance -Query $Query -Memory $memory
            
            # Apply time decay
            $timeDelta = (Get-Date) - [DateTime]$memory.Timestamp
            $timeDecay = [Math]::Exp(-$timeDelta.TotalDays / 30)  # 30-day half-life
            $finalScore = $relevanceScore * $timeDecay
            
            if ($finalScore -ge $MinRelevance) {
                $relevantMemories += @{
                    Memory = $memory
                    RelevanceScore = $finalScore
                    TimeDelta = $timeDelta.TotalDays
                }
            }
        }
        
        # Sort by relevance and limit results
        $sortedMemories = $relevantMemories | Sort-Object RelevanceScore -Descending | Select-Object -First $MaxResults
        
        Write-ContextLog "Retrieved $($sortedMemories.Count) relevant memories" -Level "INFO"
        
        return @{
            Success = $true
            Memories = $sortedMemories
            TotalFound = $relevantMemories.Count
            QueryProcessed = $Query
        }
    }
    catch {
        Write-ContextLog "Failed to retrieve cross-conversation memory: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Add-CrossConversationMemory {
    <#
    .SYNOPSIS
    Adds memory item for cross-conversation persistence
    
    .DESCRIPTION
    Stores important conversation elements for future reference across sessions
    
    .PARAMETER Type
    Type of memory (Solution, Problem, Insight, Context)
    
    .PARAMETER Content
    Memory content
    
    .PARAMETER Keywords
    Keywords for retrieval
    
    .PARAMETER Importance
    Importance level (High, Medium, Low)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Solution", "Problem", "Insight", "Context")]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [string[]]$Keywords = @(),
        
        [ValidateSet("High", "Medium", "Low")]
        [string]$Importance = "Medium"
    )
    
    Write-ContextLog "Adding cross-conversation memory: $Type" -Level "DEBUG"
    
    try {
        $memoryId = [Guid]::NewGuid().ToString()
        
        $memory = @{
            Id = $memoryId
            Type = $Type
            Content = $Content
            Keywords = $Keywords
            Importance = $Importance
            Timestamp = Get-Date
            AccessCount = 0
            LastAccessed = $null
            EffectivenessScore = 0.0
            RelatedConversations = @()
        }
        
        $script:CrossConversationMemory[$memoryId] = $memory
        
        # Save cross-conversation memory
        Save-CrossConversationMemory
        
        Write-ContextLog "Added cross-conversation memory: $memoryId" -Level "SUCCESS"
        
        return @{
            Success = $true
            MemoryId = $memoryId
            TotalMemories = $script:CrossConversationMemory.Count
        }
    }
    catch {
        Write-ContextLog "Failed to add cross-conversation memory: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Helper functions for Day 16 enhancements

function Calculate-PatternSimilarity {
    param(
        [hashtable]$Pattern1,
        [hashtable]$Pattern2
    )
    
    # Simple similarity calculation based on common keys and values
    $commonKeys = 0
    $totalKeys = ($Pattern1.Keys + $Pattern2.Keys | Sort-Object -Unique).Count
    
    foreach ($key in $Pattern1.Keys) {
        if ($Pattern2.ContainsKey($key) -and $Pattern1[$key] -eq $Pattern2[$key]) {
            $commonKeys++
        }
    }
    
    return if ($totalKeys -gt 0) { $commonKeys / $totalKeys } else { 0 }
}

function Calculate-MemoryRelevance {
    param(
        [string]$Query,
        [hashtable]$Memory
    )
    
    $relevance = 0.0
    $queryWords = $Query.Split(" ", [StringSplitOptions]::RemoveEmptyEntries)
    
    # Check content relevance
    foreach ($word in $queryWords) {
        if ($Memory.Content -match $word) {
            $relevance += 0.3
        }
    }
    
    # Check keyword relevance
    foreach ($word in $queryWords) {
        if ($Memory.Keywords -contains $word) {
            $relevance += 0.5
        }
    }
    
    # Importance boost
    switch ($Memory.Importance) {
        "High" { $relevance *= 1.5 }
        "Medium" { $relevance *= 1.0 }
        "Low" { $relevance *= 0.7 }
    }
    
    return [Math]::Min($relevance, 1.0)
}

function Save-UserProfile {
    param([string]$UserId)
    
    try {
        if ($script:UserProfiles.ContainsKey($UserId)) {
            $userProfilePath = Join-Path $script:UserProfilesPath "$UserId.json"
            $script:UserProfiles[$UserId] | ConvertTo-Json -Depth 10 | Set-Content -Path $userProfilePath -Encoding UTF8
            Write-ContextLog "User profile saved: $UserId" -Level "DEBUG"
        }
    }
    catch {
        Write-ContextLog "Failed to save user profile: $_" -Level "ERROR"
    }
}

function Save-ConversationPatterns {
    try {
        $script:ConversationPatterns | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConversationPatternsPath -Encoding UTF8
        Write-ContextLog "Conversation patterns saved successfully" -Level "DEBUG"
    }
    catch {
        Write-ContextLog "Failed to save conversation patterns: $_" -Level "ERROR"
    }
}

function Save-CrossConversationMemory {
    try {
        $script:CrossConversationMemory | ConvertTo-Json -Depth 10 | Set-Content -Path $script:CrossConversationMemoryPath -Encoding UTF8
        Write-ContextLog "Cross-conversation memory saved successfully" -Level "DEBUG"
    }
    catch {
        Write-ContextLog "Failed to save cross-conversation memory: $_" -Level "ERROR"
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-WorkingMemory',
    'Add-ContextItem',
    'Compress-Context',
    'Get-OptimizedContext',
    'Calculate-ContextRelevance',
    'New-SessionIdentifier',
    'Save-SessionState',
    'Restore-SessionState',
    'Get-SessionList',
    'Clear-ExpiredSessions',
    'Get-ContextSummary',
    # Day 16 Enhancement: Advanced Memory Systems Functions
    'Initialize-UserProfile',
    'Update-UserProfile',
    'Add-ConversationPattern',
    'Get-CrossConversationMemory',
    'Add-CrossConversationMemory'
)

Write-ContextLog "ContextOptimization module loaded successfully" -Level "INFO"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUy3Mj/dnLPeRBBwHJNezMvMk7
# eS2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUIDBOnHUQ0H1f2s/JHbxriPot58gwDQYJKoZIhvcNAQEBBQAEggEAYXct
# wCWtT7Dm9bn7uBxxAx5pmFdPMv3QnHU2thRs1/308kzQwcsAHP0W7pDzNCYhFInj
# O1XYzivQ91Ex2lij88Z2o6UcrsYoV3ZJTlIeIQihnrrif9IvHR6Y8JN5WlFaHB8c
# 1gGlnJhwqHlXNUp5mxzxkTqQrix26DtUgOWP1WWYTHj4ccrXUgJfGq5xag8fE6XF
# ixiqsSNkkNf5EVuFaq1YWtWNJOxHjDu9CymhQfcnCy++0osAXzAquPy+8uxKivtk
# T3puC2DSa7O0r0eaPnxmvkGObnIOWcoMcJXrJ9/C2o31OjajiSgpyYI/6H3HH8ff
# OZ2pJUR7RBLhFT5qbw==
# SIG # End signature block
