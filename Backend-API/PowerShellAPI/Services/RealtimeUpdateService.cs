using Microsoft.AspNetCore.SignalR;
using PowerShellAPI.Hubs;

namespace PowerShellAPI.Services;

/// <summary>
/// Background service for broadcasting real-time updates to connected clients
/// </summary>
public class RealtimeUpdateService : BackgroundService, IRealtimeUpdateService
{
    private readonly IHubContext<SystemHub> _hubContext;
    private readonly IPowerShellService _powerShellService;
    private readonly ILogger<RealtimeUpdateService> _logger;
    private readonly Timer _updateTimer;
    private bool _isBroadcasting = false;

    public RealtimeUpdateService(
        IHubContext<SystemHub> hubContext, 
        IPowerShellService powerShellService, 
        ILogger<RealtimeUpdateService> logger)
    {
        _hubContext = hubContext;
        _powerShellService = powerShellService;
        _logger = logger;
        
        // Create timer for periodic updates (every 30 seconds)
        _updateTimer = new Timer(UpdateCallback, null, TimeSpan.Zero, TimeSpan.FromSeconds(30));
        
        _logger.LogInformation("Real-time update service initialized with 30-second intervals");
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Real-time update service starting...");
        
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (_isBroadcasting)
                {
                    await PerformPeriodicUpdates(stoppingToken);
                }
                
                // Wait before next update cycle
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("Real-time update service stopping...");
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in real-time update service");
                await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken); // Back off on error
            }
        }
        
        _logger.LogInformation("Real-time update service stopped");
    }

    public async Task StartBroadcastingAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Starting real-time broadcasts");
        _isBroadcasting = true;
        
        // Send immediate update to all clients
        await PerformPeriodicUpdates(cancellationToken);
    }

    public async Task StopBroadcastingAsync()
    {
        _logger.LogInformation("Stopping real-time broadcasts");
        _isBroadcasting = false;
        
        // Notify clients that updates are stopping
        await _hubContext.Clients.All.SendAsync("BroadcastingStopped", DateTime.UtcNow);
    }

    public async Task BroadcastSystemStatusAsync(SystemStatusResult systemStatus)
    {
        try
        {
            _logger.LogDebug("Broadcasting system status update - CPU: {CpuUsage}%, Memory: {MemoryUsage}%", 
                systemStatus.CpuUsage, systemStatus.MemoryUsage);
            
            await _hubContext.Clients.All.SendAsync("SystemStatusUpdate", systemStatus);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error broadcasting system status");
        }
    }

    public async Task BroadcastAgentUpdatesAsync(AgentResult[] agents)
    {
        try
        {
            _logger.LogDebug("Broadcasting agent updates - {AgentCount} agents", agents.Length);
            
            await _hubContext.Clients.All.SendAsync("AgentsUpdate", agents);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error broadcasting agent updates");
        }
    }

    public async Task BroadcastAgentSpecificUpdateAsync(string agentId, AgentResult agentData)
    {
        try
        {
            _logger.LogDebug("Broadcasting specific update for agent: {AgentId}", agentId);
            
            // Send to clients monitoring this specific agent
            await _hubContext.Clients.Group($"agent_{agentId}").SendAsync("AgentSpecificUpdate", agentData);
            
            // Also send to all clients for general agent list updates
            await _hubContext.Clients.All.SendAsync("AgentStatusChanged", agentData);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error broadcasting agent-specific update for {AgentId}", agentId);
        }
    }

    public async Task BroadcastAlertAsync(AlertMessage alert)
    {
        try
        {
            _logger.LogInformation("Broadcasting alert: {Title} [{Severity}]", alert.Title, alert.Severity);
            
            await _hubContext.Clients.All.SendAsync("AlertBroadcast", alert);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error broadcasting alert: {AlertTitle}", alert.Title);
        }
    }

    private async void UpdateCallback(object? state)
    {
        if (_isBroadcasting)
        {
            try
            {
                await PerformPeriodicUpdates(CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in timer-based update callback");
            }
        }
    }

    private async Task PerformPeriodicUpdates(CancellationToken cancellationToken)
    {
        try
        {
            // Get current system status
            var systemStatus = await _powerShellService.GetSystemStatusAsync(cancellationToken);
            await BroadcastSystemStatusAsync(systemStatus);

            // Get current agent status
            var agents = await _powerShellService.GetAgentsAsync(cancellationToken);
            await BroadcastAgentUpdatesAsync(agents);

            // Send heartbeat to maintain connections
            await _hubContext.Clients.All.SendAsync("Heartbeat", DateTime.UtcNow, cancellationToken);

            _logger.LogDebug("Periodic updates completed successfully");
        }
        catch (OperationCanceledException)
        {
            _logger.LogDebug("Periodic updates cancelled");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error performing periodic updates");
            
            // Send error notification to clients
            var errorAlert = new AlertMessage
            {
                Title = "Update Service Error",
                Message = "Failed to retrieve system updates",
                Severity = "warning",
                Source = "RealtimeUpdateService"
            };
            
            await BroadcastAlertAsync(errorAlert);
        }
    }

    public override void Dispose()
    {
        _updateTimer?.Dispose();
        base.Dispose();
    }
}