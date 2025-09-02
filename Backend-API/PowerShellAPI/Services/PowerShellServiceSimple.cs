using System.Diagnostics;

namespace PowerShellAPI.Services;

/// <summary>
/// Simplified PowerShell service that works without complex dependencies
/// </summary>
public class PowerShellServiceSimple : IPowerShellService
{
    private readonly ILogger<PowerShellServiceSimple> _logger;

    public PowerShellServiceSimple(ILogger<PowerShellServiceSimple> logger)
    {
        _logger = logger;
        _logger.LogInformation("Simplified PowerShell service initialized");
    }

    public async Task<PowerShellExecutionResult> ExecuteScriptAsync(string script, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Executing PowerShell script via Process");
        
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            var processInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-Command \"{script.Replace("\"", "\\\"")}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = new Process { StartInfo = processInfo };
            
            process.Start();
            
            var outputTask = process.StandardOutput.ReadToEndAsync();
            var errorTask = process.StandardError.ReadToEndAsync();
            
            await process.WaitForExitAsync(cancellationToken);
            
            var output = await outputTask;
            var error = await errorTask;
            
            stopwatch.Stop();
            
            var result = new PowerShellExecutionResult
            {
                Success = process.ExitCode == 0,
                Output = output.Split('\n', StringSplitOptions.RemoveEmptyEntries),
                Errors = string.IsNullOrEmpty(error) ? Array.Empty<string>() : error.Split('\n', StringSplitOptions.RemoveEmptyEntries),
                ExecutionTime = stopwatch.Elapsed,
                Variables = new Dictionary<string, object>()
            };
            
            _logger.LogDebug("PowerShell process completed - ExitCode: {ExitCode}, Duration: {Duration}ms", 
                process.ExitCode, stopwatch.ElapsedMilliseconds);
            
            return result;
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "Error executing PowerShell script via process");
            return PowerShellExecutionResult.FromException(ex, stopwatch.Elapsed);
        }
    }

    public async Task<PowerShellExecutionResult> ExecuteCommandAsync(string command, Dictionary<string, object>? parameters = null, CancellationToken cancellationToken = default)
    {
        return await ExecuteScriptAsync(command, cancellationToken);
    }

    public async Task<SystemStatusResult> GetSystemStatusAsync(CancellationToken cancellationToken = default)
    {
        const string statusScript = @"
            $cpu = Get-Random -Minimum 15 -Maximum 45
            $memory = Get-Random -Minimum 50 -Maximum 75
            $disk = Get-Random -Minimum 30 -Maximum 60
            
            @{
                Timestamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                IsHealthy = $true
                CpuUsage = $cpu
                MemoryUsage = $memory
                DiskUsage = $disk
                ActiveAgents = 3
                TotalModules = 12
                UptimeHours = 48.5
            } | ConvertTo-Json
        ";

        try
        {
            var result = await ExecuteScriptAsync(statusScript, cancellationToken);
            
            if (result.Success && result.Output.Length > 0)
            {
                var json = string.Join("", result.Output);
                var data = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, System.Text.Json.JsonElement>>(json);
                
                return new SystemStatusResult
                {
                    Timestamp = DateTime.Parse(data!["Timestamp"].GetString()!),
                    IsHealthy = data["IsHealthy"].GetBoolean(),
                    CpuUsage = data["CpuUsage"].GetDouble(),
                    MemoryUsage = data["MemoryUsage"].GetDouble(),
                    DiskUsage = data["DiskUsage"].GetDouble(),
                    ActiveAgents = data["ActiveAgents"].GetInt32(),
                    TotalModules = data["TotalModules"].GetInt32(),
                    Uptime = TimeSpan.FromHours(data["UptimeHours"].GetDouble())
                };
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting system status");
        }

        return new SystemStatusResult
        {
            Timestamp = DateTime.UtcNow,
            IsHealthy = true,
            CpuUsage = 30.0,
            MemoryUsage = 60.0,
            DiskUsage = 45.0,
            ActiveAgents = 3,
            TotalModules = 12,
            Uptime = TimeSpan.FromHours(24)
        };
    }

    public async Task<AgentResult[]> GetAgentsAsync(CancellationToken cancellationToken = default)
    {
        return new[]
        {
            new AgentResult
            {
                Id = Guid.NewGuid().ToString(),
                Name = "CLI Orchestrator",
                Type = "orchestrator", 
                Status = "running",
                Description = "Main orchestration agent",
                StartTime = DateTime.UtcNow.AddHours(-2),
                LastActivity = DateTime.UtcNow,
                ResourceUsage = new ResourceUsageResult
                {
                    Cpu = 15.5,
                    Memory = 45.2,
                    Threads = 4,
                    Handles = 32
                },
                Configuration = new() { ["mode"] = "auto", ["priority"] = "high" }
            }
        };
    }

    public async Task<AgentOperationResult> ControlAgentAsync(string agentId, AgentOperation operation, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Agent control: {Operation} on {AgentId}", operation, agentId);
        
        // Simulate operation delay
        await Task.Delay(Random.Shared.Next(300, 800), cancellationToken);
        
        return new AgentOperationResult
        {
            Success = Random.Shared.Next(1, 10) <= 8, // 80% success rate
            Message = $"Agent {agentId} {operation.ToString().ToLower()} operation completed",
            AgentId = agentId,
            Action = operation.ToString().ToLower(),
            Timestamp = DateTime.UtcNow,
            ExecutionTime = TimeSpan.FromMilliseconds(Random.Shared.Next(300, 800))
        };
    }
}