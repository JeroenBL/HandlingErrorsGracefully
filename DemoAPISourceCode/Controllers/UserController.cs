using ErrorhandlingDemoAPI.Localization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ErrorhandlingDemoAPI.Controllers
{
    [Authorize]
    [Route("api/user")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private static List<User> _users = new List<User>();
        private readonly ICustomLocalizer _localizer;
        private static int _attemptCount = 0;

        public UserController(ICustomLocalizer localizer)
        {
            _localizer = localizer;
            if (_users.Count == 0)
            {
                _users.Add(new User { Id = 1, FirstName = "Alicia", LastName = "Doe", Email = "a.doe@example", Description = "Facilitator", Active = false });
                _users.Add(new User { Id = 2, FirstName = "Bram", LastName = "Doe", Email = " b.doe@example", Description = "EngineerSenior", Active = true });
            }
        }

        [HttpGet()]
        public IActionResult GetUsers()
        {
            var users = _users.ToList();
            return Ok(users);
        }

        [HttpGet("{id}")]
        public IActionResult GetUser(int id)
        {
            var user = _users.FirstOrDefault(u => u.Id == id);
            if (user == null)
            {
                var culture = Request.Headers["Accept-Language"].ToString().Split(',').FirstOrDefault() ?? "en";

                var detailMessage = string.Format(_localizer.GetString("UserNotFoundDetail", culture), id);
                var title = _localizer.GetString("NotFound", culture);

                return Problem(
                    type: "https://tools.ietf.org/html/rfc9110#section-15.5.5",
                    title: title,
                    statusCode: StatusCodes.Status404NotFound,
                    detail: detailMessage
                );
            }
            return Ok(user);
        }

        [HttpPost()]
        public IActionResult CreateUser([FromBody] User user, [FromHeader(Name = "simulateFailure")] bool simulateFailure, [FromHeader(Name = "retryCount")] int retryCount)
        {
            if (retryCount <= 0) retryCount = 4;

            if (simulateFailure && _attemptCount < retryCount)
            {
                _attemptCount++;
                return StatusCode(408, "Request Timeout");
            }

            if (user.Active == true)
            {
                return UnprocessableEntity("Not allowed to set property [active] during creation");
            }

            user.Id = _users.Count + 1;
            user.Active = false;
            _users.Add(user);

            _attemptCount = 0;

            return Ok(user);
        }

        [HttpGet("search")]
        public IActionResult SearchUsers([FromQuery] string email)
        {
            var filteredUsers = _users.AsQueryable();

            if (!string.IsNullOrEmpty(email))
            {
                filteredUsers = filteredUsers.Where(u => u.Email.Contains(email));
            }

            var result = filteredUsers.ToList();
            if (result.Count == 0)
            {
                return NotFound($"User with email {email} not found");
            }

            return Ok(result);
        }
    }

    public class User
    {
        public int Id { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Description { get; set; }
        public bool? Active { get; set; }
    }
}