class AttendanceRecord {
  final int id;
  final int courseId;
  final String courseName;
  final DateTime date;
  final bool isPresent;

  AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.date,
    required this.isPresent,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      courseId: json['courseId'] ?? 0,
      courseName: json['courseName']?.toString() ?? 'Unknown Course',
      date: DateTime.parse(
        json['date'].toString(),
      ),
      isPresent: json['isPresent'] == true,
    );
  }
}

class AttendanceSummary {
  final int totalClasses;
  final int presentClasses;
  final int absentClasses;
  final double attendancePercentage;
  final List<AttendanceRecord> records;

  AttendanceSummary({
    required this.totalClasses,
    required this.presentClasses,
    required this.absentClasses,
    required this.attendancePercentage,
    required this.records,
  });

  factory AttendanceSummary.fromJson(
      Map<String, dynamic> json,
      ) {
    final recordsData = json['records'];

    final records = recordsData is List
        ? recordsData
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AttendanceRecord.fromJson(item),
    )
        .toList()
        : <AttendanceRecord>[];

    return AttendanceSummary(
      totalClasses: json['totalClasses'] ?? 0,
      presentClasses: json['presentClasses'] ?? 0,
      absentClasses: json['absentClasses'] ?? 0,
      attendancePercentage:
      (json['attendancePercentage'] ?? 0).toDouble(),
      records: records,
    );
  }
}