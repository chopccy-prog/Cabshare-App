// lib/screens/signup_page.dart - Enhanced Signup with Relaxed Phone Validation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/debug_service.dart';
import 'home_shell.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  final ApiClient api;
  
  const SignupPage({super.key, required this.api});
  
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  
  // Validation states
  bool _nameValid = false;
  bool _emailValid = false;
  bool _phoneValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;
  
  @override
  void initState() {
    super.initState();
    // Set up phone controller with +91 prefix
    _phoneController.text = '+91';
    
    // Add listeners for real-time validation
    _fullNameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _phoneController.addListener(_validatePhone);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      _nameValid = _fullNameController.text.trim().length >= 2;
    });
  }

  void _validateEmail() {
    setState(() {
      _emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text.trim());
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text;
    setState(() {
      // Check if it's exactly +91 followed by 10 digits (any digits 0-9)
      _phoneValid = phone.length == 13 && 
                   phone.startsWith('+91') &&
                   RegExp(r'^\d{10}$').hasMatch(phone.substring(3));
    });
  }

  void _validatePassword() {
    setState(() {
      _passwordValid = _passwordController.text.length >= 6;
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      _confirmPasswordValid = _confirmPasswordController.text.isNotEmpty &&
                             _confirmPasswordController.text == _passwordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Welcome Text
                  const Text(
                    'Join Worksetu CabShare',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Create your account in one simple step',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Full Name Field
                  _buildValidatedTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    isValid: _nameValid,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters long';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email Field
                  _buildValidatedTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    isValid: _emailValid,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Phone Field with Enhanced Logic
                  _buildPhoneField(),
                  
                  const SizedBox(height: 16),
                  
                  // Password Field
                  _buildValidatedTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock,
                    obscureText: true,
                    isValid: _passwordValid,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  _buildValidatedTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    isValid: _confirmPasswordValid,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Terms and Privacy
                  Text(
                    'By creating an account, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?  ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: _goToLogin,
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildValidatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    required bool isValid,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: controller.text.isEmpty 
              ? Colors.grey[300]! 
              : isValid 
                  ? Colors.green 
                  : Colors.red[300]!,
          width: controller.text.isEmpty ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: label,
                hintText: hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _phoneController.text.length <= 3
              ? Colors.grey[300]!
              : _phoneValid
                  ? Colors.green
                  : Colors.red[300]!,
          width: _phoneController.text.length <= 3 ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.phone, color: Colors.grey[600], size: 20),
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                LengthLimitingTextInputFormatter(13),
                _PhoneInputFormatter(),
              ],
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+91XXXXXXXXXX',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 16,
                ),
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                
                String phone = value.trim();
                
                if (!phone.startsWith('+91') || phone.length != 13) {
                  return 'Phone number must be in +91XXXXXXXXXX format';
                }
                
                String phoneDigits = phone.substring(3);
                if (!RegExp(r'^\d{10}$').hasMatch(phoneDigits)) {
                  return 'Invalid phone number format. Must be 10 digits after +91';
                }
                
                return null;
              },
            ),
          ),
          if (_phoneController.text.length > 3) ...[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                _phoneValid ? Icons.check_circle : Icons.error,
                color: _phoneValid ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Prevent double submission
    if (_isLoading) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      print('=== STARTING SIGNUP PROCESS ===');
      print('Email: ${_emailController.text.trim()}');
      print('Phone: ${_phoneController.text.trim()}');
      print('Name: ${_fullNameController.text.trim()}');
      
      // Attempt actual registration (simplified - no debug calls)
      print('Attempting registration...');
      final userId = await _authService.signUpSimple(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      
      if (!mounted) return;
      
      print('Signup successful, userId: $userId');
      
      if (userId.isNotEmpty) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Welcome to CabShare!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to home immediately
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeShell(api: widget.api),
            ),
          );
        }
      } else {
        setState(() => _error = 'Registration failed. User ID is empty.');
      }
      
    } catch (e) {
      print('=== SIGNUP ERROR ===');
      print('Error: $e');
      
      if (!mounted) return;
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Provide more specific error messages
      if (errorMessage.toLowerCase().contains('connection')) {
        errorMessage = 'Connection error. Please check your internet connection.';
      } else if (errorMessage.toLowerCase().contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      } else if (errorMessage.toLowerCase().contains('already')) {
        errorMessage = 'This email is already registered. Please sign in instead.';
      }
      
      setState(() => _error = errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(api: widget.api),
      ),
    );
  }
}

// Custom formatter for phone input
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Always ensure +91 prefix
    if (!text.startsWith('+91')) {
      if (text.isEmpty || text == '+') {
        return const TextEditingValue(
          text: '+91',
          selection: TextSelection.collapsed(offset: 3),
        );
      } else if (text.startsWith('+9') && text.length >= 2) {
        return const TextEditingValue(
          text: '+91',
          selection: TextSelection.collapsed(offset: 3),
        );
      } else if (text.startsWith('+') && !text.startsWith('+91')) {
        return const TextEditingValue(
          text: '+91',
          selection: TextSelection.collapsed(offset: 3),
        );
      } else {
        // User typed digits without +91, add it
        final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          final newText = '+91$digits';
          return TextEditingValue(
            text: newText.length > 13 ? newText.substring(0, 13) : newText,
            selection: TextSelection.collapsed(offset: newText.length > 13 ? 13 : newText.length),
          );
        }
      }
    }
    
    // Limit to 13 characters (+91XXXXXXXXXX)
    if (text.length > 13) {
      return TextEditingValue(
        text: text.substring(0, 13),
        selection: const TextSelection.collapsed(offset: 13),
      );
    }
    
    return newValue;
  }
}
