namespace StudentManagement.API.Models
{
    public class Organization
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // ============================================================
        // ORGANIZATION CREATOR
        // ============================================================

        // User account that originally created this organization.
        // Nullable so existing organizations are not broken.
        public int? CreatedByUserId { get; set; }

        // Snapshot of creator information.
        // This remains available even if the creator account is deleted.
        public string? CreatedByName { get; set; }

        public string? CreatedByEmail { get; set; }

        // ============================================================
        // USERS
        // ============================================================

        public ICollection<User> Users { get; set; } = new List<User>();

        // ============================================================
        // STUDENTS
        // ============================================================

        public ICollection<Student> Students { get; set; } =
            new List<Student>();

        // ============================================================
        // COURSES
        // ============================================================

        public ICollection<Course> Courses { get; set; } =
            new List<Course>();
    }
}