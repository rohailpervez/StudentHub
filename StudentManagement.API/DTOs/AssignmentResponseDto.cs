namespace StudentManagement.API.DTOs
{
    public class AssignmentResponseDto
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
    }
}