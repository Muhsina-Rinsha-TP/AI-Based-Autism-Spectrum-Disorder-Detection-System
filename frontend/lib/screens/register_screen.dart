import 'dart:convert';
import 'package:autism_project/controller/provider_auth/auth_provider.dart';
import 'package:autism_project/screens/homescreen.dart';
import 'package:autism_project/screens/login_screen.dart';
import 'package:autism_project/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

  String _selectedRole = 'user';
  String? _selectedDepartment;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _departments = [
    'Pediatric Neurologist',
    'Child Psychologist',
    'Developmental Pediatrician',
    'Behavioral Therapist',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Test connection on init
    // _testConnection();
  }

  // Future<void> _testConnection() async {
  //   final isConnected = await ApiService.testConnection();
  //   if (!isConnected && mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: const Text('⚠️ Cannot connect to server. Please check your connection.'),
  //         backgroundColor: Colors.orange,
  //         behavior: SnackBarBehavior.floating,
  //       ),
  //     );
  //   }
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _experienceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check terms agreement
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to Terms & Conditions'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set selected role in provider
    ref.read(authProvider.notifier).setSelectedRole(_selectedRole);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );

    try {
      // Call register method
      final success = await ref.read(authProvider.notifier).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
        department: _selectedRole == 'doctor' ? _selectedDepartment : null,
        experienceYears: _selectedRole == 'doctor' && _experienceController.text.isNotEmpty
            ? int.tryParse(_experienceController.text)
            : null,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Check result
      final authState = ref.read(authProvider);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Registration successful! Welcome ${_nameController.text.trim()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to home screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      } else if (!success && mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${authState.error ?? 'Registration failed'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF88B0D3),
              Color(0xFF6B5B95),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? 400 : 450,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Section
                          _buildLogo(isSmallScreen),
                          const SizedBox(height: 30),

                          // Welcome Text
                          Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join our community of care',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Register Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Role Selection
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text(
                                            'User',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                          value: 'user',
                                          groupValue: _selectedRole,
                                          activeColor: const Color(0xFF6B5B95),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedRole = value!;
                                              // Reset doctor fields when switching
                                              _selectedDepartment = null;
                                              _experienceController.clear();
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: Text(
                                            'Doctor',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                          value: 'doctor',
                                          groupValue: _selectedRole,
                                          activeColor: const Color(0xFF6B5B95),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedRole = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Name Field
                                _buildTextField(
                                  controller: _nameController,
                                  hint: 'Full Name',
                                  icon: Icons.person_outline,
                                  isSmallScreen: isSmallScreen,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                // Email Field
                                _buildTextField(
                                  controller: _emailController,
                                  hint: 'Email',
                                  icon: Icons.email_outlined,
                                  isSmallScreen: isSmallScreen,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Invalid email format';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                // Phone Field
                                _buildTextField(
                                  controller: _phoneController,
                                  hint: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  isSmallScreen: isSmallScreen,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Phone number is required';
                                    }
                                    if (value.length < 10) {
                                      return 'Enter valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                // Doctor-specific fields
                                if (_selectedRole == 'doctor') ...[
                                  // Department Dropdown
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedDepartment,
                                      hint: Text(
                                        'Select Department',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: const Color(0xFF6B5B95),
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.business_center_outlined,
                                          color: const Color(0xFF6B5B95),
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      items: _departments.map((department) {
                                        return DropdownMenuItem<String>(
                                          value: department,
                                          child: Text(
                                            department,
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDepartment = value;
                                        });
                                      },
                                      validator: (value) {
                                        if (_selectedRole == 'doctor' && (value == null || value.isEmpty)) {
                                          return 'Please select department';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Experience Years
                                  _buildTextField(
                                    controller: _experienceController,
                                    hint: 'Years of Experience',
                                    icon: Icons.timeline_outlined,
                                    isSmallScreen: isSmallScreen,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_selectedRole == 'doctor') {
                                        if (value == null || value.isEmpty) {
                                          return 'Experience years required';
                                        }
                                        final years = int.tryParse(value);
                                        if (years == null || years < 0) {
                                          return 'Enter valid years';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                ],

                                // Password Field
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_outline,
                                  isSmallScreen: isSmallScreen,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6B5B95),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                // Confirm Password Field
                                _buildTextField(
                                  controller: _confirmController,
                                  hint: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  isSmallScreen: isSmallScreen,
                                  obscureText: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6B5B95),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirm = !_obscureConfirm;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 10),

                                // Terms and Conditions
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF6B5B95),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        children: [
                                          Text(
                                            'I agree to the ',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: isSmallScreen ? 12 : 13,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _showTermsDialog();
                                            },
                                            child: Text(
                                              'Terms of Service',
                                              style: TextStyle(
                                                color: const Color(0xFF6B5B95),
                                                fontWeight: FontWeight.w600,
                                                fontSize: isSmallScreen ? 12 : 13,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ' and ',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: isSmallScreen ? 12 : 13,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              _showPrivacyDialog();
                                            },
                                            child: Text(
                                              'Privacy Policy',
                                              style: TextStyle(
                                                color: const Color(0xFF6B5B95),
                                                fontWeight: FontWeight.w600,
                                                fontSize: isSmallScreen ? 12 : 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmallScreen ? 50 : 55,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B5B95),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                      disabledBackgroundColor: Colors.grey.shade400,
                                    ),
                                    child: authState.isLoading
                                        ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Creating Account...',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                          ),
                                        ),
                                      ],
                                    )
                                        : Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),

                                // Autism Support Message
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F4FF),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: const Color(0xFF6B5B95).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Color(0xFF6B5B95),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Join thousands of parents in early autism detection and support',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text(
          'By using this app, you agree to our terms and conditions. '
              'This app is designed to provide information and support for '
              'early autism detection and should not replace professional medical advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'We respect your privacy. Your personal information will be '
              'kept confidential and used only for providing our services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 90 : 110,
      height: isSmallScreen ? 90 : 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: isSmallScreen ? 45 : 55,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isSmallScreen,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF6B5B95),
            size: isSmallScreen ? 20 : 24,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isSmallScreen ? 15 : 18,
          ),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}