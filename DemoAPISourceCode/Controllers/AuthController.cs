using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace ErrorhandlingDemoAPI.Controllers
{
    [ApiController]
    [Route("api/auth")]
    [Consumes("application/json")]
    [Produces("application/json")]
    public class AuthController : ControllerBase
    {
        private const string ClientId = "demo";
        private const string ClientSecret = "demo";
        private readonly SymmetricSecurityKey _key = new(Encoding.ASCII.GetBytes("i8Z5SkolOrUOyh69p04kxNkTnovE1Ye6"));

        // POST: auth/token
        /// <summary>
        /// Retrieve an access token using a ClientID and ClientSecret
        /// </summary>
        /// <remarks>
        /// Example:
        ///   
        ///     POST /auth/token
        ///     {
        ///         "ClientId": "demo",
        ///         "ClientSecret": "demo"
        ///     }
        ///   
        /// </remarks>
        /// <response code="200"></response>
        [HttpPost("token")]
        [ProducesResponseType(typeof(TokenResponse), 200)]
        [ProducesResponseType(401)]
        public IActionResult GenerateToken([FromBody] TokenRequest request)
        {
            if (request.ClientId != ClientId || request.ClientSecret != ClientSecret)
                return Unauthorized(new { message = "Invalid client credentials" });

            var creds = new SigningCredentials(_key, SecurityAlgorithms.HmacSha256);


            var claims = new[]
            {
                new Claim(ClaimTypes.Name, "ErrorhandlingDemoAPI"),
                new Claim(ClaimTypes.Role, "Admin")
            };

            var token = new JwtSecurityToken(
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(30),
                signingCredentials: creds
            );
            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            var expiresAt = DateTime.UtcNow.AddMinutes(30);

            return Ok(new TokenResponse { Token = tokenString, ExpiresAt = expiresAt });
        }

    }

    public record TokenRequest
    {
        /// <summary>
        /// The ClientId to authenticate to the example API.
        /// </summary>
        /// <example>demo</example>
        public string ClientId { get; init; }

        /// <summary>
        /// The ClientSecret to authenticate to the example API.
        /// </summary>
        /// <example>demo</example>
        public string ClientSecret { get; init; }
    }

    public record TokenResponse
    {
        public string Token { get; set; }
        public DateTime ExpiresAt { get; set; }
    }
}
