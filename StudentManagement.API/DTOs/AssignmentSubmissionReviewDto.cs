using System.ComponentModel.DataAnnotations;

namespace StudentManagement.API.DTOs
{
    public class AssignmentSubmissionReviewDto
    {
        [Required]
        [Range(0, 100)]
        public decimal Grade { get; set; }

        [MaxLength(5000)]
        public string Feedback { get; set; } = string.Empty;
    }
}