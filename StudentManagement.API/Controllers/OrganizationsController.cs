using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;
using StudentManagement.API.Models;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class OrganizationsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public OrganizationsController(AppDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET: api/Organizations
        // Get all active organizations
        // ============================================================
        [AllowAnonymous]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Organization>>> GetOrganizations()
        {
            var organizations = await _context.Organizations
                .Where(o => o.IsActive)
                .OrderBy(o => o.Name)
                .ToListAsync();

            return Ok(organizations);
        }

        // ============================================================
        // GET: api/Organizations/1
        // ============================================================

        [HttpGet("{id}")]
        public async Task<ActionResult<Organization>> GetOrganization(int id)
        {
            var organization = await _context.Organizations
                .FirstOrDefaultAsync(o =>
                    o.Id == id &&
                    o.IsActive);

            if (organization == null)
            {
                return NotFound("Organization not found.");
            }

            return Ok(organization);
        }

        // ============================================================
        // POST: api/Organizations
        // Create new organization
        // ============================================================
        [AllowAnonymous]
        [HttpPost]
        public async Task<ActionResult<Organization>> CreateOrganization(
            Organization organization)
        {
            if (string.IsNullOrWhiteSpace(organization.Name))
            {
                return BadRequest("Organization name is required.");
            }

            var name = organization.Name.Trim();

            var existingOrganization = await _context.Organizations
                .FirstOrDefaultAsync(o =>
                    o.Name.ToLower() == name.ToLower());

            if (existingOrganization != null)
            {
                return BadRequest(
                    "An organization with this name already exists.");
            }

            var newOrganization = new Organization
            {
                Name = name,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Organizations.Add(newOrganization);

            await _context.SaveChangesAsync();

            return CreatedAtAction(
                nameof(GetOrganization),
                new { id = newOrganization.Id },
                newOrganization
            );
        }
    }
}