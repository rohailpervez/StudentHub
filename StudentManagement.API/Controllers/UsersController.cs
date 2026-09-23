using BCrypt.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;
using StudentManagement.API.Models;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,SuperAdmin")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET USERS
        // GET: api/Users
        // ============================================================

        [HttpGet]
        public async Task<IActionResult> GetUsers()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information not found.");
            }

            var users = await _context.Users
                .Where(u => u.OrganizationId == organizationId.Value)
                .OrderByDescending(u => u.CreatedAt)
                .Select(u => new
                {
                    id = u.Id,
                    fullName = u.FullName,
                    email = u.Email,
                    role = u.Role,
                    isActive = u.IsActive,
                    createdAt = u.CreatedAt,
                    organizationId = u.OrganizationId
                })
                .ToListAsync();

            return Ok(users);
        }

        // ============================================================
        // GET USER BY ID
        // GET: api/Users/5
        // ============================================================

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUser(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information not found.");
            }

            var user = await _context.Users
                .Where(u =>
                    u.Id == id &&
                    u.OrganizationId == organizationId.Value)
                .Select(u => new
                {
                    id = u.Id,
                    fullName = u.FullName,
                    email = u.Email,
                    role = u.Role,
                    isActive = u.IsActive,
                    createdAt = u.CreatedAt,
                    organizationId = u.OrganizationId
                })
                .FirstOrDefaultAsync();

            if (user == null)
            {
                return NotFound("User not found.");
            }

            return Ok(user);
        }

        // ============================================================
        // CREATE TEACHER / STAFF
        // POST: api/Users/create-member
        //
        // Admin can create:
        // Teacher
        // Staff
        // ============================================================

        [HttpPost("create-member")]
        public async Task<IActionResult> CreateMember(
            CreateMemberRequest request)
        {
            // ========================================================
            // GET CURRENT ADMIN ORGANIZATION
            // ========================================================

            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information not found.");
            }

            // ========================================================
            // VALIDATION
            // ========================================================

            if (string.IsNullOrWhiteSpace(request.FullName))
            {
                return BadRequest(
                    "Full name is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(
                    "Email is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(
                    "Password is required.");
            }

            if (request.Password.Length < 6)
            {
                return BadRequest(
                    "Password must be at least 6 characters.");
            }

            // ========================================================
            // ROLE VALIDATION
            // ========================================================

            var role = request.Role.Trim();

            if (role != "Teacher" && role != "Staff")
            {
                return BadRequest(
                    "Role must be either Teacher or Staff.");
            }

            // ========================================================
            // CLEAN DATA
            // ========================================================

            var fullName = request.FullName.Trim();

            var email = request.Email
                .Trim()
                .ToLower();

            // ========================================================
            // CHECK EMAIL
            //
            // Email must be unique across the complete system.
            // ========================================================

            var existingUser = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == email);

            if (existingUser != null)
            {
                return BadRequest(
                    "A user with this email already exists.");
            }

            // ========================================================
            // CHECK ORGANIZATION
            // ========================================================

            var organization = await _context.Organizations
                .FirstOrDefaultAsync(o =>
                    o.Id == organizationId.Value &&
                    o.IsActive);

            if (organization == null)
            {
                return BadRequest(
                    "Your organization is inactive or unavailable.");
            }

            // ========================================================
            // CREATE TEACHER / STAFF
            // ========================================================

            var user = new User
            {
                FullName = fullName,

                Email = email,

                PasswordHash =
                    BCrypt.Net.BCrypt.HashPassword(
                        request.Password
                    ),

                Role = role,

                IsActive = true,

                CreatedAt = DateTime.UtcNow,

                OrganizationId = organizationId.Value
            };

            _context.Users.Add(user);

            await _context.SaveChangesAsync();

            // ========================================================
            // RESPONSE
            // ========================================================

            return Ok(new
            {
                message =
                    $"{role} account created successfully.",

                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    role = user.Role,
                    isActive = user.IsActive,
                    organizationId = user.OrganizationId,
                    createdAt = user.CreatedAt
                }
            });
        }

        // ============================================================
        // UPDATE USER
        // PUT: api/Users/5
        // ============================================================

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(
            int id,
            UpdateUserRequest request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information not found.");
            }

            if (string.IsNullOrWhiteSpace(request.FullName) ||
                string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(
                    "Full name and email are required.");
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Id == id &&
                    u.OrganizationId == organizationId.Value);

            if (user == null)
            {
                return NotFound("User not found.");
            }

            var email = request.Email
                .Trim()
                .ToLower();

            var emailExists = await _context.Users
                .AnyAsync(u =>
                    u.Email == email &&
                    u.Id != id);

            if (emailExists)
            {
                return BadRequest(
                    "A user with this email already exists.");
            }

            user.FullName = request.FullName.Trim();

            user.Email = email;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "User updated successfully.",

                user = new
                {
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    role = user.Role,
                    isActive = user.IsActive,
                    organizationId = user.OrganizationId
                }
            });
        }

        // ============================================================
        // ACTIVATE / DEACTIVATE USER
        // PATCH: api/Users/5/status
        // ============================================================

        [HttpPatch("{id}/status")]
        public async Task<IActionResult> UpdateUserStatus(
            int id,
            UpdateUserStatusRequest request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information not found.");
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Id == id &&
                    u.OrganizationId == organizationId.Value);

            if (user == null)
            {
                return NotFound("User not found.");
            }

            user.IsActive = request.IsActive;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = request.IsActive
                    ? "User activated successfully."
                    : "User deactivated successfully.",

                userId = user.Id,

                isActive = user.IsActive
            });
        }

        // ============================================================
        // DELETE USER
        // DELETE: api/Users/5
        // ============================================================

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information not found.");
            }

            var user = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Id == id &&
                    u.OrganizationId == organizationId.Value);

            if (user == null)
            {
                return NotFound("User not found.");
            }

            // ========================================================
            // DO NOT ALLOW DELETING SUPERADMIN
            // ========================================================

            if (user.Role == "SuperAdmin")
            {
                return BadRequest(
                    "SuperAdmin cannot be deleted.");
            }

            // ========================================================
            // DELETE USER
            // ========================================================

            _context.Users.Remove(user);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "User deleted successfully."
            });
        }

        // ============================================================
        // GET ORGANIZATION ID FROM JWT
        // ============================================================

        private int? GetOrganizationId()
        {
            var claim = User.FindFirst("OrganizationId");

            if (claim == null)
            {
                return null;
            }

            if (int.TryParse(
                claim.Value,
                out int organizationId))
            {
                return organizationId;
            }

            return null;
        }
    }

    // ================================================================
    // CREATE MEMBER REQUEST
    // ================================================================

    public class CreateMemberRequest
    {
        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;

        public string Role { get; set; } = string.Empty;
    }

    // ================================================================
    // UPDATE USER REQUEST
    // ================================================================

    public class UpdateUserRequest
    {
        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;
    }

    // ================================================================
    // UPDATE USER STATUS REQUEST
    // ================================================================

    public class UpdateUserStatusRequest
    {
        public bool IsActive { get; set; }
    }
}