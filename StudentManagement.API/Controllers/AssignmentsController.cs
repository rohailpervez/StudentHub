using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;
using StudentManagement.API.DTOs;
using StudentManagement.API.Models;
using System.Security.Claims;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = "Admin,Teacher,Staff")]
    public class AssignmentsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AssignmentsController(AppDbContext context)
        {
            _context = context;
        }

        // GET ALL ASSIGNMENTS
        // GET: api/Assignments



        [HttpGet]
        public async Task<ActionResult<IEnumerable<AssignmentResponseDto>>> GetAssignments()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var assignments = await _context.Assignments
                .Where(a =>
                    a.OrganizationId == organizationId.Value)
                .Include(a => a.Course)
                .Include(a => a.CreatedByUser)
                .OrderByDescending(a => a.CreatedAt)
                .Select(a => new AssignmentResponseDto
                {
                    Id = a.Id,
                    Title = a.Title,
                    Description = a.Description,
                    DueDate = a.DueDate,
                    IsActive = a.IsActive,
                    CreatedAt = a.CreatedAt,
                    CourseId = a.CourseId,
                    CourseName = a.Course != null
                        ? a.Course.Name
                        : string.Empty,
                    CreatedByUserId = a.CreatedByUserId,
                    CreatedByUserName = a.CreatedByUser != null
                        ? a.CreatedByUser.FullName
                        : string.Empty
                })
                .ToListAsync();

            return Ok(assignments);
        }


        // GET ASSIGNMENT BY ID
        // GET: api/Assignments/5


        [HttpGet("{id}")]
        public async Task<ActionResult<AssignmentResponseDto>> GetAssignment(
            int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var assignment = await _context.Assignments
                .Where(a =>
                    a.Id == id &&
                    a.OrganizationId == organizationId.Value)
                .Include(a => a.Course)
                .Include(a => a.CreatedByUser)
                .Select(a => new AssignmentResponseDto
                {
                    Id = a.Id,
                    Title = a.Title,
                    Description = a.Description,
                    DueDate = a.DueDate,
                    IsActive = a.IsActive,
                    CreatedAt = a.CreatedAt,
                    CourseId = a.CourseId,
                    CourseName = a.Course != null
                        ? a.Course.Name
                        : string.Empty,
                    CreatedByUserId = a.CreatedByUserId,
                    CreatedByUserName = a.CreatedByUser != null
                        ? a.CreatedByUser.FullName
                        : string.Empty
                })
                .FirstOrDefaultAsync();

            if (assignment == null)
            {
                return NotFound("Assignment not found.");
            }

            return Ok(assignment);
        }


        // CREATE ASSIGNMENT
        // POST: api/Assignments
        // Admin / Teacher / Staff


        [HttpPost]
        public async Task<ActionResult<AssignmentResponseDto>> CreateAssignment(
            AssignmentCreateDto request)
        {
            var organizationId = GetOrganizationId();
            var userId = GetCurrentUserId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            if (userId == null)
            {
                return Unauthorized(
                    "User information is missing.");
            }


            // VALIDATION


            if (string.IsNullOrWhiteSpace(request.Title))
            {
                return BadRequest(
                    "Assignment title is required.");
            }

            if (request.CourseId <= 0)
            {
                return BadRequest(
                    "A valid course is required.");
            }


            // CHECK ORGANIZATION


            var organization = await _context.Organizations
                .FirstOrDefaultAsync(o =>
                    o.Id == organizationId.Value &&
                    o.IsActive);

            if (organization == null)
            {
                return BadRequest(
                    "Your organization is inactive or unavailable.");
            }


            // CHECK COURSE
            // Course must belong to the same organization.


            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == request.CourseId &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return BadRequest(
                    "Course not found in your organization.");
            }

            if (!course.IsActive)
            {
                return BadRequest(
                    "The selected course is inactive.");
            }


            // CHECK CURRENT USER

            var currentUser = await _context.Users
                .FirstOrDefaultAsync(u =>
                    u.Id == userId.Value &&
                    u.OrganizationId == organizationId.Value &&
                    u.IsActive);

            if (currentUser == null)
            {
                return Unauthorized(
                    "Your user account is inactive or unavailable.");
            }


            // CREATE ASSIGNMENT


            var assignment = new Assignment
            {
                Title = request.Title.Trim(),

                Description = request.Description?.Trim()
                    ?? string.Empty,

               DueDate = DateTime.SpecifyKind(
                   request.DueDate,
                   DateTimeKind.Utc),

                IsActive = true,

                CreatedAt = DateTime.UtcNow,

                OrganizationId = organizationId.Value,

                CourseId = course.Id,

                CreatedByUserId = userId.Value
            };

            _context.Assignments.Add(assignment);

            await _context.SaveChangesAsync();

            // CREATE NOTIFICATIONS FOR STUDENTS ENROLLED IN THIS COURSE


            var enrolledStudents = await _context.StudentCourses
                .Include(sc => sc.Student)
                .Where(sc =>
                    sc.CourseId == course.Id &&
                    sc.Student != null &&
                    sc.Student.OrganizationId == organizationId.Value &&
                    sc.Student.IsActive)
                .Select(sc => sc.Student!)
                .ToListAsync();

            foreach (var student in enrolledStudents)
            {
                if (student.UserId.HasValue)
                {
                    var notification = new Notification
                    {
                        UserId = student.UserId.Value,
                        OrganizationId = organizationId.Value,
                        Title = "New Assignment",
                        Message = $"A new assignment \"{assignment.Title}\" has been created for {course.Name}.",
                        Type = "Assignment",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow,
                        RelatedId = assignment.Id
                    };

                    _context.Notifications.Add(notification);
                }
            }

            await _context.SaveChangesAsync();


            // RESPONSE


            var response = new AssignmentResponseDto
            {
                Id = assignment.Id,
                Title = assignment.Title,
                Description = assignment.Description,
                DueDate = assignment.DueDate,
                IsActive = assignment.IsActive,
                CreatedAt = assignment.CreatedAt,
                CourseId = course.Id,
                CourseName = course.Name,
                CreatedByUserId = currentUser.Id,
                CreatedByUserName = currentUser.FullName
            };

            return CreatedAtAction(
                nameof(GetAssignment),
                new { id = assignment.Id },
                response);
        }

        // ============================================================
        // UPDATE ASSIGNMENT
        // PUT: api/Assignments/5
        //
        // Admin can update any assignment in own organization.
        // Teacher / Staff can update only their own assignments.
        // ============================================================

        [HttpPut("{id}")]
        public async Task<ActionResult<AssignmentResponseDto>> UpdateAssignment(
            int id,
            AssignmentUpdateDto request)
        {
            var organizationId = GetOrganizationId();
            var userId = GetCurrentUserId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            if (userId == null)
            {
                return Unauthorized(
                    "User information is missing.");
            }

            if (string.IsNullOrWhiteSpace(request.Title))
            {
                return BadRequest(
                    "Assignment title is required.");
            }

            var assignment = await _context.Assignments
                .Include(a => a.Course)
                .Include(a => a.CreatedByUser)
                .FirstOrDefaultAsync(a =>
                    a.Id == id &&
                    a.OrganizationId == organizationId.Value);

            if (assignment == null)
            {
                return NotFound("Assignment not found.");
            }

            // ========================================================
            // ROLE CHECK
            // ========================================================

            var role = User.FindFirst(
                ClaimTypes.Role)?.Value;

            if (role != "Admin" &&
                assignment.CreatedByUserId != userId.Value)
            {
                return Forbid();
            }

            // ========================================================
            // UPDATE
            // ========================================================

            assignment.Title = request.Title.Trim();

            assignment.Description =
                request.Description?.Trim()
                ?? string.Empty;

            assignment.DueDate = DateTime.SpecifyKind(
                request.DueDate,
                DateTimeKind.Utc);

            assignment.IsActive = request.IsActive;

            await _context.SaveChangesAsync();

            return Ok(new AssignmentResponseDto
            {
                Id = assignment.Id,
                Title = assignment.Title,
                Description = assignment.Description,
                DueDate = assignment.DueDate,
                IsActive = assignment.IsActive,
                CreatedAt = assignment.CreatedAt,
                CourseId = assignment.CourseId,
                CourseName = assignment.Course != null
                    ? assignment.Course.Name
                    : string.Empty,
                CreatedByUserId = assignment.CreatedByUserId,
                CreatedByUserName =
                    assignment.CreatedByUser != null
                        ? assignment.CreatedByUser.FullName
                        : string.Empty
            });
        }


        // DELETE ASSIGNMENT
        // DELETE: api/Assignments/5
        // Admin can delete any assignment in own organization.
        // Teacher / Staff can delete only their own assignments.


        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAssignment(int id)
        {
            var organizationId = GetOrganizationId();
            var userId = GetCurrentUserId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            if (userId == null)
            {
                return Unauthorized(
                    "User information is missing.");
            }

            var assignment = await _context.Assignments
                .FirstOrDefaultAsync(a =>
                    a.Id == id &&
                    a.OrganizationId == organizationId.Value);

            if (assignment == null)
            {
                return NotFound("Assignment not found.");
            }

            // ========================================================
            // ROLE CHECK
            // ========================================================

            var role = User.FindFirst(
                ClaimTypes.Role)?.Value;

            if (role != "Admin" &&
                assignment.CreatedByUserId != userId.Value)
            {
                return Forbid();
            }

            _context.Assignments.Remove(assignment);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message =
                    "Assignment deleted successfully."
            });
        }


