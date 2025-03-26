using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;

namespace ErrorhandlingDemoAPI.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class RolesController : ControllerBase
    {
        private static readonly List<string> FakeRoles = new() { "Admin", "User", "Guest", "SuperUser", "Test" };

        /// <summary>
        /// Retrieves the list of available roles.
        /// </summary>
        /// <param name="forceForbidden">If true, the request will return a 403 Forbidden response</param>
        /// <returns>A list of roles or a 403 Forbidden response.</returns>
        [HttpGet()]
        [Authorize(Roles = "Admin")]
        [SwaggerResponse(200, "Returns the list of roles", typeof(List<string>))]
        [SwaggerResponse(403, "Access denied if the 'ForceForbidden' header is set to true")]
        public IActionResult GetRoles([FromHeader(Name = "ForceForbidden")] bool forceForbidden)
        {
            if (forceForbidden)
            {
                return Forbid();
            }

            return Ok(FakeRoles);
        }
    }
}
