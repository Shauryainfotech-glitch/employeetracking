import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';

class EmployeeProfile extends StatelessWidget {
  final Employee employee;
  final Function() onClose;

  const EmployeeProfile({
    Key? key,
    required this.employee,
    required this.onClose,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employee Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          Divider(),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              child: Text(
                employee.name[0],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              employee.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              employee.position,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 24),
          _buildProfileDetailItem(Icons.business, 'Department', employee.department),
          _buildProfileDetailItem(Icons.work, 'Position', employee.position),
          _buildProfileDetailItem(Icons.trending_up, 'Productivity', '${employee.productivity}%'),
          _buildProfileDetailItem(Icons.calendar_today, 'Attendance', '${employee.attendance}%'),
          _buildProfileDetailItem(Icons.event, 'Join Date', DateFormat('MMM d, y').format(employee.joinDate)),
          SizedBox(height: 16),
          Text(
            'Skills',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: employee.skills
                .map((skill) => Chip(
              label: Text(skill),
              backgroundColor: Colors.blue[50],
            ))
                .toList(),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {},
            child: Text('View Full Profile'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}