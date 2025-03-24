using Bogus;
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
        private static Dictionary<string, List<DateTime>> requestLog = new Dictionary<string, List<DateTime>>();

        public UserController(ICustomLocalizer localizer)
        {
            _localizer = localizer;
            if (_users.Count == 0)
            {
                _users.Add(new User { Id = 1, FirstName = "Alicia", LastName = "Doe", Email = "a.doe@example", Description = "Facilitator", Active = false });
                _users.Add(new User { Id = 2, FirstName = "Bram", LastName = "Doe", Email = " b.doe@example", Description = "EngineerSenior", Active = true });
            }
        }

        private List<User> GenerateFakeUsers(int count = 100)
        {
            var faker = new Faker<User>()
                .RuleFor(u => u.Id, f => f.Random.Int(1, 1000))
                .RuleFor(u => u.FirstName, f => f.Name.FirstName())
                .RuleFor(u => u.LastName, f => f.Name.LastName())
                .RuleFor(u => u.Email, f => f.Internet.Email())
                .RuleFor(u => u.Description, f => f.Lorem.Sentence()) 
                .RuleFor(u => u.Active, f => f.Random.Bool());

            return faker.Generate(count);
        }

        [HttpGet]
        [Authorize(Roles = "Admin")]
        public IActionResult GetUsers([FromHeader(Name = "simulateRateLimiting")] bool simulateRateLimiting, int pageNumber = 1, int pageSize = 10)
        {
            if (simulateRateLimiting)
            {
                var maxRequestsPer10Seconds = 5;
                var userId = User.Identity.Name;

                if (!requestLog.ContainsKey(userId))
                {
                    requestLog[userId] = new List<DateTime>();
                }

                var recentRequests = requestLog[userId].Where(time => (DateTime.UtcNow - time).TotalSeconds <= 10).ToList();

                if (recentRequests.Count >= maxRequestsPer10Seconds)
                {
                    Response.StatusCode = StatusCodes.Status429TooManyRequests;
                    Response.Headers.Append("Retry-After", "10");
                    return Content("Too many requests. Please try again later.");
                }

                recentRequests.Add(DateTime.UtcNow);
                requestLog[userId] = recentRequests;

                var users = GenerateFakeUsers(100);
                users.Add(new User { Id = 1, FirstName = "Alicia", LastName = "Doe", Email = "a.doe@example", Description = "Facilitator", Active = false });
                users.Add(new User { Id = 2, FirstName = "Bram", LastName = "Doe", Email = " b.doe@example", Description = "EngineerSenior", Active = true });

                var pagedUsers = users.Skip((pageNumber - 1) * pageSize).Take(pageSize).ToList();

                var totalUsers = users.Count;
                var totalPages = (int)Math.Ceiling((double)totalUsers / pageSize);

                var result = new
                {
                    TotalUsers = totalUsers,
                    TotalPages = totalPages,
                    CurrentPage = pageNumber,
                    PageSize = pageSize,
                    Users = pagedUsers
                };

                return Ok(result);
            } else
            {
                return Ok(_users);
            }
        }

        [HttpGet("testconnection")]
        [Authorize(Roles = "Test")]
        public IActionResult TestConnection()
        {
            return Ok();
        }

        [HttpGet("{id}")]
        [Authorize(Roles = "Admin")]
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
        [Authorize(Roles = "Admin")]
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
        [Authorize(Roles = "Admin")]
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