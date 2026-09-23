namespace StudentManagement.API.DTOs
{
    public class StudentAssignmentResponseDto
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public DateTime DueDate { get; set; }

        public bool IsActive { get; set; }

        public DateTime CreatedAt { get; set; }

        public int CourseId { get; set; }

        public string CourseName { get; set; } = string.Empty;

        public int CreatedByUserId { get; set; }

        public string CreatedByUserName { get; set; } = string.Empty;
        public string? AttachmentFileName { get; set; }

        public string? AttachmentFilePath { get; set; }

        public StudentAssignmentSubmissionDto? Submission { get; set; }
    }

    public class StudentAssignmentSubmissionDto
    {
        public int Id { get; set; }

        public DateTime SubmittedAt { get; set; }

        public string FileName { get; set; } = string.Empty;

        public string FilePath { get; set; } = string.Empty;

        public string Status { get; set; } = string.Empty;

        public decimal? Grade { get; set; }

        public string Feedback { get; set; } = string.Empty;
    }
}