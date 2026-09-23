class Attendance {
  final int id;

  final int studentId;
  final String studentName;
  final String studentEmail;

  final int courseId;
  final String courseName;

  final int organizationId;

  final DateTime date;
  final bool isPresent;

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseId,
    required this.courseName,
    required this.organizationId,
    required this.date,
    required this.isPresent,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final student = json['student'] is Map<String, dynamic>
        ? json['student'] as Map<String, dynamic>
        : <String, dynamic>{};

    final course = json['course'] is Map<String, dynamic>
        ? json['course'] as Map<String, dynamic>
        : <String, dynamic>{};

    return Attendance(
      id: json['id'] ?? 0,

      studentId: json['studentId'] ?? 0,
      studentName: student['name']?.toString() ?? 'Unknown Student',
      studentEmail: student['email']?.toString() ?? '',

      courseId: json['courseId'] ?? 0,
      courseName: course['name']?.toString() ?? 'Unknown Course',

      organizationId: json['organizationId'] ?? 0,

      date: DateTime.parse(
        json['date'].toString(),
      ),

      isPresent: json['isPresent'] == true,
    );
  }
}