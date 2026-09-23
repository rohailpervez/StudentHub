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
    [Authorize]
    public class AcademicGradesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AcademicGradesController(AppDbContext context)
        {
            _context = context;
        }


        // GET: api/AcademicGrades
        // TEACHER / STAFF / ADMIN


        [HttpGet]
        [Authorize(Roles = "Admin,Teacher,Staff")]
        public async Task<ActionResult> GetAcademicGrades()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var grades = await _context.AcademicGrades
                .Where(g =>
                    g.OrganizationId == organizationId.Value &&
                    g.Student != null &&
                    g.Student.OrganizationId ==
                        organizationId.Value &&
                    g.Course != null &&
                    g.Course.OrganizationId ==
                        organizationId.Value)
                .Include(g => g.Student)
                .Include(g => g.Course)
                .OrderBy(g => g.Course!.Name)
                .ThenBy(g => g.Student!.Name)
                .Select(g => new AcademicGradeDto
                {
                    Id = g.Id,

                    StudentId = g.StudentId,

                    StudentName = g.Student != null
                        ? g.Student.Name
                        : string.Empty,

                    StudentEmail = g.Student != null
                        ? g.Student.Email
                        : string.Empty,

                    CourseId = g.CourseId,

                    CourseName = g.Course != null
                        ? g.Course.Name
                        : string.Empty,

                    OrganizationId = g.OrganizationId,

                    MidTermGrade = g.MidTermGrade,

                    FinalGrade = g.FinalGrade,

                    CreatedAt = g.CreatedAt,

                    UpdatedAt = g.UpdatedAt
                })
                .ToListAsync();

            return Ok(grades);
        }


        // GET: api/AcademicGrades/my
        // STUDENT


        [HttpGet("my")]
        [Authorize(Roles = "User")]
        public async Task<ActionResult> GetMyAcademicGrades()
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var userId = GetUserId();

            if (userId == null)
            {
                return Unauthorized(
                    "User information is missing.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.UserId == userId.Value &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return NotFound(
                    "Student profile not found.");
            }

            var grades = await _context.AcademicGrades
                .Where(g =>
                    g.StudentId == student.Id &&
                    g.OrganizationId == organizationId.Value &&
                    g.Student != null &&
                    g.Student.OrganizationId ==
                        organizationId.Value &&
                    g.Course != null &&
                    g.Course.OrganizationId ==
                        organizationId.Value)
                .Include(g => g.Course)
                .OrderBy(g => g.Course!.Name)
                .Select(g => new AcademicGradeDto
                {
                    Id = g.Id,

                    StudentId = g.StudentId,

                    StudentName = student.Name,

                    StudentEmail = student.Email,

                    CourseId = g.CourseId,

                    CourseName = g.Course != null
                        ? g.Course.Name
                        : string.Empty,

                    OrganizationId = g.OrganizationId,

                    MidTermGrade = g.MidTermGrade,

                    FinalGrade = g.FinalGrade,

                    CreatedAt = g.CreatedAt,

                    UpdatedAt = g.UpdatedAt
                })
                .ToListAsync();

            return Ok(grades);
        }


        // POST: api/AcademicGrades
        // TEACHER / STAFF / ADMIN


        [HttpPost]
        [Authorize(Roles = "Admin,Teacher,Staff")]
        public async Task<ActionResult> CreateAcademicGrade(
            [FromBody] AcademicGradeUpsertDto request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var validationError =
                ValidateGrades(request);

            if (validationError != null)
            {
                return BadRequest(validationError);
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == request.StudentId &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return NotFound(
                    "Student not found in your organization.");
            }

            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == request.CourseId &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return NotFound(
                    "Course not found in your organization.");
            }

            // Make sure the student is actually enrolled
            // in this course.
            var enrolled = await _context.StudentCourses
                .AnyAsync(sc =>
                    sc.StudentId == request.StudentId &&
                    sc.CourseId == request.CourseId);

            if (!enrolled)
            {
                return BadRequest(
                    "This student is not enrolled in the selected course.");
            }

            var existingGrade =
                await _context.AcademicGrades
                    .FirstOrDefaultAsync(g =>
                        g.StudentId == request.StudentId &&
                        g.CourseId == request.CourseId &&
                        g.OrganizationId == organizationId.Value);

            if (existingGrade != null)
            {
                return Conflict(
                    "Academic grade already exists for this student and course.");
            }

            var grade = new AcademicGrade
            {
                StudentId = request.StudentId,
                CourseId = request.CourseId,
                OrganizationId = organizationId.Value,

                MidTermGrade = request.MidTermGrade,
                FinalGrade = request.FinalGrade,

                CreatedAt = DateTime.UtcNow
            };

            _context.AcademicGrades.Add(grade);

            await _context.SaveChangesAsync();


            // CREATE NOTIFICATION FOR STUDENT


            if (student.UserId.HasValue)
            {
                var notification = new Notification
                {
                    UserId = student.UserId.Value,
                    OrganizationId = organizationId.Value,
                    Title = "Academic Grade Added",
                    Message =
                        $"Your academic grade for \"{course.Name}\" has been added.",
                    Type = "Grade",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow,
                    RelatedId = grade.Id
                };

                _context.Notifications.Add(notification);

                await _context.SaveChangesAsync();
            }

            return Ok(new
            {
                message = "Academic grade created successfully.",

                gradeId = grade.Id,

                studentId = grade.StudentId,

                courseId = grade.CourseId,

                midTermGrade = grade.MidTermGrade,

                finalGrade = grade.FinalGrade
            });
        }


        // PUT: api/AcademicGrades/{id}
        // TEACHER / STAFF / ADMIN

        [HttpPut("{id}")]
        [Authorize(Roles = "Admin,Teacher,Staff")]
        public async Task<ActionResult> UpdateAcademicGrade(
            int id,
            [FromBody] AcademicGradeUpsertDto request)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var validationError =
                ValidateGrades(request);

            if (validationError != null)
            {
                return BadRequest(validationError);
            }

            var grade = await _context.AcademicGrades
                .FirstOrDefaultAsync(g =>
                    g.Id == id &&
                    g.OrganizationId == organizationId.Value);

            if (grade == null)
            {
                return NotFound(
                    "Academic grade not found.");
            }

            var student = await _context.Students
                .FirstOrDefaultAsync(s =>
                    s.Id == request.StudentId &&
                    s.OrganizationId == organizationId.Value);

            if (student == null)
            {
                return NotFound(
                    "Student not found in your organization.");
            }

            var course = await _context.Courses
                .FirstOrDefaultAsync(c =>
                    c.Id == request.CourseId &&
                    c.OrganizationId == organizationId.Value);

            if (course == null)
            {
                return NotFound(
                    "Course not found in your organization.");
            }

            var enrolled = await _context.StudentCourses
                .AnyAsync(sc =>
                    sc.StudentId == request.StudentId &&
                    sc.CourseId == request.CourseId);

            if (!enrolled)
            {
                return BadRequest(
                    "This student is not enrolled in the selected course.");
            }

            var duplicate = await _context.AcademicGrades
                .AnyAsync(g =>
                    g.Id != id &&
                    g.StudentId == request.StudentId &&
                    g.CourseId == request.CourseId &&
                    g.OrganizationId == organizationId.Value);

            if (duplicate)
            {
                return Conflict(
                    "Another academic grade already exists for this student and course.");
            }

            grade.StudentId = request.StudentId;
            grade.CourseId = request.CourseId;

            grade.MidTermGrade = request.MidTermGrade;
            grade.FinalGrade = request.FinalGrade;

           grade.UpdatedAt = DateTime.UtcNow;

           await _context.SaveChangesAsync();


           // CREATE NOTIFICATION FOR STUDENT


           if (student.UserId.HasValue)
           {
               var notification = new Notification
               {
                   UserId = student.UserId.Value,
                   OrganizationId = organizationId.Value,
                   Title = "Academic Grade Updated",
                   Message =
                       $"Your academic grade for \"{course.Name}\" has been updated.",
                   Type = "Grade",
                   IsRead = false,
                   CreatedAt = DateTime.UtcNow,
                   RelatedId = grade.Id
               };

               _context.Notifications.Add(notification);

               await _context.SaveChangesAsync();
           }

           return Ok(new
            {
                message = "Academic grade updated successfully.",

                gradeId = grade.Id,

                studentId = grade.StudentId,

                courseId = grade.CourseId,

                midTermGrade = grade.MidTermGrade,

                finalGrade = grade.FinalGrade
            });
        }


        // DELETE: api/AcademicGrades/{id}
        // TEACHER / STAFF / ADMIN


        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin,Teacher,Staff")]
        public async Task<ActionResult> DeleteAcademicGrade(int id)
        {
            var organizationId = GetOrganizationId();

            if (organizationId == null)
            {
                return Unauthorized(
                    "Organization information is missing.");
            }

            var grade = await _context.AcademicGrades
                .FirstOrDefaultAsync(g =>
                    g.Id == id &&
                    g.OrganizationId == organizationId.Value);

            if (grade == null)
            {
                return NotFound(
                    "Academic grade not found.");
            }

            _context.AcademicGrades.Remove(grade);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Academic grade deleted successfully.",
                gradeId = id
            });
        }


        // VALIDATE GRADES


        private string? ValidateGrades(
            AcademicGradeUpsertDto request)
        {
            if (request.MidTermGrade.HasValue &&
                (request.MidTermGrade.Value < 0 ||
                 request.MidTermGrade.Value > 100))
            {
                return "Mid-Term grade must be between 0 and 100.";
            }

            if (request.FinalGrade.HasValue &&
                (request.FinalGrade.Value < 0 ||
                 request.FinalGrade.Value > 100))
            {
                return "Final grade must be between 0 and 100.";
            }

            if (!request.MidTermGrade.HasValue &&
                !request.FinalGrade.HasValue)
            {
                return "At least one grade is required.";
            }

            return null;
        }


        // GET ORGANIZATION ID FROM JWT


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


        // GET USER ID FROM JWT


        private int? GetUserId()
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