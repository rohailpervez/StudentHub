using System.ComponentModel.DataAnnotations;

namespace StudentManagement.API.DTOs
{
    public class AssignmentSubmissionCreateDto
    {
        [Required]
        [MaxLength(255)]
        public string FileName { get; set; } = string.Empty;

        [Required]
        [MaxLength(1000)]
        public string FilePath { get; set; } = string.Empty;
    }
}