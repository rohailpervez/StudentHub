import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthApiService _authApiService = AuthApiService();

  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

// New organization name.
//
// If this is not null, registration will use:
// POST /api/Auth/register-organization
//
// This makes the first user an Admin.
  String? _newOrganizationName;

// ============================================================
// INIT
// ============================================================

  @override
  void initState() {
    super.initState();
  }

// ============================================================
// DISPOSE
// ============================================================

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

// ============================================================
// REGISTER
// ============================================================

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newOrganizationName == null || _newOrganizationName!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create a new organization first.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
// ========================================================
// NEW ORGANIZATION
// ========================================================

      await _authApiService.registerOrganization(
        organizationName: _newOrganizationName!.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Organization and admin account created successfully. Please sign in.',
          ),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
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
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// ============================================================
// CREATE NEW ORGANIZATION
// ============================================================

  Future<void> _showCreateOrganizationDialog() async {
    final TextEditingController organizationController = TextEditingController(
      text: _newOrganizationName ?? '',
    );

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool isCreating = false;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> selectNewOrganization() async {
              final name = organizationController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter organization name.',
                    ),
                    backgroundColor: Color(0xFFDC2626),
                  ),
                );

                return;
              }

              setDialogState(() {
                isCreating = true;
              });

// We DO NOT create the organization here.
//
// We only remember its name.
//
// Actual organization + admin creation
// happens when the user presses
// "Create Account".

              setState(() {
                _newOrganizationName = name;
              });

              await Future.delayed(
                const Duration(milliseconds: 200),
              );

              if (!dialogContext.mounted) return;

              Navigator.of(dialogContext).pop();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$name selected. Complete the form and create the account.',
                  ),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            }

            return AlertDialog(
              title: const Text(
                'Create New Organization',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextField(
                controller: organizationController,
                enabled: !isCreating,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!isCreating) {
                    selectNewOrganization();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Organization Name',
                  hintText: 'e.g. ABC Academy',
                  prefixIcon: const Icon(
                    Icons.business_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: isCreating ? null : selectNewOrganization,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF16A34A,
                    ),
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    organizationController.dispose();
  }

// ============================================================
// BUILD
// ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 42),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your StudentHub administrator account.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(height: 34),
                  _buildFullNameField(),
                  const SizedBox(height: 18),
                  _buildEmailField(),
                  const SizedBox(height: 18),
                  _buildOrganizationField(),
                  const SizedBox(height: 18),
                  _buildPasswordField(),
                  const SizedBox(height: 18),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 28),
                  _buildRegisterButton(),
                  const SizedBox(height: 22),
                  _buildLoginLink(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// ============================================================
// LOGO
// ============================================================

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A),
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 13),
        const Text(
          'StudentHub',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

// ============================================================
// FULL NAME
// ============================================================

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Name',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameController,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hintText: 'Enter your full name',
            icon: Icons.person_outline_rounded,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name.';
            }

            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters.';
            }

            return null;
          },
        ),
      ],
    );
  }

// ============================================================
// EMAIL
// ============================================================

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hintText: 'Enter your email',
            icon: Icons.email_outlined,
          ),
          validator: (value) {
            final email = value?.trim() ?? '';

            if (email.isEmpty) {
              return 'Please enter your email.';
            }

            if (!email.contains('@')) {
              return 'Please enter a valid email.';
            }

            return null;
          },
        ),
      ],
    );
  }

// ============================================================
// ORGANIZATION
// ============================================================

  Widget _buildOrganizationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        if (_newOrganizationName != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF0FDF4,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color: const Color(
                  0xFFBBF7D0,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.business_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Organization',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(
                            0xFF166534,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _newOrganizationName!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(
                            0xFF166534,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _newOrganizationName = null;
                          });
                        },
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(
                      0xFF166534,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFF8FAF8,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color: const Color(
                  0xFFE2E8E2,
                ),
              ),
            ),
            child: const Text(
              'Create a new organization to continue.',
              style: TextStyle(
                fontSize: 13,
                color: Color(
                  0xFF777777,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isLoading ? null : _showCreateOrganizationDialog,
            icon: const Icon(
              Icons.add_business_outlined,
              size: 18,
            ),
            label: const Text(
              'Create New Organization',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(
                0xFF16A34A,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

// ============================================================
// PASSWORD
// ============================================================

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hintText: 'Create a password',
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(
                  0xFF777777,
                ),
                size: 20,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password.';
            }

            if (value.length < 6) {
              return 'Password must be at least 6 characters.';
            }

            return null;
          },
        ),
      ],
    );
  }

// ============================================================
// CONFIRM PASSWORD
// ============================================================

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!_isLoading) {
              _register();
            }
          },
          decoration: _inputDecoration(
            hintText: 'Confirm your password',
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip:
                  _obscureConfirmPassword ? 'Show password' : 'Hide password',
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(
                  0xFF777777,
                ),
                size: 20,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password.';
            }

            if (value != _passwordController.text) {
              return 'Passwords do not match.';
            }

            return null;
          },
        ),
      ],
    );
  }

// ============================================================
// INPUT DECORATION
// ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(
          0xFF777777,
        ),
        size: 20,
      ),
      filled: true,
      fillColor: const Color(
        0xFFF8FAF8,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          10,
        ),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8E2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          10,
        ),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8E2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          10,
        ),
        borderSide: const BorderSide(
          color: Color(0xFF16A34A),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          10,
        ),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          10,
        ),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.5,
        ),
      ),
    );
  }

// ============================================================
// REGISTER BUTTON
// ============================================================

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _isLoading ? null : _register,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(
            0xFF16A34A,
          ),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(
            0xFF86C99A,
          ),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

// ============================================================
// LOGIN LINK
// ============================================================

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF777777),
            ),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ============================================================
// FOOTER
// ============================================================

  Widget _buildFooter() {
    return Center(
      child: Text(
        'StudentHub • Student Management System',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
