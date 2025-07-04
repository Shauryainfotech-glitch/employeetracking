import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  bool _isEditing = false;

  // User data
  String _name = '';
  String _email = '';
  String _phone = '';
  String _department = '';
  String _position = '';
  String _joinDate = '';

  // Stats
  int _totalAttendance = 0;
  int _lateDays = 0;
  double _avgWorkingHours = 0.0;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    final userSnapshot = await dbRef.child('users/${_user!.uid}').get();
    final attendanceSnapshot = await dbRef.child('attendance/${_user!.uid}').get();

    if (userSnapshot.exists) {
      final userData = userSnapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _name = userData['name'] ?? 'No Name';
        _email = _user!.email ?? 'No Email';
        _phone = userData['phone'] ?? 'No Phone';
        _department = userData['department'] ?? 'No Department';
        _position = userData['position'] ?? 'Employee';
        _joinDate = userData['joinDate'] ?? 'Not Available';

        _nameController.text = _name;
        _phoneController.text = _phone;
        _departmentController.text = _department;
        _positionController.text = _position;
      });
    }

    if (attendanceSnapshot.exists) {
      final attendanceData = attendanceSnapshot.value as Map<dynamic, dynamic>;
      int presentDays = 0;
      int lateDays = 0;
      double totalHours = 0;

      attendanceData.forEach((date, record) {
        if (record['status'] == 'Present') presentDays++;
        if (record['status'] == 'Late') lateDays++;
        if (record['checkIn'] != null && record['checkOut'] != null) {
          // Calculate working hours
          final checkIn = record['checkIn'].toString().split(':');
          final checkOut = record['checkOut'].toString().split(':');
          final inTime = TimeOfDay(hour: int.parse(checkIn[0]), minute: int.parse(checkIn[1]));
          final outTime = TimeOfDay(hour: int.parse(checkOut[0]), minute: int.parse(checkOut[1]));
          final hours = (outTime.hour - inTime.hour) + (outTime.minute - inTime.minute) / 60;
          totalHours += hours;
        }
      });

      setState(() {
        _totalAttendance = presentDays;
        _lateDays = lateDays;
        _avgWorkingHours = presentDays > 0 ? totalHours / presentDays : 0.0;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate() && _user != null) {
      setState(() => _isEditing = false);

      await dbRef.child('users/${_user!.uid}').update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'department': _departmentController.text,
        'position': _positionController.text,
      });

      setState(() {
        _name = _nameController.text;
        _phone = _phoneController.text;
        _department = _departmentController.text;
        _position = _positionController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Here you would typically upload the image to Firebase Storage
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {bool isPhone = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Header with profile picture
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.deepPurpleAccent[700]!, Colors.deepPurpleAccent[400]!],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _pickImage : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (_user?.photoURL != null
                                    ? NetworkImage(_user!.photoURL!)
                                    : null),
                                child: _profileImage == null && _user?.photoURL == null
                                    ? Icon(Icons.person, size: 50, color: Colors.blue)
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.edit, size: 18, color: Colors.blue),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _position,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.edit,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = !_isEditing;
                          if (!_isEditing) {
                            // Reset controllers if editing is cancelled
                            _nameController.text = _name;
                            _phoneController.text = _phone;
                            _departmentController.text = _department;
                            _positionController.text = _position;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: EdgeInsets.all(16),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard(
                    'Attendance',
                    '$_totalAttendance',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Late Days',
                    '$_lateDays',
                    Icons.alarm,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Avg Hours',
                    '${_avgWorkingHours.toStringAsFixed(1)}h',
                    Icons.access_time,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Since',
                    _joinDate,
                    Icons.event,
                    Colors.purple,
                  ),
                ],
              ),
            ),

            // Profile Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Non-editable email field
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _email,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Editable fields
                    _buildEditableField('Full Name', _nameController),
                    _buildEditableField('Phone Number', _phoneController, isPhone: true),
                    _buildEditableField('Department', _departmentController),
                    _buildEditableField('Position', _positionController),

                    if (_isEditing) ...[
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _updateProfile,
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
