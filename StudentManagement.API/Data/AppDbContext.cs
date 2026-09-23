using Microsoft.EntityFrameworkCore;
using StudentManagement.API.Models;

namespace StudentManagement.API.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<Student> Students { get; set; }
        public DbSet<Course> Courses { get; set; }
        public DbSet<StudentCourse> StudentCourses { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Organization> Organizations { get; set; }
        public DbSet<Attendance> Attendances { get; set; }
        public DbSet<Assignment> Assignments { get; set; }
        public DbSet<AssignmentSubmission> AssignmentSubmissions { get; set; }
        public DbSet<AcademicGrade> AcademicGrades { get; set; }
        public DbSet<Notification> Notifications { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ============================================================
            // STUDENT → OLD COURSE RELATIONSHIP
            // ============================================================

            modelBuilder.Entity<Student>()
                .HasOne(student => student.Course)
                .WithMany()
                .HasForeignKey(student => student.CourseId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // STUDENT ↔ COURSE
            // MANY-TO-MANY THROUGH StudentCourse
            // ============================================================

            modelBuilder.Entity<StudentCourse>()
                .HasOne(sc => sc.Student)
                .WithMany(student => student.StudentCourses)
                .HasForeignKey(sc => sc.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StudentCourse>()
                .HasOne(sc => sc.Course)
                .WithMany(course => course.StudentCourses)
                .HasForeignKey(sc => sc.CourseId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StudentCourse>()
                .HasIndex(sc => new
                {
                    sc.StudentId,
                    sc.CourseId
                })
                .IsUnique();

            // ============================================================
            // USER → ORGANIZATION
            // ============================================================

            modelBuilder.Entity<User>()
                .HasOne(user => user.Organization)
                .WithMany(organization => organization.Users)
                .HasForeignKey(user => user.OrganizationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // STUDENT → ORGANIZATION
            // ============================================================

            modelBuilder.Entity<Student>()
                .HasOne(student => student.Organization)
                .WithMany(organization => organization.Students)
                .HasForeignKey(student => student.OrganizationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // STUDENT → USER / LOGIN ACCOUNT
            // ============================================================

            modelBuilder.Entity<Student>()
                .HasOne(student => student.User)
                .WithOne()
                .HasForeignKey<Student>(student => student.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // COURSE → ORGANIZATION
            // ============================================================

            modelBuilder.Entity<Course>()
                .HasOne(course => course.Organization)
                .WithMany(organization => organization.Courses)
                .HasForeignKey(course => course.OrganizationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // UNIQUE USER EMAIL
            // ============================================================

            modelBuilder.Entity<User>()
                .HasIndex(user => user.Email)
                .IsUnique();

            // ============================================================
            // ASSIGNMENT → ORGANIZATION
            // ============================================================

            modelBuilder.Entity<Assignment>()
                .HasOne(assignment => assignment.Organization)
                .WithMany()
                .HasForeignKey(assignment => assignment.OrganizationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // ASSIGNMENT → COURSE
            // ============================================================

            modelBuilder.Entity<Assignment>()
                .HasOne(assignment => assignment.Course)
                .WithMany()
                .HasForeignKey(assignment => assignment.CourseId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // ASSIGNMENT → CREATED BY USER
            // ============================================================

            modelBuilder.Entity<Assignment>()
                .HasOne(assignment => assignment.CreatedByUser)
                .WithMany()
                .HasForeignKey(assignment => assignment.CreatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // ASSIGNMENT SUBMISSION → ASSIGNMENT
            // ============================================================

            modelBuilder.Entity<AssignmentSubmission>()
                .HasOne(submission => submission.Assignment)
                .WithMany(assignment => assignment.Submissions)
                .HasForeignKey(submission => submission.AssignmentId)
                .OnDelete(DeleteBehavior.Cascade);

            // ============================================================
            // ASSIGNMENT SUBMISSION → STUDENT
            // ============================================================

            modelBuilder.Entity<AssignmentSubmission>()
                .HasOne(submission => submission.Student)
                .WithMany()
                .HasForeignKey(submission => submission.StudentId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // PREVENT DUPLICATE SUBMISSION
            // ============================================================

            modelBuilder.Entity<AssignmentSubmission>()
                .HasIndex(submission => new
                {
                    submission.AssignmentId,
                    submission.StudentId
                })
                .IsUnique();

            // ============================================================
            // ACADEMIC GRADE → STUDENT
            // ============================================================

            modelBuilder.Entity<AcademicGrade>()
                .HasOne(grade => grade.Student)
                .WithMany()
                .HasForeignKey(grade => grade.StudentId)
                .OnDelete(DeleteBehavior.Cascade);

            // ============================================================
            // ACADEMIC GRADE → COURSE
            // ============================================================

            modelBuilder.Entity<AcademicGrade>()
                .HasOne(grade => grade.Course)
                .WithMany()
                .HasForeignKey(grade => grade.CourseId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // ACADEMIC GRADE → ORGANIZATION
            // ============================================================

            modelBuilder.Entity<AcademicGrade>()
                .HasOne(grade => grade.Organization)
                .WithMany()
                .HasForeignKey(grade => grade.OrganizationId)
                .OnDelete(DeleteBehavior.Restrict);

            // ============================================================
            // PREVENT DUPLICATE ACADEMIC GRADE
            // ============================================================

            modelBuilder.Entity<AcademicGrade>()
                .HasIndex(grade => new
                {
                    grade.StudentId,
                    grade.CourseId
                })
                .IsUnique();

                // ============================================================
                // NOTIFICATION → USER
                // ============================================================

                modelBuilder.Entity<Notification>()
                    .HasOne(notification => notification.User)
                    .WithMany()
                    .HasForeignKey(notification => notification.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                // ============================================================
                // NOTIFICATION → ORGANIZATION
                // ============================================================

                modelBuilder.Entity<Notification>()
                    .HasOne(notification => notification.Organization)
                    .WithMany()
                    .HasForeignKey(notification => notification.OrganizationId)
                    .OnDelete(DeleteBehavior.Cascade);
        }
    }
}