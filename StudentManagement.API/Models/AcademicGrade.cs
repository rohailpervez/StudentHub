namespace StudentManagement.API.Models
{
    public class AcademicGrade
    {
        public int Id { get; set; }

        // ============================================================
        // STUDENT
        // ============================================================

        public int StudentId { get; set; }

        public Student? Student { get; set; }

        // ============================================================
        // COURSE
        // ============================================================

        public int CourseId { get; set; }

        public Course? Course { get; set; }

        // ============================================================
        // ORGANIZATION
        // ============================================================

        public int OrganizationId { get; set; }

        public Organization? Organization { get; set; }

        // ============================================================
        // ACADEMIC GRADES
        // ============================================================

        public decimal? MidTermGrade { get; set; }

        public decimal? FinalGrade { get; set; }

        // ============================================================
        // TIMESTAMPS
        // ============================================================

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}