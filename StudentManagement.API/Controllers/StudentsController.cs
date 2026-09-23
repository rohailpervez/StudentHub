using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;
using StudentManagement.API.DTOs;
using StudentManagement.API.Models;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class StudentsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _environment;

       public StudentsController(
           AppDbContext context,
           IWebHostEnvironment environment)
       {
           _context = context;
           _environment = environment;
       }
        // ============================================================
        // GET: api/Students
        // ============================================================

        [HttpGet]
        public async Task<IActionResult> GetStudents()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            var students = await _context.Students
                .Where(s => s.OrganizationId == organizationId.Value)
                .Include(s => s.Course)
                .Include(s => s.StudentCourses)
                    .ThenInclude(sc => sc.Course)
                .OrderBy(s => s.Id)
                .ToListAsync();

            return Ok(
                students
                    .Select(MapStudentResponse)
                    .ToList()
            );
        }

        // ============================================================
        // GET: api/Students/1
        // ============================================================

        [HttpGet("{id}")]
        public async Task<IActionResult> GetStudent(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            var student = await _context.Students
                .Where(s =>
                    s.Id == id &&
                    s.OrganizationId == organizationId.Value)
                .Include(s => s.Course)
                .Include(s => s.StudentCourses)
                    .ThenInclude(sc => sc.Course)
                .FirstOrDefaultAsync();

            if (student == null)
            {
                return NotFound("Student not found.");
            }


            return Ok(MapStudentResponse(student));
        }
// ============================================================
// GET: api/Students/me
// Logged-in student's own profile
// ============================================================

[HttpGet("me")]
public async Task<IActionResult> GetMyStudent()
{
    var organizationId = GetOrganizationId();

    if (organizationId == null)
    {
        return Unauthorized("Organization information is missing.");
    }

    var userIdClaim = User.FindFirst(
        System.Security.Claims.ClaimTypes.NameIdentifier
    )?.Value;

    if (!int.TryParse(userIdClaim, out var userId))
    {
        return Unauthorized("User information is missing.");
    }

    var student = await _context.Students
        .Where(s =>
            s.UserId == userId &&
            s.OrganizationId == organizationId.Value)
        .Include(s => s.Course)
        .Include(s => s.StudentCourses)
            .ThenInclude(sc => sc.Course)
        .FirstOrDefaultAsync();

    if (student == null)
    {
        return NotFound("Student profile not found.");
    }

    return Ok(MapStudentResponse(student));
}

// ============================================================
// PUT: api/Students/me
// Logged-in student's own profile update
// ============================================================

