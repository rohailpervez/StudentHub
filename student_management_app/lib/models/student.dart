class Student {
  final int id;
  final String name;
  final String email;
  final String phone;

  // Old single-course relationship (temporary compatibility)
  final int? courseId;
  final String course;

  // New multiple-course relationship
  final List<int> courseIds;
  final List<String> courses;

  // Student status
  final bool isActive;
  // Profile picture
  final String? profilePictureFileName;
  final String? profilePicturePath;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.course,
    required this.courses,
    required this.isActive,
    this.profilePictureFileName,
    this.profilePicturePath,
    this.courseId,
    this.courseIds = const [],
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Old single course
    final courseData = json['course'];

    String courseName = '';

    if (courseData is Map<String, dynamic>) {
      courseName = courseData['name']?.toString() ?? '';
    }

    // New multiple courses
    final coursesData = json['courses'];

    List<int> courseIds = [];
    List<String> courses = [];

    if (coursesData is List) {
      for (final item in coursesData) {
        if (item is Map<String, dynamic>) {
          final id = item['id'];

          if (id != null) {
            courseIds.add(
              int.tryParse(id.toString()) ?? 0,
            );
          }

          final name = item['name']?.toString() ?? '';

          if (name.isNotEmpty) {
            courses.add(name);
          }
        }
      }
    }

    // Fallback for old students
    // that only have the old course relationship.
    if (courses.isEmpty && courseName.isNotEmpty) {
      courses.add(courseName);
    }

    if (courseIds.isEmpty && json['courseId'] != null) {
      final oldCourseId =
      int.tryParse(json['courseId'].toString());

      if (oldCourseId != null) {
        courseIds.add(oldCourseId);
      }
    }

    return Student(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      courseId: json['courseId'] != null
          ? int.tryParse(json['courseId'].toString())
          : null,
      course: courseName,
      courseIds: courseIds,
      courses: courses,
      isActive: json['isActive'] ?? true,
      // Profile picture
      profilePictureFileName:
      json['profilePictureFileName']?.toString(),

      profilePicturePath:
      json['profilePicturePath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,

      // Old compatibility field
      'courseId': courseId,

      // New multiple-course field
      'courseIds': courseIds,

      'isActive': isActive,
      'profilePictureFileName': profilePictureFileName,
      'profilePicturePath': profilePicturePath,
    };
  }
}