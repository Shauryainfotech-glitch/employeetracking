import 'package:employee/Features/screens/manager/analytical_dashboard.dart';
import 'package:employee/Features/screens/manager/profile.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_tracker.dart';
import 'manage_employee.dart';
import 'notifications.dart';

class HRDashboard extends StatefulWidget {
  @override
  _HRDashboardState createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  int _currentIndex = 0;
  final List<Employee> _employees = [
    Employee(
      id: '1',
      name: 'John Doe',
      position: 'Android Developer',
      productivity: 85,
      attendance: 92,
      lastActive: DateTime.now().subtract(Duration(minutes: 15)),
      isActive: true,
      location: LatLng(37.42796133580664, -122.085749655962),
    ),
    Employee(
      id: '2',
      name: 'Jane Smith',
      position: 'UI/UX Designer',
      productivity: 78,
      attendance: 88,
      lastActive: DateTime.now().subtract(Duration(hours: 2)),
      isActive: false,
      location: LatLng(37.42196133580664, -122.083749655962),
    ),
    Employee(
      id: '3',
      name: 'Mike Johnson',
      position: 'Data Scientist',
      productivity: 92,
      attendance: 95,
      lastActive: DateTime.now().subtract(Duration(minutes: 45)),
      isActive: true,
      location: LatLng(37.42496133580664, -122.081749655962),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      body: _getBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0: return HRAnalyticsScreen();
      case 1: return EmployeeManagementScreen();
      case 2: return EmployeeLocationTracker();
      case 3: return NotificationPage();
      case 4: return ProfilePage();
      default: return HRAnalyticsScreen();
    }
  }


  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(employee.name[0]),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        employee.position,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  employee.isActive ? Icons.circle : Icons.circle_outlined,
                  color: employee.isActive ? Colors.green : Colors.grey,
                  size: 12,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Productivity', '${employee.productivity}%'),
                _buildStatItem('Attendance', '${employee.attendance}%'),
                _buildStatItem(
                  'Last Active',
                  employee.lastActive.hour > 12
                      ? '${employee.lastActive.hour - 12}:${employee.lastActive.minute} PM'
                      : '${employee.lastActive.hour}:${employee.lastActive.minute} AM',
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEmployeeActions(employee),
                    child: Text('Actions'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _viewEmployeeDetails(employee),
                    child: Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue[800],
      unselectedItemColor: Colors.grey[600],
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Employees',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Location',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  void _showEmployeeActions(Employee employee) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Employee Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit Details'),
              onTap: () {
                Navigator.pop(context);
                // Edit employee
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.orange),
              title: Text(employee.isActive ? 'Block Employee' : 'Unblock Employee'),
              onTap: () {
                setState(() {
                  employee.isActive = !employee.isActive;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Employee'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(employee);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete employee
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${employee.name} deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _viewEmployeeDetails(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(employee.name)),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      employee.name[0],
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    employee.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    employee.position,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                _buildDetailItem('Employee ID', employee.id),
                _buildDetailItem('Email', '${employee.name.toLowerCase().replaceAll(' ', '.')}@company.com'),
                _buildDetailItem('Phone', '+1 555-123-4567'),
                _buildDetailItem('Status', employee.isActive ? 'Active' : 'Inactive'),
                SizedBox(height: 20),
                Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard('Productivity', '${employee.productivity}%'),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard('Attendance', '${employee.attendance}%'),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String position;
  final int productivity;
  final int attendance;
  final DateTime lastActive;
  bool isActive;
  final LatLng location;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.productivity,
    required this.attendance,
    required this.lastActive,
    required this.isActive,
    required this.location,
  });
}