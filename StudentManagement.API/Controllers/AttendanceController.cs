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
    public class AttendanceController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AttendanceController(AppDbContext context)
        {
            _context = context;
        }

        // ============================================================
        // GET: api/Attendance
        // Get attendance of logged-in organization
        // ============================================================

        [HttpGet]
        public async Task<IActionResult> GetAttendance()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            var attendance = await _context.Attendances
                .Where(a =>
                    a.OrganizationId == organizationId.Value)
                .Include(a => a.Student)
                .Include(a => a.Course)
                .OrderByDescending(a => a.Date)
                .ThenBy(a => a.StudentId)
                .ToListAsync();

            return Ok(attendance);
        }

        // ============================================================
        // GET: api/Attendance/1
        // ============================================================

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetAttendanceById(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            var attendance = await _context.Attendances
                .Where(a =>
                    a.Id == id &&
                    a.OrganizationId == organizationId.Value)
                .Include(a => a.Student)
                .Include(a => a.Course)
                .FirstOrDefaultAsync();

            if (attendance == null)
            {
                return NotFound(
                    "Attendance record not found."
                );
            }

            return Ok(attendance);
        }

        // ============================================================
        // GET: api/Attendance/my
        // Get attendance of the logged-in student only
        // ============================================================

        [HttpGet("my")]
        public async Task<IActionResult> GetMyAttendance()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            // --------------------------------------------------------
            // Get logged-in User ID from JWT
            // --------------------------------------------------------

            var userIdClaim = User.FindFirst(
                System.Security.Claims.ClaimTypes.NameIdentifier
            )?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized(
                    "User information is missing."
                );
            }

            // --------------------------------------------------------
            // Find student linked with logged-in user
            // --------------------------------------------------------

            var student = await _context.Students
                .Where(s =>
                    s.UserId == userId &&
                    s.OrganizationId == organizationId.Value)
                .FirstOrDefaultAsync();

            if (student == null)
            {
                return NotFound(
                    "Student profile not found."
                );
            }

            // --------------------------------------------------------
            // Get only this student's attendance
            // Organization isolation is also enforced
            // --------------------------------------------------------

            var attendance = await _context.Attendances
                .Where(a =>
                    a.StudentId == student.Id &&
                    a.OrganizationId == organizationId.Value)
                .Include(a => a.Course)
                .OrderByDescending(a => a.Date)
                .ToListAsync();

            // --------------------------------------------------------
            // Calculate attendance summary
            // --------------------------------------------------------

            var totalClasses = attendance.Count;

            var presentClasses = attendance.Count(
                a => a.IsPresent
            );

            var absentClasses = totalClasses - presentClasses;

            var percentage = totalClasses == 0
                ? 0
                : Math.Round(
                    (double)presentClasses / totalClasses * 100,
                    1
                );

            return Ok(new
            {
                totalClasses,
                presentClasses,
                absentClasses,
                attendancePercentage = percentage,

                records = attendance.Select(a => new
                {
                    id = a.Id,
                    courseId = a.CourseId,
                    courseName = a.Course?.Name ?? "Unknown Course",
                    date = a.Date,
                    isPresent = a.IsPresent
                })
            });
        }

        // ============================================================
        // GET: api/Attendance/my/course/{courseId}
        // Get attendance of logged-in student for one course only
        // ============================================================

        [HttpGet("my/course/{courseId:int}")]
        public async Task<IActionResult> GetMyCourseAttendance(
            int courseId)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            // --------------------------------------------------------
            // Get logged-in User ID from JWT
            // --------------------------------------------------------

            var userIdClaim = User.FindFirst(
                System.Security.Claims.ClaimTypes.NameIdentifier
            )?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
            {
                return Unauthorized(
                    "User information is missing."
                );
            }

            // --------------------------------------------------------
            // Find logged-in student's profile
            // --------------------------------------------------------

            var student = await _context.Students
                .Where(s =>
                    s.UserId == userId &&
                    s.OrganizationId == organizationId.Value)
                .FirstOrDefaultAsync();

            if (student == null)
            {
                return NotFound(
                    "Student profile not found."
                );
            }

            // --------------------------------------------------------
            // Verify selected course belongs to organization
            // --------------------------------------------------------

            var course = await _context.Courses
                .Where(c =>
                    c.Id == courseId &&
                    c.OrganizationId == organizationId.Value)
                .FirstOrDefaultAsync();

            if (course == null)
            {
                return NotFound(
                    "Course not found."
                );
            }

            // --------------------------------------------------------
            // Make sure logged-in student is enrolled
            // in the selected course
            // --------------------------------------------------------

            var studentBelongsToCourse =
                await _context.StudentCourses
                    .AnyAsync(sc =>
                        sc.StudentId == student.Id &&
                        sc.CourseId == courseId);

            if (!studentBelongsToCourse)
            {
                return BadRequest(
                    "You are not enrolled in this course."
                );
            }

            // --------------------------------------------------------
            // Get only this student's attendance
            // for the selected course
            // --------------------------------------------------------

            var attendance = await _context.Attendances
                .Where(a =>
                    a.StudentId == student.Id &&
                    a.CourseId == courseId &&
                    a.OrganizationId == organizationId.Value)
                .OrderByDescending(a => a.Date)
                .ToListAsync();

            // --------------------------------------------------------
            // Calculate course-wise attendance summary
            // --------------------------------------------------------

            var totalClasses = attendance.Count;

            var presentClasses = attendance.Count(
                a => a.IsPresent
            );

            var absentClasses = totalClasses - presentClasses;

            var percentage = totalClasses == 0
                ? 0
                : Math.Round(
                    (double)presentClasses / totalClasses * 100,
                    1
                );

            // --------------------------------------------------------
            // Return course-wise attendance
            // --------------------------------------------------------

            return Ok(new
            {
                courseId = course.Id,
                courseName = course.Name,

                totalClasses,
                presentClasses,
                absentClasses,
                attendancePercentage = percentage,

                records = attendance.Select(a => new
                {
                    id = a.Id,
                    date = a.Date,
                    isPresent = a.IsPresent
                })
            });
        }

        // ============================================================
        // GET:
        // api/Attendance/date/2026-08-31
        //
        // Get attendance for a specific date
        // ============================================================

        [HttpGet("date/{date}")]
        public async Task<IActionResult> GetAttendanceByDate(
            DateTime date)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            // Make date UTC
            var selectedDate = DateTime.SpecifyKind(
                date.Date,
                DateTimeKind.Utc
            );

            var nextDate = selectedDate.AddDays(1);

            var attendance = await _context.Attendances
                .Where(a =>
                    a.OrganizationId == organizationId.Value &&
                    a.Date >= selectedDate &&
                    a.Date < nextDate)
                .Include(a => a.Student)
                .Include(a => a.Course)
                .OrderBy(a => a.StudentId)
                .ToListAsync();

            return Ok(attendance);
        }

        // ============================================================
        // POST: api/Attendance
        // Mark attendance
        // ============================================================

        [HttpPost]
        public async Task<IActionResult> MarkAttendance(
            AttendanceRequest request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            // --------------------------------------------------------
            // Verify student belongs to logged-in organization
            // --------------------------------------------------------

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == request.StudentId &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return BadRequest(
                    "Selected student not found."
                );
            }

            // --------------------------------------------------------
            // Verify course belongs to logged-in organization
            // --------------------------------------------------------

            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == request.CourseId &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return BadRequest(
                    "Selected course not found."
                );
            }

            // --------------------------------------------------------
            // Make sure student belongs to selected course
            // --------------------------------------------------------

            var studentBelongsToCourse =
                await _context.StudentCourses
                    .AnyAsync(sc =>
                        sc.StudentId == request.StudentId &&
                        sc.CourseId == request.CourseId);

            if (!studentBelongsToCourse)
            {
                return BadRequest(
                    "Selected student does not belong to this course."
                );
            }

            // --------------------------------------------------------
            // Convert attendance date to UTC
            // --------------------------------------------------------

            var selectedDate = DateTime.SpecifyKind(
                request.Date.Date,
                DateTimeKind.Utc
            );

            // --------------------------------------------------------
            // Prevent duplicate attendance
            // Same student + same course + same date
            // --------------------------------------------------------

            var existingAttendance =
                await _context.Attendances
                    .FirstOrDefaultAsync(a =>
                        a.StudentId == request.StudentId &&
                        a.CourseId == request.CourseId &&
                        a.OrganizationId == organizationId.Value &&
                        a.Date >= selectedDate &&
                        a.Date < selectedDate.AddDays(1));

            if (existingAttendance != null)
            {
                return Conflict(
                    "Attendance for this student and date already exists."
                );
            }

            // --------------------------------------------------------
            // Create Attendance entity
            // --------------------------------------------------------

            var attendance = new Attendance
            {
                StudentId = request.StudentId,
                CourseId = request.CourseId,
                OrganizationId = organizationId.Value,
                Date = selectedDate,
                IsPresent = request.IsPresent
            };

            _context.Attendances.Add(attendance);

            await _context.SaveChangesAsync();

