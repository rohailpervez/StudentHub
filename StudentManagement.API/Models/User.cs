namespace StudentManagement.API.Models
{
    public class User
    {
        public int Id { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;

        // Normal registered users are regular Users.
        // Only the application owner will be SuperAdmin.
        public string Role { get; set; } = "User";

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Organization relationship
        public int OrganizationId { get; set; }

        public Organization? Organization { get; set; }
    }
}