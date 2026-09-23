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
    [Route("api/StudentAssignments")]
    [Authorize(Roles = "User")]
    public class StudentAssignmentsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public StudentAssignmentsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/StudentAssignments/my
        [HttpGet("my")]
        public async Task<ActionResult<IEnumerable<StudentAssignmentResponseDto>>> GetMyAssignments()
        {
            var organizationId = GetOrganizationId();
            var userId = GetCurrentUserId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            if (userId == null)
            {
                return Unauthorized("User information is missing.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.UserId == userId.Value &&
                    s.OrganizationId == organizationId.Value &&
                    s.IsActive);

            if (student == null)
            {
                return NotFound("Student profile not found.");
            }

            var assignments = await _context.Assignments
                .Where(a =>
                    a.OrganizationId == organizationId.Value &&
                    a.IsActive &&
                    _context.StudentCourses.Any(sc =>
                        sc.StudentId == student.Id &&
                        sc.CourseId == a.CourseId))
                .Include(a => a.Course)
                .Include(a => a.CreatedByUser)
                .OrderBy(a => a.DueDate)
                .Select(a => new StudentAssignmentResponseDto
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
                        : string.Empty,
                AttachmentFileName = a.AttachmentFileName,
                AttachmentFilePath = a.AttachmentFilePath,
                    Submission = _context.AssignmentSubmissions
                        .Where(s =>
                            s.AssignmentId == a.Id &&
                            s.StudentId == student.Id)
                        .Select(s => new StudentAssignmentSubmissionDto
                        {
                            Id = s.Id,
                            SubmittedAt = s.SubmittedAt,
                            FileName = s.FileName,
                            FilePath = s.FilePath,
                            Status = s.Status,
                            Grade = s.Grade,
                            Feedback = s.Feedback
                        })
                        .FirstOrDefault()
                })
                .ToListAsync();

            return Ok(assignments);
        }

        // GET: api/StudentAssignments/my/{id}
        [HttpGet("my/{id}")]
        public async Task<ActionResult<StudentAssignmentResponseDto>> GetMyAssignment(int id)
        {
            var organizationId = GetOrganizationId();
            var userId = GetCurrentUserId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            if (userId == null)
            {
                return Unauthorized("User information is missing.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.UserId == userId.Value &&
                    s.OrganizationId == organizationId.Value &&
                    s.IsActive);

            if (student == null)
            {
                return NotFound("Student profile not found.");
            }

            var assignment = await _context.Assignments
                .Where(a =>
                    a.Id == id &&
                    a.OrganizationId == organizationId.Value &&
                    a.IsActive &&
                    _context.StudentCourses.Any(sc =>
                        sc.StudentId == student.Id &&
                        sc.CourseId == a.CourseId))
                .Include(a => a.Course)
                .Include(a => a.CreatedByUser)
                .Select(a => new StudentAssignmentResponseDto
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
                        : string.Empty,
                     AttachmentFileName = a.AttachmentFileName,
                     AttachmentFilePath = a.AttachmentFilePath,
                    Submission = _context.AssignmentSubmissions
                        .Where(s =>
                            s.AssignmentId == a.Id &&
                            s.StudentId == student.Id)
                        .Select(s => new StudentAssignmentSubmissionDto
                        {
                            Id = s.Id,
                            SubmittedAt = s.SubmittedAt,
                            FileName = s.FileName,
                            FilePath = s.FilePath,
                            Status = s.Status,
                            Grade = s.Grade,
                            Feedback = s.Feedback
                        })
                        .FirstOrDefault()
                })
                .FirstOrDefaultAsync();

            if (assignment == null)
            {
                return NotFound("Assignment not found.");
            }

            return Ok(assignment);
        }

