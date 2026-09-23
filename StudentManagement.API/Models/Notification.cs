namespace StudentManagement.API.Models
{
    public class Notification
    {
        public int Id { get; set; }

        // Notification kis user ke liye hai
        public int UserId { get; set; }

        public User? User { get; set; }

        // Organization isolation
        public int OrganizationId { get; set; }

        public Organization? Organization { get; set; }

        // Notification content
        public string Title { get; set; } = string.Empty;

        public string Message { get; set; } = string.Empty;

        // Examples:
        // Assignment, Grade, Attendance, Course, Submission
        public string Type { get; set; } = string.Empty;

        // Read / Unread
        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Optional ID of the related record
        // Example: AssignmentId, GradeId, CourseId
        public int? RelatedId { get; set; }
    }
}