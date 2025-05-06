// lib/presentation/auth/screens/student_login.dart
// Purpose: Student login screen with USN and DOB fields

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../student/screens/student_home.dart';
import '../providers/auth_provider.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usnController = TextEditingController();
  final _dobController = TextEditingController();
  // Removed unused _isPasswordVisible field
  
  @override
  void dispose() {
    _usnController.dispose();
    _dobController.dispose();
    super.dispose();
  }
  
  // Handle login button press
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.studentLogin(
        usn: _usnController.text.trim(),
        dob: _dobController.text.trim(),
      );
      
      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StudentHomeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Student Login',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  Center(
                    child: Image.asset(
                      'assets/images/education_logo.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to Icon if image asset is not available
                        return const Icon(
                          Icons.school,
                          size: 100,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Title
                  const Text(
                    'Student Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 48.0),
                  
                  // USN Field
                  TextFormField(
                    controller: _usnController,
                    decoration: const InputDecoration(
                      labelText: 'USN/Roll Number',
                      hintText: 'Enter your USN (e.g., CS001)',
                      prefixIcon: Icon(Icons.badge),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      return authProvider.studentValidator.getUSNValidationMessage(value ?? '');
                    },
                  ),
                  const SizedBox(height: 16.0),
                  
                  // DOB Field
                  TextFormField(
                    controller: _dobController,
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: _dobController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _dobController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      return authProvider.studentValidator.getDOBValidationMessage(value ?? '');
                    },
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Error Message
                  if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: authProvider.status == AuthStatus.authenticating
                        ? null
                        : _handleLogin,
                    child: authProvider.status == AuthStatus.authenticating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text('LOGIN'),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Help Text
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Use your university roll number and date of birth to login.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  
                  // Debug Login Info (for testing, remove in production)
                  if (true) // Set to false in production
                    const Padding(
                      padding: EdgeInsets.only(top: 32.0),
                      child: Text(
                        'Test Login: USN=CS001, DOB=01/01/2000',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}