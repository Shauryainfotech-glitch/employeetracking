import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';

import 'login.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _database;

  bool _isLoading = false;
  bool _obscurePassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();

  String _role = 'Employee';
  String _department = 'Engineering';

  final List<String> _roles = ['Employee', 'HR/Manager'];
  final List<String> _departments = [
    'Engineering',
    'Marketing',
    'Sales',
    'Human Resources',
    'Finance',
    'Operations',
    'IT',
    'Design'
  ];

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _database.child('users/${userCredential.user!.uid}').set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _role,
        'department': _department,
        'attendance': '',
        'productivity': '',
        'location' : '',
        'createdAt': ServerValue.timestamp,
      });

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showErrorToast('An unexpected error occurred. Please try again.');
      if (kDebugMode) print('Registration error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage = 'An error occurred. Please try again.';
    switch (e.code) {
      case 'weak-password': errorMessage = 'Password must be at least 6 characters'; break;
      case 'email-already-in-use': errorMessage = 'Email already in use'; break;
      case 'invalid-email': errorMessage = 'Invalid email address'; break;
      case 'operation-not-allowed': errorMessage = 'Email/password accounts not enabled'; break;
    }
    _showErrorToast(errorMessage);
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your account has been successfully created.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4299E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                child: Text(
                  'Continue to Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),

                // App Logo/Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Join our team today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Name Field
                Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                _buildTextField(
                  hintText: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                  onChanged: (value) => _nameController.text = value,
                ),
                SizedBox(height: 20),

                // Email Field
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                _buildTextField(
                  hintText: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) => _emailController.text = value,
                ),
                SizedBox(height: 20),

                // Password Field
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                _buildTextField(
                  hintText: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Color(0xFFA0AEC0),
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (value) => _passwordController.text = value,
                ),
                SizedBox(height: 20),

                // Mobile Field
                Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                _buildTextField(
                  hintText: 'Enter your mobile number',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter mobile number';
                    if (value.length < 10) return 'Please enter valid mobile number';
                    return null;
                  },
                  onChanged: (value) => _mobileController.text = value,
                ),
                SizedBox(height: 20),

                // Role Dropdown
                Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                _buildDropdown(
                  value: _role,
                  items: _roles,
                  onChanged: (value) => setState(() => _role = value!),
                ),
                SizedBox(height: 20),

                // Department Dropdown
                Text(
                  'Department',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                _buildDropdown(
                  value: _department,
                  items: _departments,
                  onChanged: (value) => setState(() => _department = value!),
                ),
                SizedBox(height: 24),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4299E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: _isLoading ? null : _registerUser,
                    child: _isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),
                SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF4299E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4299E1),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    required String? Function(String?) validator,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: Color(0xFF2D3748)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
        prefixIcon: Icon(icon, color: Color(0xFFA0AEC0)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4299E1), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
        color: Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Color(0xFFA0AEC0)),
        style: TextStyle(color: Color(0xFF2D3748), fontSize: 16),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}