// UPLOAD ASSIGNMENT ATTACHMENT PDF
// POST: api/Assignments/{id}/attachment


[HttpPost("{id}/attachment")]
[RequestSizeLimit(10 * 1024 * 1024)]
public async Task<IActionResult> UploadAssignmentAttachment(
    int id,
    IFormFile file)
{
    var organizationId = GetOrganizationId();
    var userId = GetCurrentUserId();

    if (organizationId == null)
    {
        return Unauthorized(
            "Organization information is missing.");
    }

    if (userId == null)
    {
        return Unauthorized(
            "User information is missing.");
    }

    // ========================================================
    // FILE VALIDATION
    // ========================================================

    if (file == null || file.Length == 0)
    {
        return BadRequest(
            "Please select a PDF file.");
    }

    if (file.Length > 10 * 1024 * 1024)
    {
        return BadRequest(
            "PDF file size cannot exceed 10 MB.");
    }

    var extension = Path.GetExtension(file.FileName);

    if (!string.Equals(
            extension,
            ".pdf",
            StringComparison.OrdinalIgnoreCase))
    {
        return BadRequest(
            "Only PDF files are allowed.");
    }

    // ========================================================
    // VERIFY PDF SIGNATURE
    // ========================================================

    await using var memoryStream = new MemoryStream();

    await file.CopyToAsync(memoryStream);

    var fileBytes = memoryStream.ToArray();

    if (fileBytes.Length < 5 ||
        fileBytes[0] != 0x25 ||
        fileBytes[1] != 0x50 ||
        fileBytes[2] != 0x44 ||
        fileBytes[3] != 0x46 ||
        fileBytes[4] != 0x2D)
    {
        return BadRequest(
            "The selected file is not a valid PDF.");
    }

    // FIND ASSIGNMENT
    // Assignment must belong to logged-in user's organization.


    var assignment = await _context.Assignments
        .FirstOrDefaultAsync(a =>
            a.Id == id &&
            a.OrganizationId == organizationId.Value);

    if (assignment == null)
    {
        return NotFound(
            "Assignment not found.");
    }

    // ROLE CHECK
    // Admin can attach to any assignment in own organization.
    // Teacher / Staff can attach only to their own assignment.

    var role = User.FindFirst(
        ClaimTypes.Role)?.Value;

    if (role != "Admin" &&
        assignment.CreatedByUserId != userId.Value)
    {
        return Forbid();
    }

    // ========================================================
    // UPLOAD FOLDER
    // ========================================================

    var uploadFolder = Path.Combine(
        Directory.GetCurrentDirectory(),
        "wwwroot",
        "uploads",
        "assignments");

    Directory.CreateDirectory(uploadFolder);

    // ========================================================
    // DELETE OLD ATTACHMENT IF ONE EXISTS
    // ========================================================

    if (!string.IsNullOrWhiteSpace(
            assignment.AttachmentFilePath))
    {
        var oldFileName = Path.GetFileName(
            assignment.AttachmentFilePath);

        if (!string.IsNullOrWhiteSpace(oldFileName))
        {
            var oldPhysicalPath = Path.Combine(
                uploadFolder,
                oldFileName);

            if (System.IO.File.Exists(oldPhysicalPath))
            {
                System.IO.File.Delete(
                    oldPhysicalPath);
            }
        }
    }

    // ========================================================
    // GENERATE SAFE UNIQUE FILE NAME
    // ========================================================

    var storedFileName =
        $"{Guid.NewGuid():N}.pdf";

    var physicalFilePath = Path.Combine(
        uploadFolder,
        storedFileName);

    await System.IO.File.WriteAllBytesAsync(
        physicalFilePath,
        fileBytes);

    // ========================================================
    // SAVE FILE INFORMATION
    // ========================================================

    assignment.AttachmentFileName =
        Path.GetFileName(file.FileName);

    assignment.AttachmentFilePath =
        $"uploads/assignments/{storedFileName}";

    await _context.SaveChangesAsync();

    // ========================================================
    // RESPONSE
    // ========================================================

    return Ok(new
    {
        message = "Assignment PDF attached successfully.",
        assignmentId = assignment.Id,
        fileName = assignment.AttachmentFileName,
        filePath = assignment.AttachmentFilePath,
        fileSize = file.Length,
        contentType = "application/pdf"
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
                out var organizationId))
            {
                return organizationId;
            }

            return null;
        }

        // ============================================================
        // GET CURRENT USER ID FROM JWT
        // ============================================================

        private int? GetCurrentUserId()
        {
            var claim = User.FindFirst(
                ClaimTypes.NameIdentifier);

            if (claim == null)
            {
                return null;
            }

            if (int.TryParse(
                claim.Value,
                out var userId))
            {
                return userId;
            }

            return null;
        }
    }
}