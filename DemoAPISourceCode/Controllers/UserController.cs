using Bogus;
using ErrorhandlingDemoAPI.Localization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Swashbuckle.AspNetCore.Annotations;
using System.ComponentModel.DataAnnotations;

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

        /// <summary>
        /// Retrieves a paginated list of users
        /// </summary>
        /// <param name="simulateRateLimiting">If true, the request will return a 429 TooManyRequests response to simulate rate limiting</param>
        /// <param name="pageNumber">The page number for pagination. Defaults to 1</param>
        /// <param name="pageSize">The number of users per page. Defaults to 10</param>
        /// <returns>A paginated list of users or a 429 TooManyRequests response if rate limiting is simulated</returns>              
        [HttpGet()]
        [Authorize(Roles = "Admin")]
        [SwaggerResponse(200, "Returns the list of users", typeof(User))]
        [SwaggerResponse(429, "Too many requests – returned if the 'SimulateRateLimiting' header is set to true")]
        public IActionResult GetUsers([FromHeader(Name = "SimulateRateLimiting")] bool simulateRateLimiting, int pageNumber = 1, int pageSize = 10)
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

        /// <summary>
        /// Retrieves a user by their unique identifier
        /// </summary>
        /// <param name="id">The unique identifier of the user to retrieve</param>
        /// <returns>Returns the user if found, or a 404 Not Found if the user does not exist</returns>
        /// <remarks>
        /// This API requests support the 'Accept-Language' header for language-specific error responses
        /// The 'Accept-Language' header can specify the preferred language (e.g., 'en' for English or 'de' for German)
        /// If the header is not provided, it defaults to 'de' (German)
        /// </remarks>
        [HttpGet("{id}")]
        [Authorize(Roles = "Admin")]
        [SwaggerResponse(200, "Returns the user if found.", typeof(User))]
        [SwaggerResponse(404, "Not Found if the user with the given ID does not exist.")]
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

        /// <summary>
        /// Creates a new user
        /// </summary>
        /// <param name="user">The user object containing the details of the user to be created</param>
        /// <param name="retriesBeforeSuccess">The number of retry attempts needed before creating the user. If greater than 0 a 408 Request Timeout will be returned and retry logic needs to be implemented</param>
        /// <returns>Returns the created user if successful, a 400 Bad Request if a required property is missing, or a 408 Request Timeout</returns>
        [HttpPost()]
        [Authorize(Roles = "Admin")]
        [SwaggerResponse(200, "Returns the created user if successful.", typeof(User))]
        [SwaggerResponse(400, "Bad Request if a property is missing.")]
        [SwaggerResponse(408, "Request Timeout if creation fails after retry attempts.")]
        public IActionResult CreateUser([FromBody] User user, [FromHeader(Name = "RetriesBeforeSuccess")] int retriesBeforeSuccess)
        {
            if (retriesBeforeSuccess <= 0) retriesBeforeSuccess = 0;

            if (retriesBeforeSuccess > 0 && _attemptCount < retriesBeforeSuccess)
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

        /// <summary>
        /// Retrieves a user by their email address
        /// </summary>
        /// <param name="email">The unique identifier of the user to retrieve.</param>
        /// <returns>Returns the user if found, or a 404 Not Found if the user does not exist.</returns>
        [HttpGet("search")]
        [Authorize(Roles = "Admin")]
        [SwaggerResponse(200, "Returns the user if found.", typeof(User))]
        [SwaggerResponse(404, "Not Found if the user with the given ID does not exist.")]      
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
        public int Id { get; internal set; }

        /// <summary>
        /// The FirstName of the user
        /// </summary>
        /// <example>John</example>
        [Required(ErrorMessage = "FirstName is required")]
        public string FirstName { get; set; }

        /// <summary>
        /// The lastName of the user
        /// </summary>
        /// <example>Doe</example>
        [Required(ErrorMessage = "LastName is required")]
        public string LastName { get; set; }

        /// <summary>
        /// The Email of the user
        /// </summary>
        /// <example>Doe</example>
        [Required(ErrorMessage = "Email is required")]
        public string Email { get; set; }

        /// <summary>
        /// The Description of the user
        /// </summary>
        /// <example>Doe</example>
        [Required(ErrorMessage = "Description is required")]
        public string Description { get; set; }

        /// <summary>
        /// Defines if the user is active or not. When a user is created, this value will automatically be set to 'false'
        /// </summary>
        /// <example>False</example>
        public bool? Active { get; internal set; }
    }
}