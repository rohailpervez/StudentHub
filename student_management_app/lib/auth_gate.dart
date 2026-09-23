
import 'package:flutter/material.dart';
import 'package:student_management_app/screens/common_dashboard_screen.dart';
import 'package:student_management_app/screens/super_admin_dashboard_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'services/auth_api_service.dart';

class AuthGate extends StatefulWidget {
const AuthGate({super.key});

@override
State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
final AuthApiService _authApiService = AuthApiService();

bool _isChecking = true;
bool _isLoggedIn = false;
String _userRole = '';

@override
void initState() {
super.initState();
_checkAuthentication();
}

Future<void> _checkAuthentication() async {
final loggedIn = await _authApiService.isLoggedIn();

if (!loggedIn) {
if (!mounted) return;

setState(() {
_isLoggedIn = false;
_isChecking = false;
});

return;
}

final user = await _authApiService.getSavedUser();

if (!mounted) return;

setState(() {
_isLoggedIn = true;
_userRole = user?['role']?.toString().toLowerCase() ?? '';
_isChecking = false;
});
}

Widget _getDashboardForRole() {
switch (_userRole) {
case 'admin':
return const DashboardScreen();

case 'teacher':
case 'staff':
return const CommonDashboardScreen();

case 'user':
case 'student':
return const StudentDashboardScreen();

case 'superadmin':
case 'super admin':

  return const SuperAdminDashboardScreen();

default:
// Existing fallback behavior.
return const DashboardScreen();
}
}

@override
Widget build(BuildContext context) {
if (_isChecking) {
return const Scaffold(
backgroundColor: Colors.white,
body: Center(
child: CircularProgressIndicator(
color: Color(0xFF16A34A),
),
),
);
}

if (_isLoggedIn) {
return _getDashboardForRole();
}

return const LoginScreen();
}
}

