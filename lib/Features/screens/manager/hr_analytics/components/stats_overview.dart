import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StatsOverview extends StatefulWidget {
  const StatsOverview({Key? key}) : super(key: key);

  @override
  _StatsOverviewState createState() => _StatsOverviewState();
}

class _StatsOverviewState extends State<StatsOverview> {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();

  int _totalEmployees = 0;
  int _activeEmployees = 0;
  int _avgProductivity = 0;
  int _avgAttendance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatsData();
  }

  Future<void> _fetchStatsData() async {
    try {
      // Get total number of employees
      final usersSnapshot = await _database.child('users').once();
      final totalEmployees = (usersSnapshot.snapshot.value as Map<
          dynamic,
          dynamic>?)?.length ?? 0;

      // Get active employees (those with recent location updates)
      final activeThreshold = DateTime
          .now()
          .subtract(Duration(minutes: 15))
          .millisecondsSinceEpoch;
      final locationsSnapshot = await _database
          .child('employee_locations')
          .once();

      int activeEmployees = 0;
      if (locationsSnapshot.snapshot.value != null) {
        final locationsData = locationsSnapshot.snapshot.value as Map<
            dynamic,
            dynamic>;
        activeEmployees = locationsData.values
            .where((userLocations) =>
            (userLocations as Map<dynamic, dynamic>).values.any(
                    (location) => location['timestamp'] > activeThreshold
            )
        )
            .length;
      }

      // Calculate average productivity (from users collection)
      final usersData = usersSnapshot.snapshot.value as Map<dynamic, dynamic>?;
      int totalProductivity = 0;
      int usersWithProductivity = 0;

      if (usersData != null) {
        usersData.forEach((key, value) {
          if (value['productivity'] != null && value['productivity']
              .toString()
              .isNotEmpty) {
            totalProductivity += int.parse(value['productivity'].toString());
            usersWithProductivity++;
          }
        });
      }
      final avgProductivity = usersWithProductivity > 0
          ? (totalProductivity / usersWithProductivity).round()
          : 0;

      // Calculate average attendance (from attendance collection)
      final now = DateTime.now();
      final currentMonth = DateFormat('yyyy-MM').format(now);
      final attendanceSnapshot = await _database.child('attendance').once();

      int totalAttendance = 0;
      int attendanceRecords = 0;

      if (attendanceSnapshot.snapshot.value != null) {
        final attendanceData = attendanceSnapshot.snapshot.value as Map<dynamic, dynamic>;

        attendanceData.forEach((userId, userAttendance) {
          // Ensure userAttendance is a Map
          if (userAttendance is Map<dynamic, dynamic>) {
            userAttendance.forEach((date, record) {
              // Check if the date is within the current month
              if (date.toString().startsWith(currentMonth)) {
                // Check for attendance status and calculate
                if (record['status'] == 'Present') {
                  totalAttendance += 100; // Count as full attendance
                } else if (record['status'] == 'On Leave') {
                  totalAttendance += 50; // Count as half attendance
                }
                attendanceRecords++; // Increase attendance record count
              }
            });
          }
        });
      }


      final avgAttendance = attendanceRecords > 0
          ? (totalAttendance / attendanceRecords).round()
          : 0;

      setState(() {
        _totalEmployees = totalEmployees;
        _activeEmployees = activeEmployees;
        _avgProductivity = avgProductivity;
        _avgAttendance = avgAttendance;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching stats: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load statistics')),
      );
    }
  }

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

  Widget _buildModernStatItem(String label,
      String value,
      IconData icon,
      Color color, {
        String? badgeValue,
        IconData? trend,
        Color? trendColor,
        double? progressValue,
        bool animate = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              SizedBox(height: 8),
              Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5F6C7D),
                  )),
              SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (animate)
                    TweenAnimationBuilder(
                      tween: IntTween(
                          begin: 0, end: int.parse(value.replaceAll('%', ''))),
                      duration: Duration(milliseconds: 800),
                      builder: (context, dynamic val, child) {
                        return Text(
                          progressValue != null ? '$val%' : val.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        );
                      },
                    )
                  else
                    Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        )),
                  if (trend != null) ...[
                    SizedBox(width: 4),
                    Icon(trend, size: 16, color: trendColor),
                  ],
                ],
              ),
            ],
          ),
          if (badgeValue != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeValue,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          if (progressValue != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFD),
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'Team Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  )),
              IconButton(
                icon: Icon(Icons.refresh, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isLoading = true);
                  _fetchStatsData();
                },
                tooltip: 'Refresh data',
              ),
            ],
          ),
          SizedBox(height: 16),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildModernStatItem(
                'Total Employees',
                _totalEmployees.toString(),
                Icons.people_alt_outlined,
                Color(0xFF3366FF),
                animate: true,
              ),
              _buildModernStatItem(
                'Active Now',
                _activeEmployees.toString(),
                Icons.person_outline,
                Color(0xFF00B8D9),
                badgeValue: _activeEmployees > 0
                    ? '${((_activeEmployees / _totalEmployees) * 100).round()}%'
                    : null,
              ),
              _buildModernStatItem(
                'Avg Productivity',
                '$_avgProductivity%',
                Icons.trending_up_outlined,
                _getPerformanceColor(_avgProductivity),
                trend: _avgProductivity > 75
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                trendColor: _avgProductivity > 75
                    ? Colors.green
                    : Colors.orange,
              ),
              _buildModernStatItem(
                'Avg Attendance',
                '$_avgAttendance%',
                Icons.calendar_today_outlined,
                _getAttendanceColor(_avgAttendance),
                progressValue: _avgAttendance / 100,
              ),
            ],
          ),
          SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // Navigate to detailed analytics page
            },
            child: Text('View Detailed Analytics'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Color(0xFF3366FF)),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}