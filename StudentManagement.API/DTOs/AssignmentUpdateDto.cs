using System.ComponentModel.DataAnnotations;

namespace StudentManagement.API.DTOs
{
    public class AssignmentUpdateDto
    {
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(5000)]
        public string Description { get; set; } = string.Empty;

        [Required]
        public DateTime DueDate { get; set; }

        public bool IsActive { get; set; } = true;
    }
}