// --------------------------------------------------------
// CREATE NOTIFICATION FOR STUDENT
// --------------------------------------------------------

if (student.UserId.HasValue)
{
    var notification = new Notification
    {
        UserId = student.UserId.Value,
        OrganizationId = organizationId.Value,
        Title = "Attendance Marked",
        Message =
            $"Your attendance for \"{course.Name}\" on {selectedDate:dd MMM yyyy} has been marked as {(attendance.IsPresent ? "Present" : "Absent")}.",
        Type = "Attendance",
        IsRead = false,
        CreatedAt = DateTime.UtcNow,
        RelatedId = attendance.CourseId
    };

    _context.Notifications.Add(notification);

    await _context.SaveChangesAsync();
}

            // --------------------------------------------------------
            // Load navigation properties for response
            // --------------------------------------------------------

            await _context.Entry(attendance)
                .Reference(a => a.Student)
                .LoadAsync();

            await _context.Entry(attendance)
                .Reference(a => a.Course)
                .LoadAsync();

            return CreatedAtAction(
                nameof(GetAttendanceById),
                new { id = attendance.Id },
                attendance
            );
        }

        // ============================================================
        // PUT: api/Attendance/1
        // Update attendance
        // ============================================================

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAttendance(
            int id,
            AttendanceRequest request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            var existingAttendance =
                await _context.Attendances
                    .FirstOrDefaultAsync(a =>
                        a.Id == id &&
                        a.OrganizationId == organizationId.Value);

            if (existingAttendance == null)
            {
                return NotFound(
                    "Attendance record not found."
                );
            }

            // --------------------------------------------------------
            // Verify student
            // --------------------------------------------------------

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == request.StudentId &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return BadRequest(
                    "Selected student not found."
                );
            }

            // --------------------------------------------------------
            // Verify course
            // --------------------------------------------------------

            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == request.CourseId &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return BadRequest(
                    "Selected course not found."
                );
            }

            // --------------------------------------------------------
            // Make sure student belongs to selected course
            // --------------------------------------------------------

            var studentBelongsToCourse =
                await _context.StudentCourses
                    .AnyAsync(sc =>
                        sc.StudentId == request.StudentId &&
                        sc.CourseId == request.CourseId);

            if (!studentBelongsToCourse)
            {
                return BadRequest(
                    "Selected student does not belong to this course."
                );
            }

            // --------------------------------------------------------
            // Convert date to UTC
            // --------------------------------------------------------

            var selectedDate = DateTime.SpecifyKind(
                request.Date.Date,
                DateTimeKind.Utc
            );

            // --------------------------------------------------------
            // Check duplicate attendance
            // --------------------------------------------------------

            var duplicate = await _context.Attendances
                .FirstOrDefaultAsync(a =>
                    a.Id != id &&
                    a.StudentId == request.StudentId &&
                    a.CourseId == request.CourseId &&
                    a.OrganizationId == organizationId.Value &&
                    a.Date >= selectedDate &&
                    a.Date < selectedDate.AddDays(1));

            if (duplicate != null)
            {
                return Conflict(
                    "Attendance for this student and date already exists."
                );
            }

            // --------------------------------------------------------
            // Update attendance
            // --------------------------------------------------------

            existingAttendance.StudentId =
                request.StudentId;

            existingAttendance.CourseId =
                request.CourseId;

            existingAttendance.Date =
                selectedDate;

            existingAttendance.IsPresent =
                request.IsPresent;

            // Always use OrganizationId from JWT
            existingAttendance.OrganizationId =
                organizationId.Value;

            await _context.SaveChangesAsync();

            // --------------------------------------------------------
            // Load navigation properties for response
            // --------------------------------------------------------

            await _context.Entry(existingAttendance)
                .Reference(a => a.Student)
                .LoadAsync();

            await _context.Entry(existingAttendance)
                .Reference(a => a.Course)
                .LoadAsync();

            return Ok(existingAttendance);
        }

        // ============================================================
        // DELETE: api/Attendance/1
        // ============================================================

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAttendance(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing."
                );
            }

            var attendance =
                await _context.Attendances
                    .FirstOrDefaultAsync(a =>
                        a.Id == id &&
                        a.OrganizationId == organizationId.Value);

            if (attendance == null)
            {
                return NotFound(
                    "Attendance record not found."
                );
            }

            _context.Attendances.Remove(attendance);

            await _context.SaveChangesAsync();

            return Ok(
                "Attendance deleted successfully."
            );
        }

        // ============================================================
        // GET ORGANIZATION ID FROM JWT
        // ============================================================

        private int? GetOrganizationId()
        {
            var organizationClaim =
                User.FindFirst("OrganizationId");

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