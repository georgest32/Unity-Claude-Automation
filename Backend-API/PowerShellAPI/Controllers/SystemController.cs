using Microsoft.AspNetCore.Mvc;
using PowerShellAPI.Services;

namespace PowerShellAPI.Controllers;

/// <summary>
/// System status and health monitoring controller
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class SystemController : ControllerBase
{
    private readonly IPowerShellService _powerShellService;
    private readonly ILogger<SystemController> _logger;

    public SystemController(IPowerShellService powerShellService, ILogger<SystemController> logger)
    {
        _powerShellService = powerShellService;
        _logger = logger;
    }

    /// <summary>
    /// Get current system status and health metrics
    /// </summary>
    /// <returns>System status information</returns>
    [HttpGet("status")]
    public async Task<ActionResult<SystemStatusResult>> GetSystemStatus()
    {
        _logger.LogDebug("GET /api/system/status called");
        
        try
        {
            var systemStatus = await _powerShellService.GetSystemStatusAsync(HttpContext.RequestAborted);
            
            _logger.LogDebug("System status retrieved successfully - Healthy: {IsHealthy}, CPU: {CpuUsage}%, Memory: {MemoryUsage}%", 
                systemStatus.IsHealthy, systemStatus.CpuUsage, systemStatus.MemoryUsage);
            
            return Ok(systemStatus);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("System status request was cancelled");
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving system status");
            return StatusCode(500, "Internal server error");
        }
    }

    /// <summary>
    /// Get system health check (lightweight endpoint)
    /// </summary>
    /// <returns>Basic health status</returns>
    [HttpGet("health")]
    public ActionResult<object> GetHealth()
    {
        _logger.LogDebug("GET /api/system/health called");
        
        try
        {
            var healthStatus = new
            {
                Status = "Healthy",
                Timestamp = DateTime.UtcNow,
                Version = "1.0.0",
                PowerShellAvailable = true
            };
            
            return Ok(healthStatus);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking system health");
            return StatusCode(500, "System unhealthy");
        }
    }

    /// <summary>
    /// Execute a custom PowerShell command
    /// </summary>
    /// <param name="command">PowerShell command to execute</param>
    /// <returns>Command execution result</returns>
    [HttpPost("execute")]
    public async Task<ActionResult<PowerShellExecutionResult>> ExecuteCommand([FromBody] ExecuteCommandRequest request)
    {
        _logger.LogInformation("POST /api/system/execute called with command: {Command}", request.Command);
        
        if (string.IsNullOrWhiteSpace(request.Command))
        {
            return BadRequest("Command cannot be empty");
        }

        // Security check - only allow safe commands for now
        var allowedCommands = new[]
        {
            "Get-Process",
            "Get-Service", 
            "Get-Module",
            "Get-Date",
            "Get-Location",
            "Get-ChildItem"
        };

        var commandName = request.Command.Split(' ')[0];
        if (!allowedCommands.Contains(commandName, StringComparer.OrdinalIgnoreCase))
        {
            _logger.LogWarning("Blocked unsafe command: {Command}", request.Command);
            return BadRequest($"Command '{commandName}' is not allowed");
        }

        try
        {
            var result = await _powerShellService.ExecuteCommandAsync(request.Command, request.Parameters, HttpContext.RequestAborted);
            
            _logger.LogDebug("Command executed - Success: {Success}, Output lines: {OutputCount}", 
                result.Success, result.Output.Length);
            
            return Ok(result);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Command execution was cancelled");
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error executing command: {Command}", request.Command);
            return StatusCode(500, "Command execution failed");
        }
    }
}

/// <summary>
/// Request model for executing PowerShell commands
/// </summary>
public class ExecuteCommandRequest
{
    public string Command { get; set; } = string.Empty;
    public Dictionary<string, object>? Parameters { get; set; }
}