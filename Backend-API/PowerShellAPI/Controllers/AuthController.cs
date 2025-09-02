using Microsoft.AspNetCore.Mvc;
using PowerShellAPI.Services;
using System.Security.Claims;
using System.Security.Cryptography;

namespace PowerShellAPI.Controllers;

/// <summary>
/// Authentication controller for JWT token management
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IJwtService jwtService, ILogger<AuthController> logger)
    {
        _jwtService = jwtService;
        _logger = logger;
    }

    /// <summary>
    /// Authenticate user and return JWT token
    /// </summary>
    /// <param name="request">Login credentials</param>
    /// <returns>Authentication response with JWT token</returns>
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        _logger.LogInformation("Login attempt for user: {Username}", request.Username);

        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            _logger.LogWarning("Login failed - missing username or password");
            return BadRequest(new { message = "Username and password are required" });
        }

        // Validate credentials (simplified for demo - in production use proper user store)
        if (!await ValidateCredentialsAsync(request.Username, request.Password))
        {
            _logger.LogWarning("Login failed for user: {Username} - invalid credentials", request.Username);
            return Unauthorized(new { message = "Invalid username or password" });
        }

        try
        {
            var userId = Guid.NewGuid().ToString();
            var role = DetermineUserRole(request.Username);
            
            var token = _jwtService.GenerateToken(request.Username, role, userId);
            var refreshToken = _jwtService.GenerateRefreshToken();
            var expiration = _jwtService.GetTokenExpiration(token);

            var response = new AuthResponse
            {
                Token = token,
                RefreshToken = refreshToken,
                ExpiresAt = expiration ?? DateTime.UtcNow.AddHours(1),
                User = new UserInfo
                {
                    Id = userId,
                    Username = request.Username,
                    Email = $"{request.Username}@unity-claude.local",
                    Role = role,
                    CreatedAt = DateTime.UtcNow.AddDays(-Random.Shared.Next(1, 365))
                }
            };

            _logger.LogInformation("Login successful for user: {Username}, role: {Role}, expires: {Expiration}", 
                request.Username, role, expiration);

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating authentication token for user: {Username}", request.Username);
            return StatusCode(500, new { message = "Internal server error during authentication" });
        }
    }

    /// <summary>
    /// Refresh JWT token using refresh token
    /// </summary>
    /// <param name="request">Refresh token request</param>
    /// <returns>New JWT token</returns>
    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh([FromBody] RefreshTokenRequest request)
    {
        _logger.LogDebug("Token refresh request received");

        if (string.IsNullOrWhiteSpace(request.RefreshToken))
        {
            return BadRequest(new { message = "Refresh token is required" });
        }

        // Validate refresh token (simplified - in production store and validate refresh tokens)
        if (!await ValidateRefreshTokenAsync(request.RefreshToken))
        {
            _logger.LogWarning("Invalid refresh token provided");
            return Unauthorized(new { message = "Invalid refresh token" });
        }

        try
        {
            // Extract user info from existing token (simplified)
            var username = "demo_user"; // In production, extract from stored refresh token data
            var role = "admin";
            var userId = Guid.NewGuid().ToString();

            var newToken = _jwtService.GenerateToken(username, role, userId);
            var newRefreshToken = _jwtService.GenerateRefreshToken();
            var expiration = _jwtService.GetTokenExpiration(newToken);

            var response = new AuthResponse
            {
                Token = newToken,
                RefreshToken = newRefreshToken,
                ExpiresAt = expiration ?? DateTime.UtcNow.AddHours(1),
                User = new UserInfo
                {
                    Id = userId,
                    Username = username,
                    Email = $"{username}@unity-claude.local",
                    Role = role,
                    CreatedAt = DateTime.UtcNow.AddDays(-30)
                }
            };

            _logger.LogInformation("Token refreshed successfully for user: {Username}", username);
            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refreshing authentication token");
            return StatusCode(500, new { message = "Internal server error during token refresh" });
        }
    }

    /// <summary>
    /// Logout and invalidate token
    /// </summary>
    /// <returns>Logout confirmation</returns>
    [HttpPost("logout")]
    public ActionResult Logout()
    {
        _logger.LogInformation("User logout request");
        
        // In production, you'd add the token to a blacklist
        // For now, just return success
        
        return Ok(new { message = "Logged out successfully" });
    }

    /// <summary>
    /// Validate current token and return user info
    /// </summary>
    /// <returns>Current user information</returns>
    [HttpGet("me")]
    public ActionResult<UserInfo> GetCurrentUser()
    {
        try
        {
            // Extract user info from JWT token in Authorization header
            var authHeader = Request.Headers.Authorization.FirstOrDefault();
            if (authHeader == null || !authHeader.StartsWith("Bearer "))
            {
                return Unauthorized(new { message = "No valid authorization header found" });
            }

            var token = authHeader.Substring("Bearer ".Length);
            var principal = _jwtService.ValidateToken(token);
            
            if (principal == null)
            {
                return Unauthorized(new { message = "Invalid or expired token" });
            }

            var userInfo = new UserInfo
            {
                Id = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "",
                Username = principal.FindFirst(ClaimTypes.Name)?.Value ?? "",
                Email = $"{principal.FindFirst(ClaimTypes.Name)?.Value}@unity-claude.local",
                Role = principal.FindFirst(ClaimTypes.Role)?.Value ?? "user",
                CreatedAt = DateTime.UtcNow.AddDays(-30)
            };

            return Ok(userInfo);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting current user info");
            return StatusCode(500, new { message = "Error retrieving user information" });
        }
    }

    // MARK: - Private Helper Methods

    private async Task<bool> ValidateCredentialsAsync(string username, string password)
    {
        // Simplified credential validation for demo
        // In production, validate against database, Active Directory, etc.
        
        await Task.Delay(100); // Simulate database lookup
        
        var validCredentials = new Dictionary<string, string>
        {
            {"admin", "admin123"},
            {"user", "user123"},
            {"demo", "demo123"},
            {"test", "test123"}
        };

        return validCredentials.TryGetValue(username.ToLower(), out var validPassword) && 
               validPassword == password;
    }

    private async Task<bool> ValidateRefreshTokenAsync(string refreshToken)
    {
        // Simplified refresh token validation
        // In production, validate against stored refresh tokens in database
        
        await Task.Delay(50); // Simulate database lookup
        
        // For demo, accept any base64-encoded string longer than 20 characters
        try
        {
            var decoded = Convert.FromBase64String(refreshToken);
            return decoded.Length >= 16; // Minimum 16 bytes
        }
        catch
        {
            return false;
        }
    }

    private string DetermineUserRole(string username)
    {
        // Simplified role assignment
        // In production, retrieve from user database
        
        return username.ToLower() switch
        {
            "admin" => "admin",
            "operator" => "operator", 
            "viewer" => "viewer",
            _ => "user"
        };
    }

    private string GenerateSecureKey()
    {
        var keyBytes = new byte[32]; // 256 bits
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(keyBytes);
        return Convert.ToBase64String(keyBytes);
    }
}

// MARK: - Request/Response Models

/// <summary>
/// Login request model
/// </summary>
public class LoginRequest
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>
/// Refresh token request model
/// </summary>
public class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}

/// <summary>
/// Authentication response model
/// </summary>
public class AuthResponse
{
    public string Token { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public UserInfo User { get; set; } = new();
}

/// <summary>
/// User information model
/// </summary>
public class UserInfo
{
    public string Id { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}