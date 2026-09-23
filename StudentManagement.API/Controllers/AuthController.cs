using BCrypt.Net;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using StudentManagement.API.Data;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(
            AppDbContext context,
            IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        // ============================================================
        // REGISTER ORGANIZATION + FIRST USER
        // POST: api/Auth/register-organization
        // ============================================================

        [HttpPost("register-organization")]
        public async Task<IActionResult> RegisterOrganization(
            RegisterOrganizationRequest request)
        {
            // ========================================================
            // VALIDATION
            // ========================================================

            if (string.IsNullOrWhiteSpace(request.OrganizationName) ||
                string.IsNullOrWhiteSpace(request.FullName) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest("All fields are required.");
            }

            if (request.Password.Length < 6)
            {
                return BadRequest(
                    "Password must be at least 6 characters."
                );
            }

            var organizationName = request.OrganizationName.Trim();
            var fullName = request.FullName.Trim();
            var email = request.Email.Trim().ToLower();

            // ========================================================
            // CHECK EMAIL
            // ========================================================

            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (existingUser != null)
            {
                return BadRequest(
                    "A user with this email already exists."
                );
            }

            // ========================================================
            // CHECK ORGANIZATION NAME
            // ========================================================

            var existingOrganization = await _context.Organizations
                .FirstOrDefaultAsync(o =>
                    o.Name.ToLower() == organizationName.ToLower());

            if (existingOrganization != null)
            {
                return BadRequest(
                    "An organization with this name already exists."
                );
            }

            // ========================================================
            // DATABASE TRANSACTION
            // ========================================================

            await using var transaction =
                await _context.Database.BeginTransactionAsync();

            try
            {
                // ====================================================
                // CREATE ORGANIZATION
                // ====================================================

                var organization = new Models.Organization
                {
                    Name = organizationName,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,

                    // Creator information will be filled
                    // after the first user is created.
                    CreatedByUserId = null,
                    CreatedByName = null,
                    CreatedByEmail = null
                };

                _context.Organizations.Add(organization);

                await _context.SaveChangesAsync();

                // ====================================================
                // CREATE FIRST USER
                // ====================================================

                var user = new Models.User
                {
                    FullName = fullName,
                    Email = email,

                    PasswordHash =
                        BCrypt.Net.BCrypt.HashPassword(
                            request.Password
                        ),

                    
                    // first user is admin
                    Role = "Admin",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,

                    OrganizationId = organization.Id
                };

                _context.Users.Add(user);

                await _context.SaveChangesAsync();

                // ====================================================
                // SAVE ORGANIZATION CREATOR INFORMATION
                // ====================================================
                //
                // Now user.Id is available because the user has
                // already been saved to the database.
                //
                // We save a snapshot of the creator's information.
                // If the user is deleted later, this information
                // will still remain with the organization.
                // ====================================================

                organization.CreatedByUserId = user.Id;
                organization.CreatedByName = user.FullName;
                organization.CreatedByEmail = user.Email;

                await _context.SaveChangesAsync();

                // ====================================================
                // COMMIT
                // ====================================================

                await transaction.CommitAsync();

                // ====================================================
                // RESPONSE
                // ====================================================

                return Ok(new
                {
                    message =
                        "Organization and user account created successfully.",

                    organization = new
                    {
                        id = organization.Id,
                        name = organization.Name,
                        createdByUserId =
                            organization.CreatedByUserId,
                        createdByName =
                            organization.CreatedByName,
                        createdByEmail =
                            organization.CreatedByEmail
                    },

                    user = new
                    {
                        id = user.Id,
                        fullName = user.FullName,
                        email = user.Email,
                        role = user.Role,
                        organizationId = user.OrganizationId
                    }
                });
            }
            catch
            {
                await transaction.RollbackAsync();

                return StatusCode(
                    500,
                    "Failed to create organization."
                );
            }
        }

        // ============================================================
        // REGISTER USER IN EXISTING ORGANIZATION
        // POST: api/Auth/register
        // ============================================================

        [HttpPost("register")]
        public async Task<IActionResult> Register(
            RegisterRequest request)
        {
            // ========================================================
            // VALIDATION
            // ========================================================

            if (string.IsNullOrWhiteSpace(request.FullName) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest("All fields are required.");
            }

            if (request.Password.Length < 6)
            {
                return BadRequest(
                    "Password must be at least 6 characters."
                );
            }

            if (request.OrganizationId <= 0)
            {
                return BadRequest(
                    "OrganizationId is required."
                );
            }

            var email = request.Email.Trim().ToLower();

            // ========================================================
            // CHECK EMAIL
            // ========================================================

            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (existingUser != null)
            {
                return BadRequest(
                    "A user with this email already exists."
                );
            }

            // ========================================================
            // CHECK ORGANIZATION
            // ========================================================

            var organization = await _context.Organizations
                .FirstOrDefaultAsync(o =>
                    o.Id == request.OrganizationId &&
                    o.IsActive);

            if (organization == null)
            {
                return BadRequest(
                    "Invalid or inactive organization."
                );
            }

            // ========================================================
            // CREATE USER
            // ========================================================

            var user = new Models.User
            {
                FullName = request.FullName.Trim(),
                Email = email,

                PasswordHash =
                    BCrypt.Net.BCrypt.HashPassword(
                        request.Password
                    ),

                // Every normal registered user is User.
                Role = "User",

                IsActive = true,
                CreatedAt = DateTime.UtcNow,

                OrganizationId = request.OrganizationId
            };

            _context.Users.Add(user);

            await _context.SaveChangesAsync();

            // ========================================================
            // RESPONSE
            // ========================================================

            return Ok(new
            {
                message = "User registered successfully.",

                userId = user.Id,
                fullName = user.FullName,
                email = user.Email,
                role = user.Role,
                organizationId = user.OrganizationId
            });
        }

        // ============================================================
        // LOGIN
        // POST: api/Auth/login
        // ============================================================

        [HttpPost("login")]
        public async Task<IActionResult> Login(
            LoginRequest request)
        {
            // ========================================================
            // VALIDATION
            // ========================================================

            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(
                    "Email and password are required."
                );
            }

            var email = request.Email.Trim().ToLower();

            // ========================================================
            // FIND USER
            // ========================================================

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (user == null)
            {
                return Unauthorized(
                    "Invalid email or password."
                );
            }

            // ========================================================
            // CHECK ACTIVE USER
            // ========================================================

            if (!user.IsActive)
            {
                return Unauthorized(
                    "This account is inactive."
                );
            }

            // ========================================================
            // CHECK PASSWORD
            // ========================================================

            var passwordValid =
                BCrypt.Net.BCrypt.Verify(
                    request.Password,
                    user.PasswordHash
                );

            if (!passwordValid)
            {
                return Unauthorized(
                    "Invalid email or password."
                );
            }

            // ========================================================
            // ORGANIZATION CHECK
            // ========================================================
            //
            // Normal users must have an active organization.
            //
            // SuperAdmin does NOT depend on an organization.
            // ========================================================

            if (user.Role != "SuperAdmin")
            {
                var organization =
                    await _context.Organizations
                        .FirstOrDefaultAsync(o =>
                            o.Id == user.OrganizationId &&
                            o.IsActive);

                if (organization == null)
                {
                    return Unauthorized(
                        "Your organization is inactive or unavailable."
                    );
                }
            }

            // ========================================================
            // GENERATE JWT
            // ========================================================

            var token = GenerateJwtToken(user);

            // ========================================================
            // RESPONSE
            // ========================================================

            return Ok(new
            {
                message = "Login successful.",

                token,

                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    role = user.Role,
                    organizationId = user.OrganizationId
                }
            });
        }

