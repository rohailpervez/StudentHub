namespace StudentManagement.API.Models
{
    public class Attendance
    {
        public int Id { get; set; }

        // Student
        public int StudentId { get; set; }

        public Student? Student { get; set; }

        // Course
        public int CourseId { get; set; }

        public Course? Course { get; set; }

        // Organization
        public int OrganizationId { get; set; }

        public Organization? Organization { get; set; }

        // Attendance date
        public DateTime Date { get; set; }

        // true = Present
        // false = Absent
        public bool IsPresent { get; set; }
    }
}