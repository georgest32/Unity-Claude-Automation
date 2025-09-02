using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using PowerShellAPI.Services;

namespace PowerShellAPI.Hubs;

/// <summary>
/// SignalR hub for real-time system updates
/// </summary>
[Authorize]
public class SystemHub : Hub
{
    private readonly IPowerShellService _powerShellService;
    private readonly ILogger<SystemHub> _logger;

    public SystemHub(IPowerShellService powerShellService, ILogger<SystemHub> logger)
    {
        _powerShellService = powerShellService;
        _logger = logger;
    }

    /// <summary>
    /// Client connects to the hub
    /// </summary>
    public override async Task OnConnectedAsync()
    {
        var username = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogInformation("Client connected to SystemHub: {Username} (ConnectionId: {ConnectionId})", 
            username, Context.ConnectionId);

        // Join user-specific group for targeted updates
        await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{username}");
        
        // Send initial system status
        try
        {
            var systemStatus = await _powerShellService.GetSystemStatusAsync();
            await Clients.Caller.SendAsync("SystemStatusUpdate", systemStatus);
            
            var agents = await _powerShellService.GetAgentsAsync();
            await Clients.Caller.SendAsync("AgentsUpdate", agents);
            
            _logger.LogDebug("Sent initial data to connected client: {Username}", username);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending initial data to client: {Username}", username);
        }

        await base.OnConnectedAsync();
    }

    /// <summary>
    /// Client disconnects from the hub
    /// </summary>
    /// <param name="exception">Disconnect exception if any</param>
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var username = Context.User?.Identity?.Name ?? "Anonymous";
        
        if (exception != null)
        {
            _logger.LogWarning(exception, "Client disconnected with error: {Username} (ConnectionId: {ConnectionId})", 
                username, Context.ConnectionId);
        }
        else
        {
            _logger.LogInformation("Client disconnected normally: {Username} (ConnectionId: {ConnectionId})", 
                username, Context.ConnectionId);
        }

        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Client requests to join agent monitoring group
    /// </summary>
    /// <param name="agentId">Agent ID to monitor</param>
    public async Task JoinAgentGroup(string agentId)
    {
        var username = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogDebug("Client {Username} joining agent group: {AgentId}", username, agentId);
        
        await Groups.AddToGroupAsync(Context.ConnectionId, $"agent_{agentId}");
        await Clients.Caller.SendAsync("JoinedAgentGroup", agentId);
    }

    /// <summary>
    /// Client requests to leave agent monitoring group
    /// </summary>
    /// <param name="agentId">Agent ID to stop monitoring</param>
    public async Task LeaveAgentGroup(string agentId)
    {
        var username = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogDebug("Client {Username} leaving agent group: {AgentId}", username, agentId);
        
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"agent_{agentId}");
        await Clients.Caller.SendAsync("LeftAgentGroup", agentId);
    }

    /// <summary>
    /// Client requests system metrics update
    /// </summary>
    public async Task RequestSystemMetrics()
    {
        var username = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogDebug("Client {Username} requested system metrics", username);
        
        try
        {
            var systemStatus = await _powerShellService.GetSystemStatusAsync();
            await Clients.Caller.SendAsync("SystemStatusUpdate", systemStatus);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending system metrics to client: {Username}", username);
            await Clients.Caller.SendAsync("Error", "Failed to retrieve system metrics");
        }
    }

    /// <summary>
    /// Client requests agent list update
    /// </summary>
    public async Task RequestAgentUpdates()
    {
        var username = Context.User?.Identity?.Name ?? "Anonymous";
        _logger.LogDebug("Client {Username} requested agent updates", username);
        
        try
        {
            var agents = await _powerShellService.GetAgentsAsync();
            await Clients.Caller.SendAsync("AgentsUpdate", agents);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending agent updates to client: {Username}", username);
            await Clients.Caller.SendAsync("Error", "Failed to retrieve agent updates");
        }
    }

    /// <summary>
    /// Send heartbeat to maintain connection
    /// </summary>
    public async Task Heartbeat()
    {
        await Clients.Caller.SendAsync("HeartbeatResponse", DateTime.UtcNow);
    }
}