// ============================================================
// CHANGE PASSWORD
// POST: api/Auth/change-password
// ============================================================

[HttpPost("change-password")]
public async Task<IActionResult> ChangePassword(
    ChangePasswordRequest request)
{
    // ========================================================
    // VALIDATION
    // ========================================================

    if (string.IsNullOrWhiteSpace(request.CurrentPassword) ||
        string.IsNullOrWhiteSpace(request.NewPassword) ||
        string.IsNullOrWhiteSpace(request.ConfirmNewPassword))
    {
        return BadRequest(
            "All password fields are required."
        );
    }

    if (request.NewPassword.Length < 6)
    {
        return BadRequest(
            "New password must be at least 6 characters."
        );
    }

    if (request.NewPassword != request.ConfirmNewPassword)
    {
        return BadRequest(
            "New password and confirm password do not match."
        );
    }

    // ========================================================
    // GET CURRENT LOGGED-IN USER
    // ========================================================

    var userIdClaim = User.FindFirst(
        ClaimTypes.NameIdentifier
    )?.Value;

    if (!int.TryParse(userIdClaim, out var userId))
    {
        return Unauthorized(
            "User information is missing."
        );
    }

    // ========================================================
    // FIND USER
    // ========================================================

    var user = await _context.Users
        .FirstOrDefaultAsync(u => u.Id == userId);

    if (user == null)
    {
        return NotFound(
            "User account not found."
        );
    }

    // ========================================================
    // CHECK CURRENT PASSWORD
    // ========================================================

    var currentPasswordValid =
        BCrypt.Net.BCrypt.Verify(
            request.CurrentPassword,
            user.PasswordHash
        );

    if (!currentPasswordValid)
    {
        return BadRequest(
            "Current password is incorrect."
        );
    }

    // ========================================================
    // PREVENT SAME PASSWORD
    // ========================================================

    if (BCrypt.Net.BCrypt.Verify(
            request.NewPassword,
            user.PasswordHash))
    {
        return BadRequest(
            "New password must be different from your current password."
        );
    }

    // ========================================================
    // UPDATE PASSWORD
    // ========================================================

    user.PasswordHash =
        BCrypt.Net.BCrypt.HashPassword(
            request.NewPassword
        );

    await _context.SaveChangesAsync();

    // ========================================================
    // RESPONSE
    // ========================================================

    return Ok(new
    {
        message =
            "Password changed successfully."
    });
}

        // ============================================================
        // GENERATE JWT TOKEN
        // ============================================================

        private string GenerateJwtToken(
            Models.User user)
        {
            var jwtKey = _configuration["Jwt:Key"];

            if (string.IsNullOrWhiteSpace(jwtKey))
            {
                throw new InvalidOperationException(
                    "JWT key is not configured."
                );
            }

            var claims = new[]
            {
                new Claim(
                    ClaimTypes.NameIdentifier,
                    user.Id.ToString()
                ),

                new Claim(
                    ClaimTypes.Name,
                    user.FullName
                ),

                new Claim(
                    ClaimTypes.Email,
                    user.Email
                ),

                new Claim(
                    ClaimTypes.Role,
                    user.Role
                ),

                new Claim(
                    "OrganizationId",
                    user.OrganizationId.ToString()
                )
            };

            var key =
                new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtKey)
                );

            var credentials =
                new SigningCredentials(
                    key,
                    SecurityAlgorithms.HmacSha256
                );

            var token = new JwtSecurityToken(
                issuer : _configuration["Jwt:Issuer"],
                audience : _configuration["Jwt:Audience"],
                claims : claims,
                expires : DateTime.UtcNow.AddHours(8),
                signingCredentials : credentials
            );

            return new JwtSecurityTokenHandler()
                .WriteToken(token);
        }
    }

    // ================================================================
    // REGISTER ORGANIZATION REQUEST
    // ================================================================

    public class RegisterOrganizationRequest
    {
        public string OrganizationName { get; set; } = string.Empty;

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;
    }

    // ================================================================
    // REGISTER REQUEST
    // ================================================================

    public class RegisterRequest
    {
        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;

        public int OrganizationId { get; set; }
    }

    // ================================================================
    // LOGIN REQUEST
    // ================================================================

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;
    }
    // ================================================================
    // CHANGE PASSWORD REQUEST
    // ================================================================

    public class ChangePasswordRequest
    {
        public string CurrentPassword { get; set; } = string.Empty;

        public string NewPassword { get; set; } = string.Empty;

        public string ConfirmNewPassword { get; set; } = string.Empty;
    }
}