import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/users_api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UsersApiService _apiService = UsersApiService();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD USERS
  // ============================================================

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getUsers();

      if (!mounted) return;

      final users = data.map((json) => UserModel.fromJson(json)).toList();

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _filterUsers() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.role.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // ============================================================
  // ADD TEACHER / STAFF
  // ============================================================

  Future<void> _showAddMemberDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    String selectedRole = 'Teacher';
    bool obscurePassword = true;
    bool isCreating = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Member'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Create a Teacher or Staff account.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // FULL NAME
                        TextFormField(
                          controller: nameController,
                          enabled: !isCreating,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Full name is required.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // EMAIL
                        TextFormField(
                          controller: emailController,
                          enabled: !isCreating,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required.';
                            }

                            if (!value.contains('@')) {
                              return 'Enter a valid email.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // PASSWORD
                        TextFormField(
                          controller: passwordController,
                          enabled: !isCreating,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required.';
                            }

                            if (value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ROLE
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Teacher',
                              child: Text('Teacher'),
                            ),
                            DropdownMenuItem(
                              value: 'Staff',
                              child: Text('Staff'),
                            ),
                          ],
                          onChanged: isCreating
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  setDialogState(() {
                                    selectedRole = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isCreating = true;
                          });

                          try {
                            await _apiService.createMember(
                              fullName: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              role: selectedRole,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              isCreating = false;
                            });

                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
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
                  icon: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.person_add_alt_1,
                        ),
                  label: Text(
                    isCreating ? 'Creating...' : 'Create Member',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (result == true) {
      await _loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Member account created successfully.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // VIEW USER DETAILS
  // ============================================================

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ID', '#${user.id}'),
              _detailRow('Name', user.fullName),
              _detailRow('Email', user.email),
              _detailRow('Role', user.role),
              _detailRow(
                'Status',
                user.isActive ? 'Active' : 'Inactive',
              ),
              _detailRow(
                'Organization ID',
                user.organizationId.toString(),
              ),
              _detailRow(
                'Created',
                _formatDate(user.createdAt),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // EDIT USER
  // ============================================================

  Future<void> _editUser(UserModel user) async {
    final nameController = TextEditingController(text: user.fullName);

    final emailController = TextEditingController(text: user.email);

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required.';
                    }

                    if (!value.contains('@')) {
                      return 'Enter a valid email.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                try {
                  await _apiService.updateUser(
                    id: user.id,
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                  );

                  if (!context.mounted) return;

                  Navigator.pop(context, true);
                } catch (e) {
                  if (!context.mounted) return;

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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();

    if (result == true) {
      await _loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User updated successfully.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<void> _toggleUserStatus(
    UserModel user,
  ) async {
    try {
      final newStatus = !user.isActive;

      await _apiService.updateUserStatus(
        id: user.id,
        isActive: newStatus,
      );

      if (!mounted) return;

      final updatedUser = user.copyWith(
        isActive: newStatus,
      );

      setState(() {
        final index = _users.indexWhere(
          (u) => u.id == user.id,
        );

        if (index != -1) {
          _users[index] = updatedUser;
        }

        _filterUsers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'User activated successfully.'
                : 'User deactivated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update user status.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> _deleteUser(UserModel user) async {
    if (user.role == 'SuperAdmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SuperAdmin cannot be deleted.',
          ),
        ),
      );

      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User?'),
          content: Text(
            'Are you sure you want to delete '
            '"${user.fullName}"?\n\n'
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
      await _apiService.deleteUser(user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User deleted successfully.',
          ),
        ),
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;

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
                'Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage organization users',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const Spacer(),

          // ADD MEMBER BUTTON
          FilledButton.icon(
            onPressed: _showAddMemberDialog,
            icon: const Icon(
              Icons.person_add_alt_1,
            ),
            label: const Text('Add Member'),
          ),

          const SizedBox(width: 12),

          // REFRESH BUTTON
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadUsers,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
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
          child: _filteredUsers.isEmpty ? _buildEmptyState() : _buildUserList(),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search by name, email or role...',
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
    );
  }

  // ============================================================
  // USER LIST
  // ============================================================

  Widget _buildUserList() {
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        itemCount: _filteredUsers.length,
        separatorBuilder: (context, index) {
          return const Divider(
            height: 1,
          );
        },
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];

          return _buildUserItem(user);
        },
      ),
    );
  }

  // ============================================================
  // USER ITEM
  // ============================================================

  Widget _buildUserItem(
    UserModel user,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor:
            user.isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
        child: Text(
          user.fullName.isNotEmpty
              ? user.fullName.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: user.isActive
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
              user.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusBadge(
            user.isActive,
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(
          top: 7,
        ),
        child: Text(
          '${user.email}  •  ${user.role}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'View',
            onPressed: () {
              _showUserDetails(user);
            },
            icon: const Icon(
              Icons.visibility_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () {
              _editUser(user);
            },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: user.isActive ? 'Deactivate' : 'Activate',
            onPressed: () {
              _toggleUserStatus(
                user,
              );
            },
            icon: Icon(
              user.isActive
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_rounded,
              size: 30,
              color: user.isActive ? Colors.green : Colors.grey,
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () {
              _deleteUser(user);
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

  Widget _buildStatusBadge(
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF166534) : const Color(0xFFB91C1C),
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
            'No users found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No users match your search.',
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
            'Unable to load users',
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
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
