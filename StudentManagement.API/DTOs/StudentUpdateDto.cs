using System.ComponentModel.DataAnnotations;

namespace StudentManagement.API.DTOs
{
    public class StudentUpdateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        // Student can be enrolled in multiple courses
        public List<int> CourseIds { get; set; } = new List<int>();

        public bool IsActive { get; set; } = true;
    }
}