namespace StudentManagement.API.DTOs
{
    public class AcademicGradeUpsertDto
    {
        public int StudentId { get; set; }

        public int CourseId { get; set; }

        public decimal? MidTermGrade { get; set; }

        public decimal? FinalGrade { get; set; }
    }
}