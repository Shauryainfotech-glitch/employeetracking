import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:employee/Features/auth/register.dart';
import '../../core/models/user_model.dart';
import '../../core/provider/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/manager/hr_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  late final DatabaseReference _database;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingAuth = true;
  String _email = '';
  String _password = '';
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _checkAuthState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final snapshot = await _database.child('users/${currentUser.uid}').get();
        if (snapshot.exists) {
          final role = snapshot.child('role').value.toString();
          await Future.delayed(Duration(milliseconds: 1000));
          _redirectBasedOnRole(role);
          return;
        }
      }
    } catch (e) {
      print('Error checking auth state: $e');
    }

    if (mounted) {
      setState(() => _isCheckingAuth = false);
    }
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );

      final snapshot = await _database.child('users/${userCredential.user!.uid}').get();

      if (snapshot.exists) {
        final userMap = Map<String, dynamic>.from(snapshot.value as Map<Object?, Object?>);  // Safely cast
        final user = UserModel.fromJson(userMap);
        ref.read(userProvider.notifier).setUser(user);  // Update global user context
        _redirectBasedOnRole(user.role);
      }

      if (snapshot.exists) {
        final role = snapshot.child('role').value.toString();
        _redirectBasedOnRole(role);
      } else {
        _showCustomAlert(
          title: 'Error',
          message: 'User data not found',
          isSuccess: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Invalid email or password';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Try again later.';
      }

      _showCustomAlert(
        title: 'Login Failed',
        message: errorMessage,
        isSuccess: false,
      );

      print(errorMessage);
    } catch (e) {
      _showCustomAlert(
        title: 'Error',
        message: 'An unexpected error occurred',
        isSuccess: false,
      );
      print(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _redirectBasedOnRole(String role) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) {
        switch (role) {
          case 'Admin':
            return AdminDashboard();
          case 'HR/Manager':
            return HRDashboard();
          case 'Employee':
          default:
            return EmployeeDashboard();
        }
      }),
          (Route<dynamic> route) => false,
    );
  }

  void _showCustomAlert({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
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
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
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
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Color(0xFFF8FAFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Smart Employee',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2575FC),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: Color(0xFF6A11CB),
              ),
            ],
          ),
        ),
      );
    }

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
                          Icons.work_outline,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sign in to access your dashboard',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

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
                  onChanged: (value) => _email = value,
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
                  onChanged: (value) => _password = value,
                ),
                SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF4299E1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Login Button
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
                    onPressed: _isLoading ? null : _loginUser,
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
                      'Login',
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
                        'New to our platform?',
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

                // Register Button
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
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrationScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Create Account',
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

  Future<void> _resetPassword() async {
    if (_email.isEmpty || !_email.contains('@')) {
      _showCustomAlert(
        title: 'Error',
        message: 'Please enter a valid email address',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: _email);
      _showCustomAlert(
        title: 'Email Sent',
        message: 'Password reset link sent to $_email',
        isSuccess: true,
      );
    } catch (e) {
      _showCustomAlert(
        title: 'Error',
        message: 'Failed to send reset email',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
    required void Function(String) onChanged,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
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
}
