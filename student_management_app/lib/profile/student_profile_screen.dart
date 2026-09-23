import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_api_service.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_api_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final StudentApiService _apiService = StudentApiService();
  final AuthApiService _authApiService = AuthApiService();

  Student? _student;

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  bool _isUpdatingProfile = false;

  final TextEditingController _currentPasswordController =
  TextEditingController();

  final TextEditingController _newPasswordController =
  TextEditingController();

  final TextEditingController _confirmNewPasswordController =
  TextEditingController();

  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();

    super.dispose();
  }
// ============================================================
// LOAD LOGGED-IN STUDENT
// ============================================================

  Future<void> _loadStudent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final student = await _apiService.getMyStudent();

      if (!mounted) return;

      setState(() {
        _student = student;

        _nameController.text = student.name;
        _emailController.text = student.email;
        _phoneController.text = student.phone;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  Future<void> _showEditProfileDialog() async {
    if (_student == null) return;

    _nameController.text = _student!.name;
    _emailController.text = _student!.email;
    _phoneController.text = _student!.phone;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUpdatingProfile
                      ? null
                      : () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isUpdatingProfile
                      ? null
                      : () async {
                    final name =
                    _nameController.text.trim();
                    final email =
                    _emailController.text.trim();
                    final phone =
                    _phoneController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                          Text('Name is required.'),
                        ),
                      );
                      return;
                    }

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content:
                          Text('Email is required.'),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      _isUpdatingProfile = true;
                    });

                    try {
                      final updatedStudent =
                      await _apiService
                          .updateMyStudentProfile(
                        name: name,
                        email: email,
                        phone: phone,
                      );

                      if (!mounted) return;

                      setState(() {
                        _student = updatedStudent;
                      });

                      if (context.mounted) {
                        Navigator.pop(context, true);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Profile updated successfully.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;

                      setDialogState(() {
                        _isUpdatingProfile = false;
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF111111),
                    foregroundColor: Colors.white,
                  ),
                  child: _isUpdatingProfile
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CHANGE PASSWORD DIALOG
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      enabled: !_isChangingPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isChangingPassword
                              ? null
                              : () {
                            setDialogState(() {
                              obscureCurrentPassword =
                              !obscureCurrentPassword;
                            });
                          },
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _newPasswordController,
                      obscureText: obscureNewPassword,
                      enabled: !_isChangingPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isChangingPassword
                              ? null
                              : () {
                            setDialogState(() {
                              obscureNewPassword =
                              !obscureNewPassword;
                            });
                          },
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _confirmNewPasswordController,
                      obscureText: obscureConfirmPassword,
                      enabled: !_isChangingPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isChangingPassword
                              ? null
                              : () {
                            setDialogState(() {
                              obscureConfirmPassword =
                              !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isChangingPassword
                      ? null
                      : () async {
                    final currentPassword =
                    _currentPasswordController.text.trim();

                    final newPassword =
                    _newPasswordController.text.trim();

                    final confirmNewPassword =
                    _confirmNewPasswordController.text.trim();

                    if (currentPassword.isEmpty ||
                        newPassword.isEmpty ||
                        confirmNewPassword.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'All password fields are required.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (newPassword.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'New password must be at least 6 characters.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (newPassword != confirmNewPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'New password and confirm password do not match.',
                          ),
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      _isChangingPassword = true;
                    });

                    try {
                      final result =
                      await _authApiService.changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                        confirmNewPassword: confirmNewPassword,
                      );

                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message']?.toString() ??
                                'Password changed successfully.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      setDialogState(() {
                        _isChangingPassword = false;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst(
                              'Exception: ',
                              '',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: _isChangingPassword
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );

    _isChangingPassword = false;
  }

  // ============================================================
  // CHANGE PROFILE PICTURE
  // ============================================================

  Future<void> _changeProfilePicture() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;

      final fileName = pickedFile.name;

      final fileBytes = pickedFile.bytes;

      final filePath = pickedFile.path;

      if (fileBytes == null && (filePath == null || filePath.isEmpty)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access the selected image.',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF111111),
            ),
          );
        },
      );

      await _apiService.uploadMyProfilePicture(
        filePath ?? fileName,
        fileBytes: fileBytes,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      await _loadStudent();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile picture updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final student = _student;

    if (student == null) {
      return const Center(
        child: Text(
          'Student profile not found.',
          style: TextStyle(
            color: Color(0xFF555555),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 24),
          _buildProfileHeader(student),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildPersonalInformation(student),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _buildAcademicInformation(student),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSecuritySection(),
        ],
      ),
    );
  }

// ============================================================
// PAGE HEADER
// ============================================================

  Widget _buildPageHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your personal and academic information.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

// ============================================================
// PROFILE HEADER
// ============================================================

  Widget _buildProfileHeader(Student student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          _buildAvatar(
            name: student.name,
            size: 78,
            profilePicturePath: student.profilePicturePath,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  student.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Text(
                    'STUDENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          OutlinedButton.icon(
            onPressed: _changeProfilePicture,
            icon: const Icon(
              Icons.camera_alt_outlined,
              size: 17,
            ),
            label: const Text('Change Picture'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// PERSONAL INFORMATION
// ============================================================

  Widget _buildPersonalInformation(Student student) {
    return _buildCard(
      title: 'Personal Information',
      subtitle: 'Your basic account information.',
      trailing: OutlinedButton.icon(
        onPressed: _isUpdatingProfile
            ? null
            : _showEditProfileDialog,
        icon: const Icon(
          Icons.edit_outlined,
          size: 15,
        ),
        label: const Text('Edit Profile'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF222222),
          side: const BorderSide(
            color: Color(0xFFD9D9D9),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            value: student.name,
          ),
          const Divider(height: 1),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: student.email,
          ),
          const Divider(height: 1),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: student.phone.isEmpty ? 'Not provided' : student.phone,
          ),
        ],
      ),
    );
  }

// ============================================================
// ACADEMIC INFORMATION
// ============================================================

  Widget _buildAcademicInformation(Student student) {
    return _buildCard(
      title: 'Academic Information',
      subtitle: 'Information managed by your institution.',
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Student ID',
            value: student.id.toString(),
          ),
          const Divider(height: 1),
          _buildInfoRow(
            icon: Icons.menu_book_outlined,
            label: 'Enrolled Subjects',
            value: student.courses.length.toString(),
          ),
          const Divider(height: 1),
          _buildInfoRow(
            icon: Icons.verified_outlined,
            label: 'Account Status',
            value: student.isActive ? 'Active' : 'Inactive',
          ),
          const SizedBox(height: 16),
          _buildCoursesSection(student),
        ],
      ),
    );
  }