// POST: api/StudentAssignments/my/{id}/upload
[HttpPost("my/{id}/upload")]
[RequestSizeLimit(10 * 1024 * 1024)]
public async Task<ActionResult> UploadAssignmentPdf(
    int id,
    IFormFile file)
{
    var organizationId = GetOrganizationId();
    var userId = GetCurrentUserId();

    if (organizationId == null)
    {
        return Unauthorized("Organization information is missing.");
    }

    if (userId == null)
    {
        return Unauthorized("User information is missing.");
    }

    if (file == null || file.Length == 0)
    {
        return BadRequest("Please select a PDF file.");
    }

    // Maximum file size: 10 MB
    if (file.Length > 10 * 1024 * 1024)
    {
        return BadRequest("PDF file size cannot exceed 10 MB.");
    }

    // Only .pdf extension is allowed
    var extension = Path.GetExtension(file.FileName);

    if (!string.Equals(
            extension,
            ".pdf",
            StringComparison.OrdinalIgnoreCase))
    {
        return BadRequest("Only PDF files are allowed.");
    }



    // Verify PDF file signature: %PDF-
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
        return BadRequest("The selected file is not a valid PDF.");
    }

    var student = await _context.Students
        .FirstOrDefaultAsync(s =>
            s.UserId == userId.Value &&
            s.OrganizationId == organizationId.Value &&
            s.IsActive);

    if (student == null)
    {
        return NotFound("Student profile not found.");
    }

    var assignment = await _context.Assignments
        .FirstOrDefaultAsync(a =>
            a.Id == id &&
            a.OrganizationId == organizationId.Value &&
            a.IsActive &&
            _context.StudentCourses.Any(sc =>
                sc.StudentId == student.Id &&
                sc.CourseId == a.CourseId));

    if (assignment == null)
    {
        return NotFound("Assignment not found.");
    }

    var existingSubmission = await _context.AssignmentSubmissions
        .FirstOrDefaultAsync(s =>
            s.AssignmentId == assignment.Id &&
            s.StudentId == student.Id);

    if (existingSubmission != null)
    {
        return Conflict(
            "You have already submitted this assignment.");
    }

    var uploadFolder = Path.Combine(
        Directory.GetCurrentDirectory(),
        "wwwroot",
        "uploads",
        "assignments");

    Directory.CreateDirectory(uploadFolder);

    // Generate a safe unique filename.
    var storedFileName =
        $"{Guid.NewGuid():N}.pdf";

    var physicalFilePath = Path.Combine(
        uploadFolder,
        storedFileName);

    await System.IO.File.WriteAllBytesAsync(
        physicalFilePath,
        fileBytes);

    var relativeFilePath =
        $"uploads/assignments/{storedFileName}";

    return Ok(new
    {
        message = "PDF uploaded successfully.",
        fileName = file.FileName,
        filePath = relativeFilePath,
        fileSize = file.Length,
        contentType = file.ContentType
    });
}

        // POST: api/StudentAssignments/my/{id}/submit
        [HttpPost("my/{id}/submit")]
        public async Task<ActionResult> SubmitAssignment(
            int id,
            [FromBody] AssignmentSubmissionCreateDto request)
        {
            var organizationId = GetOrganizationId();
            var userId = GetCurrentUserId();

            if (organizationId == null)
            {
                return Unauthorized("Organization information is missing.");
            }

            if (userId == null)
            {
                return Unauthorized("User information is missing.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.UserId == userId.Value &&
                    s.OrganizationId == organizationId.Value &&
                    s.IsActive);

            if (student == null)
            {
                return NotFound("Student profile not found.");
            }

            var assignment = await _context.Assignments
                .FirstOrDefaultAsync(a =>
                    a.Id == id &&
                    a.OrganizationId == organizationId.Value &&
                    a.IsActive &&
                    _context.StudentCourses.Any(sc =>
                        sc.StudentId == student.Id &&
                        sc.CourseId == a.CourseId));

            if (assignment == null)
            {
                return NotFound("Assignment not found.");
            }

            var existingSubmission = await _context.AssignmentSubmissions
                .FirstOrDefaultAsync(s =>
                    s.AssignmentId == assignment.Id &&
                    s.StudentId == student.Id);

            if (existingSubmission != null)
            {
                return Conflict("You have already submitted this assignment.");
            }

            var submission = new AssignmentSubmission
            {
                AssignmentId = assignment.Id,
                StudentId = student.Id,
                SubmittedAt = DateTime.UtcNow,
                FileName = request.FileName,
                FilePath = request.FilePath,
                Status = "Submitted"
            };

           _context.AssignmentSubmissions.Add(submission);

           await _context.SaveChangesAsync();

           // ============================================================
           // CREATE NOTIFICATION FOR ASSIGNMENT CREATOR
           // ============================================================

           var assignmentCreator = await _context.Users
               .FirstOrDefaultAsync(u =>
                   u.Id == assignment.CreatedByUserId &&
                   u.OrganizationId == organizationId.Value &&
                   (u.Role == "Teacher" || u.Role == "Staff"));

           if (assignmentCreator != null)
           {
               var notification = new Notification
               {
                   UserId = assignmentCreator.Id,
                   OrganizationId = organizationId.Value,
                   Title = "New Assignment Submission",
                   Message =
                       $"{student.Name} has submitted the assignment \"{assignment.Title}\".",
                   Type = "Submission",
                   IsRead = false,
                   CreatedAt = DateTime.UtcNow,
                   RelatedId = assignment.Id
               };

               _context.Notifications.Add(notification);

               await _context.SaveChangesAsync();
           }

           return Ok(new
           {
                message = "Assignment submitted successfully.",
                submissionId = submission.Id,
                assignmentId = submission.AssignmentId,
                studentId = submission.StudentId,
                submittedAt = submission.SubmittedAt,
                fileName = submission.FileName,
                filePath = submission.FilePath,
                status = submission.Status
            });
        }

// ============================================================
// GET: api/StudentAssignments/my/{id}/attachment
//
// Student can view the PDF attached by Teacher/Staff/Admin.
// Existing student submission PDF system is NOT changed.
// ============================================================

[HttpGet("my/{id}/attachment")]
public async Task<IActionResult> ViewAssignmentAttachment(int id)
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
    // FIND ACTIVE STUDENT IN SAME ORGANIZATION
    // ========================================================

    var student = await _context.Students
        .FirstOrDefaultAsync(s =>
            s.UserId == userId.Value &&
            s.OrganizationId == organizationId.Value &&
            s.IsActive);

    if (student == null)
    {
        return NotFound(
            "Student profile not found.");
    }

    // ========================================================
    // FIND ASSIGNMENT
    //
    // Student can only access:
    // - active assignment
    // - same organization
    // - course in which student is enrolled
    // ========================================================

    var assignment = await _context.Assignments
        .FirstOrDefaultAsync(a =>
            a.Id == id &&
            a.OrganizationId == organizationId.Value &&
            a.IsActive &&
            _context.StudentCourses.Any(sc =>
                sc.StudentId == student.Id &&
                sc.CourseId == a.CourseId));

    if (assignment == null)
    {
        return NotFound(
            "Assignment not found.");
    }

    // ========================================================
    // CHECK ATTACHMENT
    // ========================================================

    if (string.IsNullOrWhiteSpace(
            assignment.AttachmentFilePath))
    {
        return NotFound(
            "Assignment PDF attachment was not found.");
    }

    // ========================================================
    // GET SAFE FILE NAME
    // ========================================================

    var fileName = Path.GetFileName(
        assignment.AttachmentFilePath);

    if (string.IsNullOrWhiteSpace(fileName))
    {
        return BadRequest(
            "Invalid assignment PDF file path.");
    }

    // ========================================================
    // PHYSICAL UPLOAD FOLDER
    // ========================================================

    var uploadFolder = Path.Combine(
        Directory.GetCurrentDirectory(),
        "wwwroot",
        "uploads",
        "assignments");

    var physicalFilePath = Path.Combine(
        uploadFolder,
        fileName);

    // ========================================================
    // CHECK FILE EXISTS
    // ========================================================

    if (!System.IO.File.Exists(physicalFilePath))
    {
        return NotFound(
            "Assignment PDF file was not found.");
    }

    // ========================================================
    // RETURN PDF
    // ========================================================

    var fileBytes =
        await System.IO.File.ReadAllBytesAsync(
            physicalFilePath);

    return File(
        fileBytes,
        "application/pdf",
        enableRangeProcessing: true);
}

        private int? GetOrganizationId()
        {
            var claim = User.FindFirst("OrganizationId");

            if (claim == null)
            {
                return null;
            }

            if (int.TryParse(claim.Value, out var organizationId))
            {
                return organizationId;
            }

            return null;
        }

        private int? GetCurrentUserId()
        {
            var claim = User.FindFirst(
                ClaimTypes.NameIdentifier);

            if (claim == null)
            {
                return null;
            }

            if (int.TryParse(claim.Value, out var userId))
            {
                return userId;
            }

            return null;
        }
    }
}