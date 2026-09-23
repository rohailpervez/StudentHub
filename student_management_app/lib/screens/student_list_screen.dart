import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_api_service.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'student_profile_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentApiService _apiService = StudentApiService();

  List<Student> _students = [];
  List<Student> _filteredStudents = [];

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadStudents();

    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD STUDENTS
  // ============================================================

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _apiService.getStudents();

      if (!mounted) return;

      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load students.';
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _filterStudents() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final courseNames = student.courses.join(' ').toLowerCase();

          return student.name.toLowerCase().contains(query) ||
              student.email.toLowerCase().contains(query) ||
              student.phone.toLowerCase().contains(query) ||
              student.course.toLowerCase().contains(query) ||
              courseNames.contains(query);
        }).toList();
      }
    });
  }

  // ============================================================
  // TOGGLE ACTIVE / INACTIVE
  // ============================================================

  Future<void> _toggleStudentStatus(Student student) async {
    try {
      final newStatus =
      await _apiService.toggleStudentStatus(student.id);

      if (!mounted) return;

      // Update student locally so UI changes immediately.
      final updatedStudent = Student(
        id: student.id,
        name: student.name,
        email: student.email,
        phone: student.phone,

        // Old compatibility
        courseId: student.courseId,
        course: student.course,

        // New multiple courses
        courseIds: student.courseIds,
        courses: student.courses,

        isActive: newStatus,
      );

      setState(() {
        final index = _students.indexWhere(
              (s) => s.id == student.id,
        );

        if (index != -1) {
          _students[index] = updatedStudent;
        }

        _filterStudents();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Student activated successfully.'
                : 'Student deactivated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update student status.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DELETE STUDENT
  // ============================================================

  Future<void> _deleteStudent(Student student) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Student?'),
          content: Text(
            'Are you sure you want to delete "${student.name}"?\n\n'
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _apiService.deleteStudent(student.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully.'),
        ),
      );

      await _loadStudents();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete student.'),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildContent(),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Students',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage all registered students',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddStudentScreen(),
                ),
              );

              if (result == true) {
                _loadStudents();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        _buildSearchBar(),
        const SizedBox(height: 20),
        Expanded(
          child: _filteredStudents.isEmpty
              ? _buildEmptyState()
              : _buildStudentList(),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
              'Search by name, email, phone or course...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
              )
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadStudents,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _buildStudentList() {
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredStudents.length,
        separatorBuilder: (context, index) {
          return const Divider(height: 1);
        },
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];

          return _buildStudentItem(student);
        },
      ),
    );
  }

  // ============================================================
  // STUDENT ITEM
  // ============================================================

  Widget _buildStudentItem(Student student) {
    final courseText = student.courses.isNotEmpty
        ? student.courses.join(', ')
        : student.course;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: student.isActive
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF3F4F6),
        child: Text(
          student.name.isNotEmpty
              ? student.name.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: student.isActive
                ? const Color(0xFF2563EB)
                : const Color(0xFF6B7280),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              student.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusBadge(student.isActive),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text(
          '${student.email}  •  $courseText',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // VIEW
          IconButton(
            tooltip: 'View Profile',
            icon: const Icon(
              Icons.visibility_outlined,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentProfileScreen(
                    student: student,
                  ),
                ),
              );

              if (result == true) {
                _loadStudents();
              }
            },
          ),

          // EDIT
          IconButton(
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditStudentScreen(
                    student: student,
                  ),
                ),
              );

              if (result == true) {
                _loadStudents();
              }
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),

          // ACTIVATE / DEACTIVATE
          IconButton(
            tooltip:
            student.isActive ? 'Deactivate' : 'Activate',
            onPressed: () {
              _toggleStudentStatus(student);
            },
            icon: Icon(
              student.isActive
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_rounded,
              size: 30,
              color: student.isActive
                  ? Colors.green
                  : Colors.grey,
            ),
          ),

          // DELETE
          IconButton(
            tooltip: 'Delete',
            onPressed: () {
              _deleteStudent(student);
            },
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive
              ? const Color(0xFF166534)
              : const Color(0xFFB91C1C),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try another search or add a new student.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 70,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 15),
          const Text(
            'Unable to load students',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure the ASP.NET Core API is running.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}