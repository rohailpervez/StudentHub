namespace StudentManagement.API.Models
{
    public class AttendanceRequest
    {
        public int StudentId { get; set; }

        public int CourseId { get; set; }

        public DateTime Date { get; set; }

        public bool IsPresent { get; set; }
    }
}