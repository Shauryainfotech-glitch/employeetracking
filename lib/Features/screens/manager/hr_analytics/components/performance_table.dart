import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';

class PerformanceTable extends StatelessWidget {
  final List<Employee> employees;
  final Function(String, Employee) onEmployeeAction;

  const PerformanceTable({
    Key? key,
    required this.employees,
    required this.onEmployeeAction,
  }) : super(key: key);

  Color _getPerformanceColor(int performance) {
    if (performance >= 90) return Color(0xFF00A76F);
    if (performance >= 75) return Color(0xFF3366FF);
    if (performance >= 50) return Color(0xFFFFAB00);
    return Color(0xFFFF5630);
  }

  Color _getAttendanceColor(int attendance) {
    if (attendance >= 95) return Color(0xFF00A76F);
    if (attendance >= 85) return Color(0xFF3366FF);
    if (attendance >= 70) return Color(0xFFFFAB00);
    return Color(0xFFFF5630);
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting data for ${employees.length} employees')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () => _exportData(context),
                  tooltip: 'Export Data',
                ),
              ],
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: [
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('Productivity'), numeric: true),
                  DataColumn(label: Text('Attendance'), numeric: true),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Last Active')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: employees.map((employee) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: employee.isActive ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(employee.name),
                          ],
                        ),
                      ),
                      DataCell(Text(employee.department)),
                      DataCell(Text(employee.position)),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPerformanceColor(employee.productivity)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${employee.productivity}%',
                            style: TextStyle(
                              color: _getPerformanceColor(employee.productivity),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getAttendanceColor(employee.attendance)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${employee.attendance}%',
                            style: TextStyle(
                              color: _getAttendanceColor(employee.attendance),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          employee.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: employee.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      DataCell(Text(DateFormat('MMM d, h:mm a').format(employee.lastActive))),
                      DataCell(
                        PopupMenuButton(
                          icon: Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: Text('View Profile'),
                              value: 'profile',
                            ),
                            PopupMenuItem(
                              child: Text('Edit'),
                              value: 'edit',
                            ),
                            PopupMenuItem(
                              child: Text('Send Message'),
                              value: 'message',
                            ),
                          ],
                          onSelected: (value) => onEmployeeAction(value, employee),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}