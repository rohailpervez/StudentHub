namespace StudentManagement.API.Models
{
    public class Course
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public int DurationMonths { get; set; }

        public bool IsActive { get; set; } = true;

        // ============================================================
        // ORGANIZATION RELATIONSHIP
        // ============================================================

        public int OrganizationId { get; set; }

        public Organization? Organization { get; set; }

        // ============================================================
        // NEW MULTIPLE STUDENTS RELATIONSHIP
        // ============================================================

        public ICollection<StudentCourse> StudentCourses { get; set; }
            = new List<StudentCourse>();
    }
}