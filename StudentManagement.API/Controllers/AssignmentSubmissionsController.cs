using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Data;
using StudentManagement.API.DTOs;
using System.Security.Claims;
using StudentManagement.API.Models;

namespace StudentManagement.API.Controllers
{
    [ApiController]
    [Route("api/AssignmentSubmissions")]
    [Authorize(Roles = "Admin,Teacher,Staff")]
    public class AssignmentSubmissionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AssignmentSubmissionsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/AssignmentSubmissions/assignment/{assignmentId}
        [HttpGet("assignment/{assignmentId}")]
        public async Task<ActionResult> GetAssignmentSubmissions(
            int assignmentId)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            // Make sure assignment belongs to the
            // logged-in user's organization.
            var assignment = await _context.Assignments
                .FirstOrDefaultAsync(a =>
                    a.Id == assignmentId &&
                    a.OrganizationId == organizationId.Value);

            if (assignment == null)
            {
                return NotFound("Assignment not found.");
            }

            var submissions = await _context.AssignmentSubmissions
                .Where(s =>
                    s.AssignmentId == assignmentId &&
                    s.Assignment != null &&
                    s.Assignment.OrganizationId ==
                        organizationId.Value &&
                    s.Student != null &&
                    s.Student.OrganizationId ==
                        organizationId.Value)
                .Include(s => s.Student)
                .Include(s => s.Assignment)
                    .ThenInclude(a => a!.Course)
                .OrderByDescending(s => s.SubmittedAt)
                .Select(s => new
                {
                    submissionId = s.Id,

                    studentId = s.StudentId,

                    studentName = s.Student != null
                        ? s.Student.Name
                        : string.Empty,

                    studentEmail = s.Student != null
                        ? s.Student.Email
                        : string.Empty,

                    assignmentId = s.AssignmentId,

                    assignmentTitle = s.Assignment != null
                        ? s.Assignment.Title
                        : string.Empty,

                    courseName = s.Assignment != null &&
                                 s.Assignment.Course != null
                        ? s.Assignment.Course.Name
                        : string.Empty,

                    submittedAt = s.SubmittedAt,

                    fileName = s.FileName,

                    filePath = s.FilePath,

                    status = s.Status,

                    grade = s.Grade,

                    feedback = s.Feedback
                })
                .ToListAsync();

            return Ok(submissions);
        }

        // PUT: api/AssignmentSubmissions/{submissionId}/review
        [HttpPut("{submissionId}/review")]
        public async Task<ActionResult> ReviewSubmission(
            int submissionId,
            [FromBody] AssignmentSubmissionReviewDto request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var submission = await _context.AssignmentSubmissions
                .Include(s => s.Assignment)
                .Include(s => s.Student)
                .FirstOrDefaultAsync(s =>
                    s.Id == submissionId &&
                    s.Assignment != null &&
                    s.Assignment.OrganizationId ==
                        organizationId.Value &&
                    s.Student != null &&
                    s.Student.OrganizationId ==
                        organizationId.Value);

            if (submission == null)
            {
                return NotFound("Submission not found.");
            }

           submission.Grade = request.Grade;
           submission.Feedback = request.Feedback;
           submission.Status = "Reviewed";

           await _context.SaveChangesAsync();

           // ============================================================
           // CREATE NOTIFICATION FOR THE STUDENT
           // ============================================================

           if (submission.Student != null &&
               submission.Student.UserId.HasValue &&
               submission.Assignment != null)
           {
               var notification = new Notification
               {
                   UserId = submission.Student.UserId.Value,
                   OrganizationId = organizationId.Value,
                   Title = "Assignment Graded",
                   Message =
                       $"Your assignment \"{submission.Assignment.Title}\" has been graded.",
                   Type = "Grade",
                   IsRead = false,
                   CreatedAt = DateTime.UtcNow,
                   RelatedId = submission.AssignmentId
               };

               _context.Notifications.Add(notification);

               await _context.SaveChangesAsync();
           }

           return Ok(new
            {
                message = "Submission reviewed successfully.",
                submissionId = submission.Id,
                studentId = submission.StudentId,
                assignmentId = submission.AssignmentId,
                grade = submission.Grade,
                feedback = submission.Feedback,
                status = submission.Status
            });
        }

// GET: api/AssignmentSubmissions/{submissionId}/pdf
[HttpGet("{submissionId}/pdf")]
public async Task<IActionResult> ViewSubmissionPdf(
    int submissionId)
{
    var organizationId = GetOrganizationId();

    if (organizationId == null)
    {
        return Unauthorized(
            "Organization information is missing.");
    }

    // Make sure the submission belongs to the
    // logged-in user's organization.
    var submission = await _context.AssignmentSubmissions
        .Include(s => s.Assignment)
        .Include(s => s.Student)
        .FirstOrDefaultAsync(s =>
            s.Id == submissionId &&
            s.Assignment != null &&
            s.Assignment.OrganizationId ==
                organizationId.Value &&
            s.Student != null &&
            s.Student.OrganizationId ==
                organizationId.Value);

    if (submission == null)
    {
        return NotFound("Submission not found.");
    }

    if (string.IsNullOrWhiteSpace(submission.FilePath))
    {
        return NotFound("Submitted PDF file was not found.");
    }

    var uploadFolder = Path.Combine(
        Directory.GetCurrentDirectory(),
        "wwwroot",
        "uploads",
        "assignments");

    var fileName = Path.GetFileName(
        submission.FilePath);

    if (string.IsNullOrWhiteSpace(fileName))
    {
        return BadRequest("Invalid PDF file path.");
    }

    var physicalFilePath = Path.Combine(
        uploadFolder,
        fileName);

    if (!System.IO.File.Exists(physicalFilePath))
    {
        return NotFound("Submitted PDF file was not found.");
    }

    var fileBytes = await System.IO.File.ReadAllBytesAsync(
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

            if (int.TryParse(
                claim.Value,
                out var organizationId))
            {
                return organizationId;
            }

            return null;
        }
    }
}