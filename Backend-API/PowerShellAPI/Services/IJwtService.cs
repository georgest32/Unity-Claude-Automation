using System.Security.Claims;

namespace PowerShellAPI.Services;

/// <summary>
/// JWT token service interface
/// </summary>
public interface IJwtService
{
    /// <summary>
    /// Generate JWT token for authenticated user
    /// </summary>
    /// <param name="username">Username</param>
    /// <param name="role">User role</param>
    /// <param name="userId">User ID</param>
    /// <returns>JWT token string</returns>
    string GenerateToken(string username, string role, string userId);

    /// <summary>
    /// Generate refresh token
    /// </summary>
    /// <returns>Refresh token string</returns>
    string GenerateRefreshToken();

    /// <summary>
    /// Validate JWT token and extract claims
    /// </summary>
    /// <param name="token">JWT token</param>
    /// <returns>Claims principal if valid, null if invalid</returns>
    ClaimsPrincipal? ValidateToken(string token);

    /// <summary>
    /// Get token expiration time
    /// </summary>
    /// <param name="token">JWT token</param>
    /// <returns>Expiration datetime</returns>
    DateTime? GetTokenExpiration(string token);
}

/// <summary>
/// JWT configuration options
/// </summary>
public class JwtOptions
{
    public string SecretKey { get; set; } = string.Empty;
    public string Issuer { get; set; } = "Unity-Claude-PowerShell-API";
    public string Audience { get; set; } = "Unity-Claude-iOS-App";
    public int ExpirationMinutes { get; set; } = 60;
    public int RefreshTokenExpirationDays { get; set; } = 7;
}