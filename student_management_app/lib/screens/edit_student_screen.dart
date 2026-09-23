import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../services/student_api_service.dart';

class EditStudentScreen extends StatefulWidget {
  final Student student;

  const EditStudentScreen({
    super.key,
    required this.student,
  });

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final StudentApiService _apiService = StudentApiService();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  List<Course> _courses = [];

  // Multiple selected courses
  late List<int> _selectedCourseIds;

  bool _isLoadingCourses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.student.name,
    );

    _emailController = TextEditingController(
      text: widget.student.email,
    );

    _phoneController = TextEditingController(
      text: widget.student.phone,
    );

    // Load all courses already assigned to this student.
    //
    // For old students, courseIds will contain the old courseId
    // because Student.fromJson has a compatibility fallback.
    _selectedCourseIds = List<int>.from(
      widget.student.courseIds,
    );

    // Extra safety for old single-course data.
    if (_selectedCourseIds.isEmpty &&
        widget.student.courseId != null) {
      _selectedCourseIds = [
        widget.student.courseId!,
      ];
    }

    _loadCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD COURSES
  // ============================================================

  Future<void> _loadCourses() async {
    try {
      final courses = await _apiService.getCourses();

      if (!mounted) return;

      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCourses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load courses.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // UPDATE STUDENT
  // ============================================================

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one course.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final selectedCourses = _courses
          .where(
            (course) => _selectedCourseIds.contains(course.id),
      )
          .toList();

      // First selected course is kept for old compatibility fields.
      final firstCourse =
      selectedCourses.isNotEmpty ? selectedCourses.first : null;

      final updatedStudent = Student(
        id: widget.student.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),

        // Old compatibility
        courseId: firstCourse?.id,
        course: firstCourse?.name ?? '',

        // New multiple courses
        courseIds: List<int>.from(_selectedCourseIds),
        courses: selectedCourses
            .map((course) => course.name)
            .toList(),

        isActive: widget.student.isActive,
      );

      await _apiService.updateStudent(updatedStudent);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update student. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 850,
                  ),
                  child: _buildFormCard(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: _isSaving
                ? null
                : () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Student',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Update student information',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E5E5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Information',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Editing student #${widget.student.id}',
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // NAME
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter student name',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the student name';
                }

                if (value.trim().length < 3) {
                  return 'Name must contain at least 3 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // EMAIL
            _buildField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'student@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email address';
                }

                final emailRegex = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                );

                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // PHONE
            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '03001234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }

                if (value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // MULTIPLE COURSES
            _buildCourseSelector(),

            const SizedBox(height: 32),

            const Divider(
              color: Color(0xFFE5E5E5),
            ),

            const SizedBox(height: 24),

            // BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111111),
                    side: const BorderSide(
                      color: Color(0xFFCCCCCC),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _updateStudent,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),
                  label: Text(
                    _isSaving
                        ? 'Updating...'
                        : 'Update Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MULTIPLE COURSE SELECTOR
  // ============================================================

  Widget _buildCourseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),

        const SizedBox(height: 8),

        if (_isLoadingCourses)
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
            ),
          )
        else if (_courses.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF777777),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No courses available.',
                    style: TextStyle(
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: Column(
              children: [
                ..._courses
                    .where(
                      (course) =>
                  course.isActive ||
                      _selectedCourseIds.contains(course.id),
                )
                    .map(
                      (course) => CheckboxListTile(
                    value: _selectedCourseIds.contains(
                      course.id,
                    ),
                    onChanged: _isSaving
                        ? null
                        : (selected) {
                      setState(() {
                        if (selected == true) {
                          if (!_selectedCourseIds
                              .contains(course.id)) {
                            _selectedCourseIds
                                .add(course.id);
                          }
                        } else {
                          _selectedCourseIds
                              .remove(course.id);
                        }
                      });
                    },
                    title: Text(
                      course.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF222222),
                      ),
                    ),
                    subtitle: Text(
                      'Course ID: ${course.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    controlAffinity:
                    ListTileControlAffinity.leading,
                    activeColor: Colors.black,
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    secondary: !course.isActive
                        ? Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E5),
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                        : null,
                  ),
                ),
              ],
            ),
          ),

        if (_selectedCourseIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            '${_selectedCourseIds.length} course${_selectedCourseIds.length == 1 ? '' : 's'} selected',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF666666),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}