using Microsoft.AspNetCore.Mvc;
using PowerShellAPI.Services;

namespace PowerShellAPI.Controllers;

/// <summary>
/// Agent management and control controller
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AgentsController : ControllerBase
{
    private readonly IPowerShellService _powerShellService;
    private readonly ILogger<AgentsController> _logger;

    public AgentsController(IPowerShellService powerShellService, ILogger<AgentsController> logger)
    {
        _powerShellService = powerShellService;
        _logger = logger;
    }

    /// <summary>
    /// Get all agents
    /// </summary>
    /// <returns>List of agents</returns>
    [HttpGet]
    public async Task<ActionResult<AgentResult[]>> GetAgents()
    {
        _logger.LogDebug("GET /api/agents called");
        
        try
        {
            var agents = await _powerShellService.GetAgentsAsync(HttpContext.RequestAborted);
            
            _logger.LogDebug("Retrieved {AgentCount} agents", agents.Length);
            
            return Ok(agents);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Get agents request was cancelled");
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving agents");
            return StatusCode(500, "Failed to retrieve agents");
        }
    }

    /// <summary>
    /// Start an agent
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <returns>Operation result</returns>
    [HttpPost("{id}/start")]
    public async Task<ActionResult<AgentOperationResult>> StartAgent(string id)
    {
        _logger.LogInformation("POST /api/agents/{AgentId}/start called", id);
        
        if (string.IsNullOrWhiteSpace(id))
        {
            return BadRequest("Agent ID cannot be empty");
        }

        try
        {
            var result = await _powerShellService.ControlAgentAsync(id, AgentOperation.Start, HttpContext.RequestAborted);
            
            _logger.LogInformation("Agent start operation completed - Success: {Success}, Message: {Message}", 
                result.Success, result.Message);
            
            return result.Success ? Ok(result) : BadRequest(result);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Start agent request was cancelled for agent {AgentId}", id);
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error starting agent {AgentId}", id);
            return StatusCode(500, $"Failed to start agent: {ex.Message}");
        }
    }

    /// <summary>
    /// Stop an agent
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <returns>Operation result</returns>
    [HttpPost("{id}/stop")]
    public async Task<ActionResult<AgentOperationResult>> StopAgent(string id)
    {
        _logger.LogInformation("POST /api/agents/{AgentId}/stop called", id);
        
        if (string.IsNullOrWhiteSpace(id))
        {
            return BadRequest("Agent ID cannot be empty");
        }

        try
        {
            var result = await _powerShellService.ControlAgentAsync(id, AgentOperation.Stop, HttpContext.RequestAborted);
            
            _logger.LogInformation("Agent stop operation completed - Success: {Success}, Message: {Message}", 
                result.Success, result.Message);
            
            return result.Success ? Ok(result) : BadRequest(result);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Stop agent request was cancelled for agent {AgentId}", id);
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error stopping agent {AgentId}", id);
            return StatusCode(500, $"Failed to stop agent: {ex.Message}");
        }
    }

    /// <summary>
    /// Restart an agent
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <returns>Operation result</returns>
    [HttpPost("{id}/restart")]
    public async Task<ActionResult<AgentOperationResult>> RestartAgent(string id)
    {
        _logger.LogInformation("POST /api/agents/{AgentId}/restart called", id);
        
        if (string.IsNullOrWhiteSpace(id))
        {
            return BadRequest("Agent ID cannot be empty");
        }

        try
        {
            var result = await _powerShellService.ControlAgentAsync(id, AgentOperation.Restart, HttpContext.RequestAborted);
            
            _logger.LogInformation("Agent restart operation completed - Success: {Success}, Message: {Message}", 
                result.Success, result.Message);
            
            return result.Success ? Ok(result) : BadRequest(result);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Restart agent request was cancelled for agent {AgentId}", id);
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error restarting agent {AgentId}", id);
            return StatusCode(500, $"Failed to restart agent: {ex.Message}");
        }
    }

    /// <summary>
    /// Pause an agent
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <returns>Operation result</returns>
    [HttpPost("{id}/pause")]
    public async Task<ActionResult<AgentOperationResult>> PauseAgent(string id)
    {
        _logger.LogInformation("POST /api/agents/{AgentId}/pause called", id);
        
        if (string.IsNullOrWhiteSpace(id))
        {
            return BadRequest("Agent ID cannot be empty");
        }

        try
        {
            var result = await _powerShellService.ControlAgentAsync(id, AgentOperation.Pause, HttpContext.RequestAborted);
            
            _logger.LogInformation("Agent pause operation completed - Success: {Success}, Message: {Message}", 
                result.Success, result.Message);
            
            return result.Success ? Ok(result) : BadRequest(result);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Pause agent request was cancelled for agent {AgentId}", id);
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error pausing agent {AgentId}", id);
            return StatusCode(500, $"Failed to pause agent: {ex.Message}");
        }
    }

    /// <summary>
    /// Resume an agent
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <returns>Operation result</returns>
    [HttpPost("{id}/resume")]
    public async Task<ActionResult<AgentOperationResult>> ResumeAgent(string id)
    {
        _logger.LogInformation("POST /api/agents/{AgentId}/resume called", id);
        
        if (string.IsNullOrWhiteSpace(id))
        {
            return BadRequest("Agent ID cannot be empty");
        }

        try
        {
            var result = await _powerShellService.ControlAgentAsync(id, AgentOperation.Resume, HttpContext.RequestAborted);
            
            _logger.LogInformation("Agent resume operation completed - Success: {Success}, Message: {Message}", 
                result.Success, result.Message);
            
            return result.Success ? Ok(result) : BadRequest(result);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Resume agent request was cancelled for agent {AgentId}", id);
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error resuming agent {AgentId}", id);
            return StatusCode(500, $"Failed to resume agent: {ex.Message}");
        }
    }

    /// <summary>
    /// Get agent configuration
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <returns>Agent configuration</returns>
    [HttpGet("{id}/config")]
    public async Task<ActionResult<Dictionary<string, object>>> GetAgentConfiguration(string id)
    {
        _logger.LogDebug("GET /api/agents/{AgentId}/config called", id);
        
        try
        {
            // Mock configuration for now - would be replaced with actual PowerShell logic
            var config = new Dictionary<string, object>
            {
                ["mode"] = "auto",
                ["priority"] = "high", 
                ["logLevel"] = "info",
                ["maxRetries"] = 3,
                ["timeout"] = 30,
                ["enabled"] = true,
                ["tags"] = new[] { "production", "critical" },
                ["lastConfigUpdate"] = DateTime.UtcNow.AddHours(-1)
            };
            
            _logger.LogDebug("Retrieved configuration for agent {AgentId} with {ConfigCount} keys", id, config.Count);
            
            return Ok(config);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving configuration for agent {AgentId}", id);
            return StatusCode(500, "Failed to retrieve agent configuration");
        }
    }

    /// <summary>
    /// Update agent configuration
    /// </summary>
    /// <param name="id">Agent ID</param>
    /// <param name="configuration">New configuration</param>
    /// <returns>Update result</returns>
    [HttpPut("{id}/config")]
    public async Task<ActionResult<AgentOperationResult>> UpdateAgentConfiguration(string id, [FromBody] Dictionary<string, object> configuration)
    {
        _logger.LogInformation("PUT /api/agents/{AgentId}/config called with {ConfigCount} keys", id, configuration.Count);
        
        if (string.IsNullOrWhiteSpace(id))
        {
            return BadRequest("Agent ID cannot be empty");
        }

        if (configuration == null || configuration.Count == 0)
        {
            return BadRequest("Configuration cannot be empty");
        }

        try
        {
            // Mock configuration update - would be replaced with actual PowerShell logic
            var updateScript = $@"
                # Agent configuration update logic would go here
                $agentId = ""{id}""
                $configKeys = @({string.Join(", ", configuration.Keys.Select(k => $"'{k}'"))})
                
                Start-Sleep -Milliseconds 300
                
                $result = @{{
                    Success = $true
                    Message = ""Agent $agentId configuration updated with $($configKeys.Count) keys""
                    AgentId = $agentId
                    Action = ""configure""
                    Timestamp = Get-Date
                }}
                
                $result | ConvertTo-Json
            ";

            var executionResult = await _powerShellService.ExecuteScriptAsync(updateScript, HttpContext.RequestAborted);
            
            if (executionResult.Success && executionResult.Output.Length > 0)
            {
                var json = string.Join("", executionResult.Output);
                var operationResult = System.Text.Json.JsonSerializer.Deserialize<AgentOperationResult>(json);
                
                _logger.LogInformation("Agent configuration update completed - Success: {Success}", operationResult!.Success);
                
                return Ok(operationResult);
            }
            else
            {
                var failureResult = new AgentOperationResult
                {
                    Success = false,
                    Message = $"Configuration update failed: {string.Join(", ", executionResult.Errors)}",
                    AgentId = id,
                    Action = "configure",
                    Timestamp = DateTime.UtcNow
                };
                
                return BadRequest(failureResult);
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Update agent configuration request was cancelled for agent {AgentId}", id);
            return StatusCode(408, "Request timeout");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating configuration for agent {AgentId}", id);
            return StatusCode(500, $"Failed to update agent configuration: {ex.Message}");
        }
    }
}