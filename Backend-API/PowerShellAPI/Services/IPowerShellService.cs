using System.Management.Automation;

namespace PowerShellAPI.Services;

/// <summary>
/// Interface for PowerShell script execution service
/// </summary>
public interface IPowerShellService
{
    /// <summary>
    /// Execute a PowerShell script and return the results
    /// </summary>
    /// <param name="script">PowerShell script to execute</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Execution results</returns>
    Task<PowerShellExecutionResult> ExecuteScriptAsync(string script, CancellationToken cancellationToken = default);

    /// <summary>
    /// Execute a PowerShell command with parameters
    /// </summary>
    /// <param name="command">Command to execute</param>
    /// <param name="parameters">Command parameters</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Execution results</returns>
    Task<PowerShellExecutionResult> ExecuteCommandAsync(string command, Dictionary<string, object>? parameters = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Get system status using PowerShell commands
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>System status information</returns>
    Task<SystemStatusResult> GetSystemStatusAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Get agent information using PowerShell modules
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Agent information</returns>
    Task<AgentResult[]> GetAgentsAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Control agent operations (start/stop/restart/pause/resume)
    /// </summary>
    /// <param name="agentId">Agent identifier</param>
    /// <param name="operation">Operation to perform</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Operation result</returns>
    Task<AgentOperationResult> ControlAgentAsync(string agentId, AgentOperation operation, CancellationToken cancellationToken = default);
}

/// <summary>
/// Result of PowerShell script execution
/// </summary>
public class PowerShellExecutionResult
{
    public bool Success { get; set; }
    public string[] Output { get; set; } = Array.Empty<string>();
    public string[] Errors { get; set; } = Array.Empty<string>();
    public TimeSpan ExecutionTime { get; set; }
    public Dictionary<string, object> Variables { get; set; } = new();
    
    public static PowerShellExecutionResult FromException(Exception exception, TimeSpan executionTime)
    {
        return new PowerShellExecutionResult
        {
            Success = false,
            Errors = new[] { exception.Message },
            ExecutionTime = executionTime
        };
    }
}

/// <summary>
/// System status result from PowerShell execution
/// </summary>
public class SystemStatusResult
{
    public DateTime Timestamp { get; set; }
    public bool IsHealthy { get; set; }
    public double CpuUsage { get; set; }
    public double MemoryUsage { get; set; }
    public double DiskUsage { get; set; }
    public int ActiveAgents { get; set; }
    public int TotalModules { get; set; }
    public TimeSpan Uptime { get; set; }
}

/// <summary>
/// Agent information result from PowerShell
/// </summary>
public class AgentResult
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime? StartTime { get; set; }
    public DateTime? LastActivity { get; set; }
    public ResourceUsageResult? ResourceUsage { get; set; }
    public Dictionary<string, string> Configuration { get; set; } = new();
}

/// <summary>
/// Resource usage information
/// </summary>
public class ResourceUsageResult
{
    public double Cpu { get; set; }
    public double Memory { get; set; }
    public int Threads { get; set; }
    public int Handles { get; set; }
}

/// <summary>
/// Agent operation result
/// </summary>
public class AgentOperationResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public string AgentId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public TimeSpan? ExecutionTime { get; set; }
}

/// <summary>
/// Available agent operations
/// </summary>
public enum AgentOperation
{
    Start,
    Stop,
    Restart,
    Pause,
    Resume
}