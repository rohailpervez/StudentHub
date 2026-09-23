using System.ComponentModel.DataAnnotations;

namespace StudentManagement.API.DTOs
{
    public class StudentCreateDto
    {
        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        // Student login password
        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;

        // Student can be enrolled in multiple courses
        public List<int> CourseIds { get; set; } = new List<int>();
    }
}