// ============================================================
// COURSES
// ============================================================

  Widget _buildCoursesSection(Student student) {
    final courses = student.courses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enrolled Courses',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          if (courses.isEmpty)
            const Text(
              'No courses assigned.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
              ),
            )
          else
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: Color(0xFF555555),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF444444),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

// ============================================================
// SECURITY
// ============================================================

  Widget _buildSecuritySection() {
    return _buildCard(
      title: 'Security',
      subtitle: 'Manage your account security.',
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: _showChangePasswordDialog,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color(0xFFE8E8E8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Update your account password securely.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }

// ============================================================
// INFO ROW
// ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 17,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF777777),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// CARD
// ============================================================

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE4E4E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

// ============================================================
// AVATAR
// ============================================================

  Widget _buildAvatar({
    required String name,
    required double size,
    String? profilePicturePath,
  }) {
    final initial = name.trim().isEmpty
        ? 'S'
        : name.trim().substring(0, 1).toUpperCase();

    final imageUrl = profilePicturePath != null &&
        profilePicturePath.trim().isNotEmpty
        ? 'http://localhost:5083${profilePicturePath.trim()}'
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl != null
          ? Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            initial,
            style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: size * 0.40,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      )
          : Text(
        initial,
        style: TextStyle(
          color: const Color(0xFF111111),
          fontSize: size * 0.40,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

// ============================================================
// LOADING
// ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your profile...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF777777),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// ERROR
// ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE4E4E4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFF333333),
                size: 27,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF777777),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadStudent,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
