import 'package:flutter/material.dart';

import 'auth_gate.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StudentManagementApp());
}

class StudentManagementApp extends StatelessWidget {
  const StudentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Management System',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
