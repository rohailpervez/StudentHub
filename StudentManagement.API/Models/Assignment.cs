namespace StudentManagement.API.Models
{
    public class Assignment
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public DateTime DueDate { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Organization
        public int OrganizationId { get; set; }
        public Organization? Organization { get; set; }

        // Course / Subject
        public int CourseId { get; set; }
        public Course? Course { get; set; }

        // User who created the assignment
        public int CreatedByUserId { get; set; }
        public User? CreatedByUser { get; set; }
        // Assignment attachment
        public string AttachmentFileName { get; set; } = string.Empty;
        public string AttachmentFilePath { get; set; } = string.Empty;

        // Student submissions
        public ICollection<AssignmentSubmission> Submissions { get; set; }
            = new List<AssignmentSubmission>();
    }
}