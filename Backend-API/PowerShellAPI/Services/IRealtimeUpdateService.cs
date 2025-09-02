namespace PowerShellAPI.Services;

/// <summary>
/// Interface for real-time update broadcasting service
/// </summary>
public interface IRealtimeUpdateService
{
    /// <summary>
    /// Start broadcasting real-time updates
    /// </summary>
    /// <param name="cancellationToken">Cancellation token</param>
    Task StartBroadcastingAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Stop broadcasting real-time updates
    /// </summary>
    Task StopBroadcastingAsync();

    /// <summary>
    /// Broadcast system status update to all connected clients
    /// </summary>
    /// <param name="systemStatus">System status data</param>
    Task BroadcastSystemStatusAsync(SystemStatusResult systemStatus);

    /// <summary>
    /// Broadcast agent status update to all connected clients
    /// </summary>
    /// <param name="agents">Agent data</param>
    Task BroadcastAgentUpdatesAsync(AgentResult[] agents);

    /// <summary>
    /// Broadcast agent-specific update to clients monitoring that agent
    /// </summary>
    /// <param name="agentId">Agent ID</param>
    /// <param name="agentData">Agent data</param>
    Task BroadcastAgentSpecificUpdateAsync(string agentId, AgentResult agentData);

    /// <summary>
    /// Send alert to all connected clients
    /// </summary>
    /// <param name="alert">Alert information</param>
    Task BroadcastAlertAsync(AlertMessage alert);
}

/// <summary>
/// Alert message for real-time broadcasting
/// </summary>
public class AlertMessage
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Severity { get; set; } = "info";
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string Source { get; set; } = "System";
    public Dictionary<string, object> Data { get; set; } = new();
}