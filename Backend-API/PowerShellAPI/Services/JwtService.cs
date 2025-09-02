using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace PowerShellAPI.Services;

/// <summary>
/// JWT token service implementation
/// </summary>
public class JwtService : IJwtService
{
    private readonly JwtOptions _options;
    private readonly ILogger<JwtService> _logger;
    private readonly SymmetricSecurityKey _signingKey;

    public JwtService(IConfiguration configuration, ILogger<JwtService> logger)
    {
        _logger = logger;
        _options = new JwtOptions();
        configuration.GetSection("Jwt").Bind(_options);
        
        // Generate secure key if not configured
        if (string.IsNullOrEmpty(_options.SecretKey))
        {
            _options.SecretKey = GenerateSecureKey();
            _logger.LogInformation("Generated new JWT secret key");
        }
        
        _signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SecretKey));
        
        _logger.LogInformation("JWT service initialized - Issuer: {Issuer}, Audience: {Audience}, Expiration: {ExpirationMinutes} minutes", 
            _options.Issuer, _options.Audience, _options.ExpirationMinutes);
    }

    public string GenerateToken(string username, string role, string userId)
    {
        _logger.LogDebug("Generating JWT token for user: {Username} with role: {Role}", username, role);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Role, role),
            new Claim("username", username),
            new Claim("user_id", userId),
            new Claim("iat", DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(_options.ExpirationMinutes),
            Issuer = _options.Issuer,
            Audience = _options.Audience,
            SigningCredentials = new SigningCredentials(_signingKey, SecurityAlgorithms.HmacSha256Signature)
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);
        var tokenString = tokenHandler.WriteToken(token);

        _logger.LogDebug("JWT token generated successfully for user {Username}, expires: {Expiration}", 
            username, tokenDescriptor.Expires);

        return tokenString;
    }

    public string GenerateRefreshToken()
    {
        var randomBytes = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        
        var refreshToken = Convert.ToBase64String(randomBytes);
        _logger.LogDebug("Refresh token generated");
        
        return refreshToken;
    }

    public ClaimsPrincipal? ValidateToken(string token)
    {
        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = _signingKey,
                ValidateIssuer = true,
                ValidIssuer = _options.Issuer,
                ValidateAudience = true,
                ValidAudience = _options.Audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.FromMinutes(5), // Allow 5 minutes clock skew
                RequireExpirationTime = true
            };

            var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
            
            _logger.LogDebug("JWT token validated successfully for user: {Username}", 
                principal.FindFirst(ClaimTypes.Name)?.Value ?? "Unknown");
            
            return principal;
        }
        catch (SecurityTokenExpiredException)
        {
            _logger.LogDebug("JWT token expired");
            return null;
        }
        catch (SecurityTokenException ex)
        {
            _logger.LogDebug(ex, "JWT token validation failed");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error validating JWT token");
            return null;
        }
    }

    public DateTime? GetTokenExpiration(string token)
    {
        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtToken = tokenHandler.ReadJwtToken(token);
            
            return jwtToken.ValidTo;
        }
        catch (Exception ex)
        {
            _logger.LogDebug(ex, "Error reading JWT token expiration");
            return null;
        }
    }

    private string GenerateSecureKey()
    {
        // Generate 256-bit key for HMAC-SHA256
        var keyBytes = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(keyBytes);
        return Convert.ToBase64String(keyBytes);
    }
}