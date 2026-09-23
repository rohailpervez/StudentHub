namespace StudentManagement.API.Models
{
    public class AssignmentSubmission
    {
        public int Id { get; set; }

        public int AssignmentId { get; set; }
        public Assignment? Assignment { get; set; }

        public int StudentId { get; set; }
        public Student? Student { get; set; }

        public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;

        // Uploaded file information
        public string FileName { get; set; } = string.Empty;

        public string FilePath { get; set; } = string.Empty;

        // Pending / Submitted / Late
        public string Status { get; set; } = "Submitted";

        // We will use these later for teacher evaluation
        public decimal? Grade { get; set; }

        public string Feedback { get; set; } = string.Empty;
    }
}