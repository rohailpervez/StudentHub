using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "SuperAdmin")]
    public class SuperAdminController : ControllerBase
    {
        private readonly AppDbContext _context;

        public SuperAdminController(AppDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET ALL ORGANIZATIONS
        // GET: api/SuperAdmin/organizations
        // ============================================================

        [HttpGet("organizations")]
        public async Task<IActionResult> GetOrganizations()
        {
            var organizations = await _context.Organizations
                .Include(o => o.Users)
                .Include(o => o.Courses)
                .Include(o => o.Students)
                .OrderByDescending(o => o.CreatedAt)
                .Select(o => new
                {
                    id = o.Id,
                    name = o.Name,
                    isActive = o.IsActive,
                    createdAt = o.CreatedAt,

                    usersCount = o.Users.Count,
                    coursesCount = o.Courses.Count,
                    studentsCount = o.Students.Count,

                    users = o.Users
                        .Select(u => new
                        {
                            id = u.Id,
                            fullName = u.FullName,
                            email = u.Email,
                            role = u.Role,
                            isActive = u.IsActive,
                            createdAt = u.CreatedAt
                        })
                        .ToList()
                })
                .ToListAsync();

            return Ok(organizations);
        }

        // ============================================================
        // GET SINGLE ORGANIZATION DETAILS
        // GET: api/SuperAdmin/organizations/{id}
        // ============================================================

        [HttpGet("organizations/{id}")]
        public async Task<IActionResult> GetOrganization(int id)
        {
            var organization = await _context.Organizations
                .Include(o => o.Users)
                .Include(o => o.Courses)
                .Include(o => o.Students)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (organization == null)
            {
                return NotFound("Organization not found.");
            }

            return Ok(new
            {
                id = organization.Id,
                name = organization.Name,
                isActive = organization.IsActive,
                createdAt = organization.CreatedAt,

                users = organization.Users
                    .Select(u => new
                    {
                        id = u.Id,
                        fullName = u.FullName,
                        email = u.Email,
                        role = u.Role,
                        isActive = u.IsActive,
                        createdAt = u.CreatedAt
                    })
                    .ToList(),

                courses = organization.Courses
                    .Select(c => new
                    {
                        id = c.Id,
                        name = c.Name,
                        description = c.Description,
                        durationMonths = c.DurationMonths,
                        isActive = c.IsActive
                    })
                    .ToList(),

                students = organization.Students
                    .Select(s => new
                    {
                        id = s.Id,
                        name = s.Name,
                        email = s.Email,
                        phone = s.Phone,
                        courseId = s.CourseId
                    })
                    .ToList()
            });
        }

        // ============================================================
        // DELETE USER
        // DELETE: api/SuperAdmin/users/{id}
        // ============================================================

        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null)
            {
                return NotFound("User not found.");
            }

            // ========================================================
            // NEVER ALLOW DELETING SUPER ADMIN
            // ========================================================

            if (user.Role == "SuperAdmin")
            {
                return BadRequest(
                    "SuperAdmin account cannot be deleted."
                );
            }

            _context.Users.Remove(user);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "User deleted successfully.",
                userId = id
            });
        }

        // ============================================================
        // DELETE ORGANIZATION
        // DELETE: api/SuperAdmin/organizations/{id}
        // ============================================================

        [HttpDelete("organizations/{id}")]
        public async Task<IActionResult> DeleteOrganization(int id)
        {
            var organization = await _context.Organizations
                .Include(o => o.Users)
                .Include(o => o.Courses)
                .Include(o => o.Students)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (organization == null)
            {
                return NotFound("Organization not found.");
            }

            // ========================================================
            // DELETE ALL STUDENTS
            // ========================================================

            _context.Students.RemoveRange(
                organization.Students
            );

            // ========================================================
            // DELETE ALL COURSES
            // ========================================================

            _context.Courses.RemoveRange(
                organization.Courses
            );

            // ========================================================
            // DELETE ALL USERS
            // ========================================================

            _context.Users.RemoveRange(
                organization.Users
            );

            // ========================================================
            // DELETE ORGANIZATION
            // ========================================================

            _context.Organizations.Remove(
                organization
            );

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message =
                    "Organization and all related users, courses and students deleted successfully.",

                organizationId = id
            });
        }
    }
} 