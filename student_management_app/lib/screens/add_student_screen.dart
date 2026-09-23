import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/student_api_service.dart';
import '../../models/course.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final StudentApiService _apiService = StudentApiService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Course> _courses = [];
  final List<int> _selectedCourseIds = [];

  bool _isLoadingCourses = true;
  bool _isSaving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
        _courses = courses
            .where((course) => course.isActive)
            .toList();

        _isLoadingCourses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCourses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load courses. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SAVE STUDENT
  // ============================================================

  Future<void> _saveStudent() async {
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
            (course) =>
            _selectedCourseIds.contains(course.id),
      )
          .toList();

      final firstCourse = selectedCourses.isNotEmpty
          ? selectedCourses.first
          : null;

      final student = Student(
        id: 0,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),

        // Old compatibility
        courseId: firstCourse?.id,
        course: firstCourse?.name ?? '',

        // New multiple courses
        courseIds: _selectedCourseIds,
        courses: selectedCourses
            .map((course) => course.name)
            .toList(),

        isActive: true,
      );

      await _apiService.addStudent(
        student,
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Student added successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 32,
      ),
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
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Add Student',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Create a new student record',
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
          crossAxisAlignment:
          CrossAxisAlignment.start,
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

            const Text(
              'Enter the student details and login credentials below.',
              style: TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // NAME
            // ==================================================

            _buildField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter student name',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter the student name';
                }

                if (value.trim().length < 3) {
                  return 'Name must contain at least 3 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // EMAIL
            // ==================================================

            _buildField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'student@example.com',
              icon: Icons.email_outlined,
              keyboardType:
              TextInputType.emailAddress,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter an email address';
                }

                final emailRegex = RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                );

                if (!emailRegex.hasMatch(
                  value.trim(),
                )) {
                  return 'Please enter a valid email address';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PASSWORD
            // ==================================================

            _buildPasswordField(),

            const SizedBox(height: 20),

            // ==================================================
            // PHONE
            // ==================================================

            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '03001234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Please enter a phone number';
                }

                if (value.trim().length < 10) {
                  return 'Please enter a valid phone number';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MULTIPLE COURSES
            // ==================================================

            _buildCourseSelector(),

            const SizedBox(height: 32),

            const Divider(
              color: Color(0xFFE5E5E5),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(0xFF111111),
                    side: const BorderSide(
                      color: Color(0xFFCCCCCC),
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
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
                  onPressed:
                  _isSaving ? null : _saveStudent,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.person_add_alt_1_rounded,
                  ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save Student',
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
  // PASSWORD FIELD
  // ============================================================

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Login Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null ||
                value.isEmpty) {
              return 'Please enter a password';
            }

            if (value.length < 6) {
              return 'Password must contain at least 6 characters';
            }

            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter login password',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF666666),
            ),
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Show password'
                  : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscurePassword =
                  !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF666666),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 1.5,
              ),
            ),
            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'This password will be used by the student to log in.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COURSE SELECTOR
  // ============================================================

  Widget _buildCourseSelector() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
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
              borderRadius:
              BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
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
              borderRadius:
              BorderRadius.circular(10),
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
                    'No active courses available.',
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
              borderRadius:
              BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
              ),
            ),
            child: Column(
              children: [
                ..._courses.map(
                      (course) =>
                      CheckboxListTile(
                        value: _selectedCourseIds
                            .contains(course.id),
                        onChanged: _isSaving
                            ? null
                            : (selected) {
                          setState(() {
                            if (selected ==
                                true) {
                              if (!_selectedCourseIds
                                  .contains(
                                course.id,
                              )) {
                                _selectedCourseIds
                                    .add(
                                  course.id,
                                );
                              }
                            } else {
                              _selectedCourseIds
                                  .remove(
                                course.id,
                              );
                            }
                          });
                        },
                        title: Text(
                          course.name,
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w500,
                            color:
                            Color(0xFF222222),
                          ),
                        ),
                        subtitle: Text(
                          'Course ID: ${course.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color:
                            Color(0xFF888888),
                          ),
                        ),
                        controlAffinity:
                        ListTileControlAffinity
                            .leading,
                        activeColor: Colors.black,
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
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
  // GENERIC FORM FIELD
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
      crossAxisAlignment:
      CrossAxisAlignment.start,
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
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF111111),
                width: 1.5,
              ),
            ),
            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
            contentPadding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}