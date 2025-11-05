import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Text controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  // Sign up method
  void _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match!";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = AuthService();
      await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _birthDateController.text.trim(),
        _phoneController.text.trim(),
      );
      
      // After successful signup, pop back to login screen
      // AuthGate will then detect the new user and navigate to the app
      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Sign up',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Create an account to continue!',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(label: 'First Name', controller: _firstNameController),
                _buildTextField(label: 'Last Name', controller: _lastNameController),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Enter a valid email',
                ),
                _buildTextField(
                  label: 'Birth of date',
                  controller: _birthDateController,
                  hint: 'Enter your birth date',
                  isDatePicker: true,
                ),
                _buildTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hint: '+63 ',
                ),
                _buildTextField(
                  label: 'Set Password',
                  controller: _passwordController,
                  isPassword: true,
                ),
                _buildTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                ),
                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),

                // Register Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        child: const Text('Register'),
                      ),
                const SizedBox(height: 24),

                // Log In link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    bool isDatePicker = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkTextColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: isDatePicker
                  ? const Icon(Icons.calendar_today_outlined)
                  : (isPassword ? const Icon(Icons.visibility_off_outlined) : null),
            ),
            readOnly: isDatePicker,
            onTap: isDatePicker
                ? () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2101),
                    );
                    
                    // FIX: This 'if' block prevents the null crash
                    if (pickedDate != null) {
                      String formattedDate =
                          "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
                      controller.text = formattedDate;
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}