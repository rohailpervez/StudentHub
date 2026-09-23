namespace StudentManagement.API.Models
{
    public class Student
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        public string? ProfilePictureFileName { get; set; }

        public string? ProfilePicturePath { get; set; }

        // ============================================================
        // OLD COURSE RELATIONSHIP
        // ============================================================
        // Temporary compatibility field.
        // Isko abhi remove nahi kar rahe taake existing data/functionality
        // break na ho.
        public int? CourseId { get; set; }

        public Course? Course { get; set; }

        // ============================================================
        // NEW MULTIPLE COURSES RELATIONSHIP
        // ============================================================

        public ICollection<StudentCourse> StudentCourses { get; set; }
            = new List<StudentCourse>();

        // ============================================================
        // ORGANIZATION RELATIONSHIP
        // ============================================================

        public int OrganizationId { get; set; }

        public Organization? Organization { get; set; }
        // ============================================================
        // USER / LOGIN ACCOUNT RELATIONSHIP
        // ============================================================

        public int? UserId { get; set; }

        public User? User { get; set; }
    }
}