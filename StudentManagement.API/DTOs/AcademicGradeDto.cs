namespace StudentManagement.API.DTOs
{
    public class AcademicGradeDto
    {
        public int Id { get; set; }

        public int StudentId { get; set; }

        public string StudentName { get; set; } = string.Empty;

        public string StudentEmail { get; set; } = string.Empty;

        public int CourseId { get; set; }

        public string CourseName { get; set; } = string.Empty;

        public int OrganizationId { get; set; }

        public decimal? MidTermGrade { get; set; }

        public decimal? FinalGrade { get; set; }

        public DateTime CreatedAt { get; set; }

        public DateTime? UpdatedAt { get; set; }
    }
}