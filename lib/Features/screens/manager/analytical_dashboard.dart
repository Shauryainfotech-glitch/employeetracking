import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HRAnalyticsScreen extends StatefulWidget {
  @override
  _HRAnalyticsScreenState createState() => _HRAnalyticsScreenState();
}

class _HRAnalyticsScreenState extends State<HRAnalyticsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL:
        'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendanceData = [];
  List<Map<String, dynamic>> _locationData = [];
  bool _isLoading = true;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );
  String _selectedDepartment = 'All';
  String _selectedMetric = 'Attendance';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load employee data
    final employeesSnapshot = await _dbRef.child('users').get();
    if (employeesSnapshot.exists) {
      final employeesMap = employeesSnapshot.value as Map<dynamic, dynamic>;
      _employees = employeesMap.entries.map((entry) {
        return {'uid': entry.key, ...Map<String, dynamic>.from(entry.value)};
      }).toList();
    }

    // Load attendance data with proper date parsing
    final attendanceSnapshot = await _dbRef.child('attendance').get();
    if (attendanceSnapshot.exists) {
      final attendanceMap = attendanceSnapshot.value as Map<dynamic, dynamic>;
      _attendanceData = [];
      attendanceMap.forEach((userId, userData) {
        if (userData is Map) {
          userData.forEach((date, record) {
            DateTime parsedDate;
            try {
              parsedDate = date is String
                  ? DateTime.parse(date)
                  : date.toDate();
            } catch (e) {
              parsedDate = DateTime.now();
            }

            _attendanceData.add({
              'userId': userId,
              'date': parsedDate,
              ...Map<String, dynamic>.from(record),
            });
          });
        }
      });
    }

    // Load location data with proper timestamp parsing
    final locationSnapshot = await _dbRef.child('employee_locations').get();
    if (locationSnapshot.exists) {
      final locationMap = locationSnapshot.value as Map<dynamic, dynamic>;
      _locationData = [];
      locationMap.forEach((userId, locations) {
        if (locations is Map) {
          locations.forEach((timestamp, location) {
            DateTime parsedTimestamp;
            try {
              // Handle both string and numeric timestamps
              if (timestamp is String) {
                parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
                  int.parse(timestamp),
                );
              } else if (timestamp is int) {
                parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
                  timestamp,
                );
              } else {
                parsedTimestamp = DateTime.now();
              }
            } catch (e) {
              parsedTimestamp = DateTime.now();
            }

            _locationData.add({
              'userId': userId,
              'timestamp': parsedTimestamp,
              ...Map<String, dynamic>.from(location),
            });
          });
        }
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null && picked != _dateRange) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'HR Analytics Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    // Get unique departments from employees, handling null cases
    final departments = _employees
        .map((e) => e['department']?.toString() ?? 'Unknown')
        .toSet()
        .toList();
    departments.insert(0, 'All');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ToggleButtons(
              borderRadius: BorderRadius.circular(12),
              isSelected: [
                _selectedMetric == 'Attendance',
                _selectedMetric == 'Location',
                _selectedMetric == 'Productivity',
              ],
              onPressed: (int index) {
                setState(() {
                  _selectedMetric = [
                    'Attendance',
                    'Location',
                    'Productivity',
                  ][index];
                });
              },
              selectedColor: Colors.white,
              fillColor: Colors.indigoAccent,
              color: Colors.black.withOpacity(0.6),
              constraints: BoxConstraints(
                minHeight: 58,
                minWidth: (constraints.maxWidth - 32) / 3,
                // Account for padding
                maxWidth:
                    (constraints.maxWidth - 32) /
                    3, // Equal width for all buttons
              ),
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 18),
                      SizedBox(width: 4),
                      Text('Attendance'),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 18),
                      SizedBox(width: 4),
                      Text('Location'),
                    ],
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work, size: 18),
                      SizedBox(width: 4),
                      Text('Productivity'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final filteredEmployees = _selectedDepartment == 'All'
        ? _employees
        : _employees
              .where((e) => e['department'] == _selectedDepartment)
              .toList();

    final stats = _calculateAttendanceStats(filteredEmployees);

    // Provide default values for null cases
    final presentDays = stats['presentDays'] ?? 0;
    final leaveDays = stats['leaveDays'] ?? 0;
    final absentDays = stats['absentDays'] ?? 0;
    final totalDays = stats['totalDays'] ?? 1; // Avoid division by zero

    return Padding(
      padding: const EdgeInsets.all(16),

      child: SizedBox(
        height: 150,

        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (context, index) =>
              const SizedBox(width: 16, height: 200),
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return _buildModernSummaryCard(
                  title: 'Employees',
                  value: filteredEmployees.length,
                  icon: Icons.people_rounded,
                  color: Colors.blueAccent,
                  percentage: null,
                );
              case 1:
                return _buildModernSummaryCard(
                  title: 'Present',
                  value: presentDays,
                  icon: Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  percentage: (presentDays / totalDays) * 100,
                );
              case 2:
                return _buildModernSummaryCard(
                  title: 'On Leave',
                  value: leaveDays,
                  icon: Icons.beach_access_rounded,
                  color: Colors.orangeAccent,
                  percentage: (leaveDays / totalDays) * 100,
                );
              case 3:
                return _buildModernSummaryCard(
                  title: 'Absent',
                  value: absentDays,
                  icon: Icons.warning_rounded,
                  color: Colors.redAccent,
                  percentage: (absentDays / totalDays) * 100,
                );
              default:
                return Container();
            }
          },
        ),
      ),
    );
  }

  Widget _buildModernSummaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required double? percentage,
  }) {
    return GestureDetector(
      onTap: () {
        // Add interaction feedback
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (percentage != null)
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (percentage != null)
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _calculateAttendanceStats(
    List<Map<String, dynamic>> employees,
  ) {
    final filteredAttendance = _attendanceData.where((a) {
      DateTime recordDate;
      try {
        recordDate = a['date'] is String
            ? DateTime.parse(a['date'])
            : a['date'] as DateTime;
      } catch (e) {
        recordDate = DateTime.now();
      }

      final isInDateRange =
          recordDate.isAfter(_dateRange.start) &&
          recordDate.isBefore(_dateRange.end.add(const Duration(days: 1)));

      if (!isInDateRange) return false;
      if (_selectedDepartment == 'All') return true;

      final employee = _employees.firstWhere(
        (e) => e['uid'] == a['userId'],
        orElse: () => {'department': ''},
      );
      return employee['department'] == _selectedDepartment;
    }).toList();

    return {
      'presentDays': filteredAttendance
          .where((a) => a['status'] == 'Present')
          .length,
      'leaveDays': filteredAttendance
          .where((a) => a['status'] == 'On Leave')
          .length,
      'absentDays': filteredAttendance
          .where((a) => a['status'] == 'Absent')
          .length,
      'totalDays': employees.length * _dateRange.duration.inDays,
    };
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    required int totalDays,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  Spacer(),
                  if (title == 'Present' ||
                      title == 'On Leave' ||
                      title == 'Absent')
                    Text(
                      '${totalDays > 0 ? ((int.parse(value) / totalDays) * 100).toStringAsFixed(1) : '0'}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart() {
    if (_selectedMetric == 'Attendance') {
      return _buildAttendanceChart();
    } else if (_selectedMetric == 'Location') {
      return _buildLocationChart();
    } else {
      return _buildProductivityChart();
    }
  }

  Widget _buildAttendanceChart() {
    // Group attendance by date
    final attendanceByDate = <DateTime, Map<String, int>>{};
    for (var record in _attendanceData) {
      DateTime recordDate;
      try {
        recordDate = record['date'] is String
            ? DateTime.parse(record['date'])
            : record['date'];
      } catch (e) {
        recordDate = DateTime.now(); // Fallback if parsing fails
      }

      if (recordDate.isAfter(_dateRange.start) &&
          recordDate.isBefore(_dateRange.end.add(Duration(days: 1)))) {
        final dateKey = DateTime(
          recordDate.year,
          recordDate.month,
          recordDate.day,
        );
        attendanceByDate.putIfAbsent(
          dateKey,
          () => {'Present': 0, 'On Leave': 0, 'Absent': 0},
        );

        final status = record['status'] as String? ?? 'Unknown';
        if (attendanceByDate[dateKey]!.containsKey(status)) {
          attendanceByDate[dateKey]![status] =
              attendanceByDate[dateKey]![status]! + 1;
        }
      }
    }

    // Convert to chart data
    final chartData = attendanceByDate.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key.day,
        barRods: [
          BarChartRodData(
            toY: (entry.value['Present'] ?? 0).toDouble(),
            color: Colors.indigoAccent,
          ),
          BarChartRodData(
            toY: (entry.value['On Leave'] ?? 0).toDouble(),
            color: Colors.orange,
          ),
          BarChartRodData(
            toY: (entry.value['Absent'] ?? 0).toDouble(),
            color: Colors.red,
          ),
        ],
      );
    }).toList();

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Trend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime(
                            _dateRange.start.year,
                            _dateRange.start.month,
                            value.toInt(),
                          );
                          return Text(DateFormat('d').format(date));
                        },
                      ),
                    ),
                  ),
                  barGroups: chartData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationChart() {
    // Group location data by employee
    final locationByEmployee = <String, int>{};
    for (var record in _locationData) {
      DateTime recordTime;
      try {
        recordTime = record['timestamp'] is String
            ? DateTime.parse(record['timestamp'])
            : record['timestamp'] is int
            ? DateTime.fromMillisecondsSinceEpoch(record['timestamp'])
            : record['timestamp'] as DateTime;
      } catch (e) {
        recordTime = DateTime.now();
      }

      if (recordTime.isAfter(_dateRange.start) &&
          recordTime.isBefore(_dateRange.end.add(Duration(days: 1)))) {
        locationByEmployee.update(
          record['userId'],
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    // Convert to chart data
    final chartData = locationByEmployee.entries.map((entry) {
      final employee = _employees.firstWhere(
        (e) => e['uid'] == entry.key,
        orElse: () => {'name': 'Unknown'},
      );
      return {'name': employee['name'], 'count': entry.value};
    }).toList()..sort((a, b) => b['count'].compareTo(a['count']));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Updates by Employee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < chartData.length &&
                              index % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                chartData[index]['name']
                                    .toString()
                                    .split(' ')
                                    .first,
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  barGroups: chartData.take(10).map((data) {
                    final index = chartData.indexOf(data);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['count'].toDouble(),
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityChart() {
    // Calculate average working hours per employee
    final productivityByEmployee = <String, double>{};
    for (var record in _attendanceData) {
      // Parse the date properly
      DateTime recordDate;
      try {
        recordDate = record['date'] is String
            ? DateTime.parse(record['date'])
            : record['date'];
      } catch (e) {
        recordDate = DateTime.now(); // Fallback if parsing fails
      }

      // Only process records within the selected date range
      if (recordDate.isAfter(_dateRange.start) &&
          recordDate.isBefore(_dateRange.end.add(Duration(days: 1)))) {
        if (record['workingHours'] != null) {
          productivityByEmployee.update(
            record['userId'],
            (value) => value + (record['workingHours'] ?? 0),
            ifAbsent: () => record['workingHours'] ?? 0,
          );
        }
      }
    }

    // Convert to chart data
    final chartData = productivityByEmployee.entries.map((entry) {
      final employee = _employees.firstWhere(
        (e) => e['uid'] == entry.key,
        orElse: () => {'name': 'Unknown', 'department': ''},
      );
      return {
        'name': employee['name'],
        'department': employee['department'],
        'hours': entry.value,
      };
    }).toList()..sort((a, b) => b['hours'].compareTo(a['hours']));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity by Employee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 &&
                              index < chartData.length &&
                              index % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                chartData[index]['name']
                                    .toString()
                                    .split(' ')
                                    .first,
                                style: TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  barGroups: chartData.take(10).map((data) {
                    final index = chartData.indexOf(data);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['hours'].toDouble(),
                          color: Colors.purple,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(300), // Fixed height
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigoAccent, Colors.indigoAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important for proper sizing
              children: [
                // Top row with logo and icons
                SizedBox(
                  height: 48, // Fixed height for top row
                  child: Row(
                    children: [
                      // App Logo/Title
                      Icon(Icons.analytics, size: 28, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        // Makes title flexible
                        child: Text(
                          'HR Insights',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Spacer(),

                      // Notification Icon with Badge
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Notifications clicked'),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // User Profile Dropdown
                      PopupMenuButton<String>(
                        icon: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        onSelected: (String result) {
                          switch (result) {
                            case 'profile':
                              Navigator.pushNamed(context, '/profile');
                              break;
                            case 'settings':
                              Navigator.pushNamed(context, '/settings');
                              break;
                            case 'logout':
                              // Handle logout
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('My Profile'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Settings'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                ),

                // Search Bar
                SizedBox(height: 8),
                Container(
                  height: 40,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    onChanged: (value) {
                      // Handle search
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilters(),
                  _buildSummaryCards(),
                  SizedBox(height: 16),
                  _buildMainChart(),
                ],
              ),
            ),
    );
  }
}