[HttpPut("me")]
public async Task<IActionResult> UpdateMyStudentProfile(
    StudentProfileUpdateDto dto)
{
    var organizationId = GetOrganizationId();

    if (organizationId == null)
    {
        return Unauthorized("Organization information is missing.");
    }

    var userIdClaim = User.FindFirst(
        System.Security.Claims.ClaimTypes.NameIdentifier
    )?.Value;

    if (!int.TryParse(userIdClaim, out var userId))
    {
        return Unauthorized("User information is missing.");
    }

    // --------------------------------------------------------
    // VALIDATE BASIC INFORMATION
    // --------------------------------------------------------

    if (string.IsNullOrWhiteSpace(dto.Name))
    {
        return BadRequest("Name is required.");
    }

    if (string.IsNullOrWhiteSpace(dto.Email))
    {
        return BadRequest("Email is required.");
    }

    // --------------------------------------------------------
    // FIND LOGGED-IN STUDENT
    // --------------------------------------------------------

    var student = await _context.Students
        .FirstOrDefaultAsync(s =>
            s.UserId == userId &&
            s.OrganizationId == organizationId.Value);

    if (student == null)
    {
        return NotFound("Student profile not found.");
    }

    // --------------------------------------------------------
    // FIND LINKED USER ACCOUNT
    // --------------------------------------------------------

    var user = await _context.Users
        .FirstOrDefaultAsync(u =>
            u.Id == userId &&
            u.OrganizationId == organizationId.Value);

    if (user == null)
    {
        return NotFound("User account not found.");
    }

    // --------------------------------------------------------
    // NORMALIZE EMAIL
    // --------------------------------------------------------

    var email = dto.Email.Trim().ToLower();

    // --------------------------------------------------------
    // CHECK IF EMAIL IS ALREADY USED BY ANOTHER USER
    // --------------------------------------------------------

    var emailAlreadyExists = await _context.Users
        .AnyAsync(u =>
            u.Email == email &&
            u.Id != userId);

    if (emailAlreadyExists)
    {
        return BadRequest(
            "A user with this email already exists.");
    }

    // --------------------------------------------------------
    // UPDATE STUDENT PROFILE
    // --------------------------------------------------------

    student.Name = dto.Name.Trim();
    student.Email = email;
    student.Phone = dto.Phone?.Trim() ?? string.Empty;

    // --------------------------------------------------------
    // UPDATE LINKED LOGIN ACCOUNT
    // --------------------------------------------------------

    user.FullName = dto.Name.Trim();
    user.Email = email;

    await _context.SaveChangesAsync();

    // --------------------------------------------------------
    // RETURN UPDATED PROFILE
    // --------------------------------------------------------

    return Ok(MapStudentResponse(student));
}
        // ============================================================
        // POST: api/Students
        // ============================================================

        [HttpPost]
        public async Task<IActionResult> AddStudent(StudentCreateDto dto)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            // NORMALIZE EMAIL
            var email = dto.Email.Trim().ToLower();

            // VALIDATE PASSWORD

            if (string.IsNullOrWhiteSpace(dto.Password) ||
                dto.Password.Length < 6)
            {
                return BadRequest(
                    "Password must be at least 6 characters.");
            }

            // --------------------------------------------------------
            // CHECK USER EMAIL
            // --------------------------------------------------------

            var emailAlreadyExists = await _context.Users
                .AnyAsync(u => u.Email == email);

            if (emailAlreadyExists)
            {
                return BadRequest(
                    "A user with this email already exists.");
            }

            // --------------------------------------------------------
            // VALIDATE COURSE IDS
            // --------------------------------------------------------

            var courseIds = dto.CourseIds
                .Distinct()
                .ToList();

            if (courseIds.Count > 0)
            {
                var validCourseIds = await _context.Courses
                    .Where(c =>
                        courseIds.Contains(c.Id) &&
                        c.OrganizationId == organizationId.Value)
                    .Select(c => c.Id)
                    .ToListAsync();

                if (validCourseIds.Count != courseIds.Count)
                {
                    return BadRequest(
                        "One or more selected courses were not found in your organization.");
                }
            }

            // --------------------------------------------------------
            // START TRANSACTION
            // --------------------------------------------------------

            await using var transaction =
                await _context.Database.BeginTransactionAsync();

            try
            {
                // ----------------------------------------------------
                // CREATE USER LOGIN ACCOUNT
                // ----------------------------------------------------

                var user = new User
                {
                    FullName = dto.Name.Trim(),
                    Email = email,

                    // Password is stored only as a BCrypt hash.
                    PasswordHash =
                        BCrypt.Net.BCrypt.HashPassword(dto.Password),

                    Role = "User",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    OrganizationId = organizationId.Value
                };

                _context.Users.Add(user);

                await _context.SaveChangesAsync();

                // ----------------------------------------------------
                // CREATE STUDENT
                // ----------------------------------------------------

                var student = new Student
                {
                    Name = dto.Name.Trim(),
                    Email = email,
                    Phone = dto.Phone,

                    OrganizationId = organizationId.Value,
                    IsActive = true,

                    // Temporary compatibility:
                    // first selected course remains in old CourseId.
                    CourseId = courseIds.Count > 0
                        ? courseIds[0]
                        : null,

                    // Link Student with User login account.
                    UserId = user.Id
                };

                _context.Students.Add(student);

                await _context.SaveChangesAsync();

                // ----------------------------------------------------
                // CREATE STUDENT ↔ COURSE RELATIONSHIPS
                // ----------------------------------------------------

                foreach (var courseId in courseIds)
                {
                    _context.StudentCourses.Add(new StudentCourse
                    {
                        StudentId = student.Id,
                        CourseId = courseId
                    });
                }

                await _context.SaveChangesAsync();

                // ----------------------------------------------------
                // COMMIT TRANSACTION
                // ----------------------------------------------------

                await transaction.CommitAsync();

                // ----------------------------------------------------
                // LOAD RELATIONSHIPS
                // ----------------------------------------------------

                await _context.Entry(student)
                    .Reference(s => s.Course)
                    .LoadAsync();

                await _context.Entry(student)
                    .Collection(s => s.StudentCourses)
                    .Query()
                    .Include(sc => sc.Course)
                    .LoadAsync();

                // ----------------------------------------------------
                // RETURN SAFE RESPONSE
                // ----------------------------------------------------

                return CreatedAtAction(
                    nameof(GetStudent),
                    new { id = student.Id },
                    MapStudentResponse(student)
                );
            }
            catch
            {
                // ----------------------------------------------------
                // ROLLBACK IF ANYTHING FAILS
                // ----------------------------------------------------

                await transaction.RollbackAsync();

                return StatusCode(
                    500,
                    "Failed to create student and login account.");
            }
        }

        // ============================================================
        // PUT: api/Students/1
        // ============================================================

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateStudent(
            int id,
            StudentUpdateDto dto)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            // --------------------------------------------------------
            // FIND STUDENT
            // --------------------------------------------------------

            var existingStudent = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == id &&
                    s.OrganizationId == organizationId.Value);

            if (existingStudent == null)
            {
                return NotFound("Student not found.");
            }

          // --------------------------------------------------------
          // SAVE OLD COURSE IDS FOR NOTIFICATION CHECK
          // --------------------------------------------------------

          var oldCourseIds = await _context.StudentCourses
              .Where(sc => sc.StudentId == existingStudent.Id)
              .Select(sc => sc.CourseId)
              .ToListAsync();

            // --------------------------------------------------------
            // VALIDATE COURSE IDS
            // --------------------------------------------------------

            var courseIds = dto.CourseIds
                .Distinct()
                .ToList();

            if (courseIds.Count > 0)
            {
                var validCourseIds = await _context.Courses
                    .Where(c =>
                        courseIds.Contains(c.Id) &&
                        c.OrganizationId == organizationId.Value)
                    .Select(c => c.Id)
                    .ToListAsync();

                if (validCourseIds.Count != courseIds.Count)
                {
                    return BadRequest(
                        "One or more selected courses were not found in your organization.");
                }
            }

            // --------------------------------------------------------
            // UPDATE BASIC INFORMATION
            // --------------------------------------------------------

            existingStudent.Name = dto.Name;
            existingStudent.Email = dto.Email;
            existingStudent.Phone = dto.Phone;
            existingStudent.IsActive = dto.IsActive;

            // Temporary compatibility:
            // first selected course remains in old CourseId.
            existingStudent.CourseId = courseIds.Count > 0
                ? courseIds[0]
                : null;

            // --------------------------------------------------------
            // REMOVE OLD STUDENT ↔ COURSE RELATIONSHIPS
            // --------------------------------------------------------

            var oldStudentCourses = await _context.StudentCourses
                .Where(sc => sc.StudentId == existingStudent.Id)
                .ToListAsync();

            _context.StudentCourses.RemoveRange(oldStudentCourses);

            // --------------------------------------------------------
            // ADD NEW STUDENT ↔ COURSE RELATIONSHIPS
            // --------------------------------------------------------

            foreach (var courseId in courseIds)
            {
                _context.StudentCourses.Add(new StudentCourse
                {
                    StudentId = existingStudent.Id,
                    CourseId = courseId
                });
            }

            await _context.SaveChangesAsync();

            // ============================================================
            // CREATE NOTIFICATIONS FOR NEWLY ASSIGNED COURSES
            // ============================================================

            if (existingStudent.UserId.HasValue)
            {
                var newlyAssignedCourseIds = courseIds
                    .Except(oldCourseIds)
                    .ToList();

                if (newlyAssignedCourseIds.Count > 0)
                {
                    var newlyAssignedCourses = await _context.Courses
                        .Where(c =>
                            newlyAssignedCourseIds.Contains(c.Id) &&
                            c.OrganizationId == organizationId.Value)
                        .ToListAsync();

                    foreach (var course in newlyAssignedCourses)
                    {
                        var notification = new Notification
                        {
                            UserId = existingStudent.UserId.Value,
                            OrganizationId = organizationId.Value,
                            Title = "New Course Assigned",
                            Message =
                                $"You have been assigned to the course \"{course.Name}\".",
                            Type = "Course",
                            IsRead = false,
                            CreatedAt = DateTime.UtcNow,
                            RelatedId = course.Id
                        };

                        _context.Notifications.Add(notification);
                    }

                    await _context.SaveChangesAsync();
                }
            }

            // --------------------------------------------------------
            // LOAD RELATIONSHIPS
            // --------------------------------------------------------

            await _context.Entry(existingStudent)
                .Reference(s => s.Course)
                .LoadAsync();

            await _context.Entry(existingStudent)
                .Collection(s => s.StudentCourses)
                .Query()
                .Include(sc => sc.Course)
                .LoadAsync();

            // --------------------------------------------------------
            // RETURN SAFE RESPONSE
            // --------------------------------------------------------

            return Ok(MapStudentResponse(existingStudent));
        }

        // ============================================================
        // DELETE: api/Students/1
        // ============================================================

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStudent(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == id &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return NotFound("Student not found.");
            }

            _context.Students.Remove(student);

            await _context.SaveChangesAsync();

            return Ok("Student deleted successfully.");
        }

        // ============================================================
        // PATCH: api/Students/1/toggle-status
        // ============================================================

        [HttpPatch("{id}/toggle-status")]
        public async Task<IActionResult> ToggleStudentStatus(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == id &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return NotFound("Student not found.");
            }

            student.IsActive = !student.IsActive;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = student.IsActive
                    ? "Student activated successfully."
                    : "Student deactivated successfully.",

                isActive = student.IsActive
            });
        }

        [HttpPost("me/profile-picture")]
        public async Task<IActionResult> UploadMyProfilePicture(
            IFormFile file)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var userIdClaim = User.FindFirst(
                System.Security.Claims.ClaimTypes.NameIdentifier
            )?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized(
                    "User information is missing.");
            }

            if (file == null || file.Length == 0)
            {
                return BadRequest(
                    "Please select an image file.");
            }

            const long maxFileSize = 5 * 1024 * 1024;

            if (file.Length > maxFileSize)
            {
                return BadRequest(
                    "Profile picture must be 5 MB or smaller.");
            }

            var allowedExtensions = new[]
            {
                ".jpg",
                ".jpeg",
                ".png",
                ".webp"
            };

            var extension = Path.GetExtension(file.FileName)
                .ToLowerInvariant();

            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(
                    "Only JPG, JPEG, PNG, and WEBP images are allowed.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.UserId == userId &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return NotFound(
                    "Student profile not found.");
            }

            var uploadsFolder = Path.Combine(
                _environment.WebRootPath ?? Path.Combine(
                    _environment.ContentRootPath,
                    "wwwroot"),
                "uploads",
                "profile-pictures");

            Directory.CreateDirectory(uploadsFolder);

            if (!string.IsNullOrWhiteSpace(
                    student.ProfilePicturePath))
            {
                var oldFilePath = Path.Combine(
                    _environment.ContentRootPath,
                    student.ProfilePicturePath
                        .TrimStart('/')
                        .Replace(
                            '/',
                            Path.DirectorySeparatorChar));

                if (System.IO.File.Exists(oldFilePath))
                {
                    System.IO.File.Delete(oldFilePath);
                }
            }

            var uniqueFileName =
                $"{Guid.NewGuid()}{extension}";

            var filePath = Path.Combine(
                uploadsFolder,
                uniqueFileName);

            await using (var stream =
                new FileStream(
                    filePath,
                    FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            student.ProfilePictureFileName =
                file.FileName;

            student.ProfilePicturePath =
                $"/uploads/profile-pictures/{uniqueFileName}";

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message =
                    "Profile picture uploaded successfully.",

                fileName =
                    student.ProfilePictureFileName,

                filePath =
                    student.ProfilePicturePath
            });
        }

        // ============================================================
        // MAP STUDENT RESPONSE
        // ============================================================

        private object MapStudentResponse(Student student)
        {
            return new
            {
                id = student.Id,
                name = student.Name,
                email = student.Email,
                phone = student.Phone,
                isActive = student.IsActive,
                organizationId = student.OrganizationId,

                profilePictureFileName =
                    student.ProfilePictureFileName,

                profilePicturePath =
                    student.ProfilePicturePath,

                // Temporary compatibility
                courseId = student.CourseId,

                // Old single-course response
                course = student.Course == null
                    ? null
                    : new
                    {
                        id = student.Course.Id,
                        name = student.Course.Name
                    },

                // New multiple-course response
                courses = student.StudentCourses
                    .Select(sc => new
                    {
                        id = sc.CourseId,
                        name = sc.Course != null
                            ? sc.Course.Name
                            : string.Empty
                    })
                    .ToList()
            };
        }

        // ============================================================
        // GET ORGANIZATION ID FROM JWT
        // ============================================================

        private int? GetOrganizationId()
        {
            var organizationIdClaim =
                User.FindFirst("OrganizationId")?.Value;

            if (string.IsNullOrWhiteSpace(organizationIdClaim))
            {
                return null;
            }

            if (!int.TryParse(
                    organizationIdClaim,
                    out var organizationId))
            {
                return null;
            }

            return organizationId;
        }
    }
}