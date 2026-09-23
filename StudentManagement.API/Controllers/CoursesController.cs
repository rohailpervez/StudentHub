using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;
using StudentManagement.API.Models;
using Microsoft.AspNetCore.Authorization;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CoursesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CoursesController(AppDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET: api/Courses
        // Get only courses from logged-in user's organization
        // ============================================================

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Course>>> GetCourses()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            return await _context.Courses
                .Where(c => c.OrganizationId == organizationId.Value)
                .OrderBy(c => c.Id)
                .ToListAsync();
        }

        // ============================================================
        // GET: api/Courses/1
        // ============================================================

        [HttpGet("{id}")]
        public async Task<ActionResult<Course>> GetCourse(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == id &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return NotFound("Course not found.");
            }

            return Ok(course);
        }

        // ============================================================
        // POST: api/Courses
        // ============================================================

        [HttpPost]
        public async Task<ActionResult<Course>> CreateCourse(Course course)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            // Never trust OrganizationId coming from the request.
            // Always use the organization from JWT.
            course.OrganizationId = organizationId.Value;

            _context.Courses.Add(course);

            await _context.SaveChangesAsync();

            return CreatedAtAction(
                nameof(GetCourse),
                new { id = course.Id },
                course
            );
        }

        // ============================================================
        // PUT: api/Courses/1
        // ============================================================

        [HttpPut("{id}")]
        public async Task<ActionResult<Course>> UpdateCourse(
            int id,
            Course course)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            if (id != course.Id)
            {
                return BadRequest("Course ID does not match.");
            }

            var existingCourse = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == id &&
                    c.OrganizationId == organizationId.Value);

            if (existingCourse == null)
            {
                return NotFound("Course not found.");
            }

            existingCourse.Name = course.Name;
            existingCourse.Description = course.Description;
            existingCourse.DurationMonths = course.DurationMonths;
            existingCourse.IsActive = course.IsActive;

            await _context.SaveChangesAsync();

            return Ok(existingCourse);
        }

        // ============================================================
        // DELETE: api/Courses/1
        // ============================================================

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCourse(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == id &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return NotFound("Course not found.");
            }

            _context.Courses.Remove(course);

            await _context.SaveChangesAsync();

            return Ok("Course deleted successfully.");
        }

        // ============================================================
        // GET ORGANIZATION ID FROM JWT
        // ============================================================

        private int? GetOrganizationId()
        {
            var organizationClaim = User.FindFirst("OrganizationId");

            if (organizationClaim == null)
            {
                return null;
            }

            if (int.TryParse(
                organizationClaim.Value,
                out var organizationId))
            {
                return organizationId;
            }

            return null;
        }
    }
}