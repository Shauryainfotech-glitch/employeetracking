import 'package:employee/Features/auth/login.dart';
import 'package:employee/Features/auth/register.dart';
import 'package:employee/Features/screens/employee/employee_attendance.dart';
import 'package:employee/Features/screens/employee/widgets/employee_appdrawer.dart';
import 'package:employee/Features/screens/manager/notifications.dart';
import 'package:employee/Features/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/provider/user_provider.dart';
import 'employee_location.dart';
import 'employee_settings.dart';
import 'employee_team.dart';


void main() {
  ProviderScope(
    child: MyApp(),
  );
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Color(0xFFF8FAFD),
      ),
      home: LoginScreen(),  // This is the correct way to specify home
   );
  }
}

class EmployeeDashboard extends StatefulWidget {
  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();



  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isDarkMode = false;

  final List<Widget> _pages = [
    DashboardPage(),
    TrackingPage(),
    AttendancePage(),
    AttendanceCalendarPage(),
    // SettingsPage(),
    ProfileScreen(),
  ];

  final Color primaryColor = Color(0xFF6C7EE1);
  final Color backgroundColor = Colors.white;

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Logout",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                // Implement your logout logic here
                Navigator.of(context).pop();
                _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ModernEmployeeDrawer(),
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      // floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _getAppBarTitle(),
        style: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      backgroundColor: _isDarkMode ? Colors.grey[900] : primaryColor,
      elevation: 1,
      shadowColor: _isDarkMode ? Colors.black54 : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(10),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.menu,
          color: _isDarkMode ? Colors.white : Colors.white,
          size: 26,
        ),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        // Notification Badge with Counter
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined,
                color: _isDarkMode ? Colors.white : Colors.white,
                size: 26,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                      (Route<dynamic> route) => false,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '3', // Replace with actual notification count
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),

        // Theme Toggle Button
        Tooltip(
          message: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          child: IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _isDarkMode ? Colors.white : Colors.white,
              size: 26,
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ),

        // Logout Button with Confirmation
        Tooltip(
          message: 'Logout',
          child: IconButton(
            icon: Icon(
              Icons.logout,
              color: _isDarkMode ? Colors.white : Colors.white,
              size: 24,
            ),
            onPressed: () {
              _showLogoutConfirmation();
            },
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Location Tracking';
      case 2: return 'Team';
      case 3: return 'Profile';
      default: return 'Employee Portal';
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _pageController.jumpToPage(index);
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF02d39a),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Tracking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Check',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_outlined),
              activeIcon: Icon(Icons.check),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Color(0xFF2a3c4f),
      child: Icon(Icons.qr_code_scanner, color: Colors.white),
      onPressed: () {
        // QR code scanning for attendance
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            SizedBox(height: 20),
            _buildAttendanceCard(),
            SizedBox(height: 20),
            _buildStatsRow(),
            SizedBox(height: 20),
            _buildWeeklyHoursChart(),
            SizedBox(height: 20),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Consumer(
      builder: (context, ref, child) {
        // Access the user data from the provider
        final userData = ref.watch(userProvider);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: userData?.name != null && userData!.name!.isNotEmpty
                      ? Text(
                    userData!.name![0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : Icon(Icons.person, size: 30, color: Colors.blue[800]),
                ),

                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: TextStyle(color: Colors.grey)),
                      Text(
                        userData?.name ?? 'Employee',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            userData?.role ?? 'Employee',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFe3f9f3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF02d39a)),
                      SizedBox(width: 4),
                      Text('Present', style: TextStyle(color: Color(0xFF02d39a))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceCard() {
    final User? user = FirebaseAuth.instance.currentUser;
    final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref();

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.child('attendance/${user?.uid}').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || user == null) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Calculate monthly attendance stats
        final now = DateTime.now();
        final currentMonth = DateFormat('yyyy-MM').format(now);
        int present = 0, absent = 0, late = 0, leave = 0;
        int totalWorkingDays = 0;

        if (snapshot.data!.snapshot.value != null) {
          final attendanceData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Count days in current month (excluding weekends)
          final firstDay = DateTime(now.year, now.month, 1);
          final lastDay = DateTime(now.year, now.month + 1, 0);
          for (var day = firstDay; day.isBefore(lastDay.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
            if (day.weekday >= DateTime.monday && day.weekday <= DateTime.friday) {
              totalWorkingDays++;
            }
          }

          // Count attendance statuses
          attendanceData.forEach((date, record) {
            if (date.toString().startsWith(currentMonth)) {
              switch (record['status']) {
                case 'Present': present++; break;
                case 'Absent': absent++; break;
                case 'Late': late++; break;
                case 'On Leave': leave++; break;
              }
            }
          });
        }

        final attendedDays = present + late;
        final attendancePercentage = totalWorkingDays > 0 ? attendedDays / totalWorkingDays : 0.0;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(now),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Present', '$present', Icons.check_circle, Colors.green),
                    _buildStatItem('Absent', '$absent', Icons.cancel, Colors.red),
                    _buildStatItem('Late', '$late', Icons.watch_later, Colors.orange),
                    _buildStatItem('Leave', '$leave', Icons.beach_access, Colors.blue),
                  ],
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: attendancePercentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF02d39a)),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Attendance: ${(attendancePercentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '$attendedDays/$totalWorkingDays days',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }



  Widget _buildStatsRow() {
    final User? user = FirebaseAuth.instance.currentUser;
    final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref();

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.child('attendance/${user?.uid}').onValue,
      builder: (context, snapshot) {
        // Default values
        double todayHours = 0.0;
        String daysCompleted = '0/0';
        Color daysColor = Color(0xFFf8b250);

        if (snapshot.hasData && user != null && snapshot.data!.snapshot.value != null) {
          final attendanceData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final now = DateTime.now();
          final todayKey = DateFormat('yyyy-MM-dd').format(now);
          final currentMonth = DateFormat('yyyy-MM').format(now);

          // Calculate today's working hours
          if (attendanceData[todayKey] != null) {
            final todayRecord = attendanceData[todayKey];
            if (todayRecord['checkIn'] != null && todayRecord['checkOut'] != null) {
              final checkInParts = todayRecord['checkIn'].toString().split(':');
              final checkOutParts = todayRecord['checkOut'].toString().split(':');

              final checkInTime = TimeOfDay(
                hour: int.parse(checkInParts[0]),
                minute: int.parse(checkInParts[1]),
              );
              final checkOutTime = TimeOfDay(
                hour: int.parse(checkOutParts[0]),
                minute: int.parse(checkOutParts[1]),
              );

              final checkInDt = DateTime(now.year, now.month, now.day,
                  checkInTime.hour, checkInTime.minute);
              final checkOutDt = DateTime(now.year, now.month, now.day,
                  checkOutTime.hour, checkOutTime.minute);
              todayHours = checkOutDt.difference(checkInDt).inMinutes / 60.0;
            }
          }

          // Calculate monthly days completed
          int presentDays = 0;
          int totalWorkingDays = 0;
          final firstDay = DateTime(now.year, now.month, 1);
          final lastDay = DateTime(now.year, now.month + 1, 0);

          for (var day = firstDay; day.isBefore(lastDay.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
            if (day.weekday >= DateTime.monday && day.weekday <= DateTime.friday) {
              totalWorkingDays++;
              final dayKey = DateFormat('yyyy-MM-dd').format(day);
              if (attendanceData[dayKey] != null &&
                  attendanceData[dayKey]['status'] == 'Present') {
                presentDays++;
              }
            }
          }

          daysCompleted = '$presentDays/$totalWorkingDays';

          // Change color based on completion percentage
          final completionPercentage = totalWorkingDays > 0 ? presentDays / totalWorkingDays : 0;
          if (completionPercentage >= 0.9) {
            daysColor = Colors.green;
          } else if (completionPercentage >= 0.7) {
            daysColor = Color(0xFFf8b250); // Orange
          } else {
            daysColor = Colors.red;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Working Hours',
                todayHours.toStringAsFixed(1),
                'hours today',
                Icons.access_time,
                Color(0xFF23b6e6),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Days',
                daysCompleted,
                'this month',
                Icons.calendar_month,
                daysColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }



  Widget _buildWeeklyHoursChart() {
    final User? user = FirebaseAuth.instance.currentUser;
    final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref();

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.child('attendance/${user?.uid}').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || user == null) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Initialize weekly hours data
        List<double> weeklyHours = List.filled(7, 0.0);
        final now = DateTime.now();
        final currentDate = DateTime(now.year, now.month, now.day);

        if (snapshot.data!.snapshot.value != null) {
          final attendanceData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // Calculate hours for each day of the current week
          for (int i = 0; i < 7; i++) {
            final day = currentDate.subtract(Duration(days: currentDate.weekday - 1 - i));
            final dayKey = DateFormat('yyyy-MM-dd').format(day);

            if (attendanceData[dayKey] != null) {
              final record = attendanceData[dayKey];
              if (record['checkIn'] != null && record['checkOut'] != null) {
                final checkInParts = record['checkIn'].toString().split(':');
                final checkOutParts = record['checkOut'].toString().split(':');

                final checkInTime = TimeOfDay(
                  hour: int.parse(checkInParts[0]),
                  minute: int.parse(checkInParts[1]),
                );
                final checkOutTime = TimeOfDay(
                  hour: int.parse(checkOutParts[0]),
                  minute: int.parse(checkOutParts[1]),
                );

                // Calculate working hours
                final checkInDt = DateTime(day.year, day.month, day.day,
                    checkInTime.hour, checkInTime.minute);
                final checkOutDt = DateTime(day.year, day.month, day.day,
                    checkOutTime.hour, checkOutTime.minute);
                weeklyHours[i] = checkOutDt.difference(checkInDt).inMinutes / 60.0;
              }
            }
          }
        }

        // Find max Y value for chart scaling
        final maxY = weeklyHours.reduce((a, b) => a > b ? a : b).ceilToDouble() + 2;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Hours',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'This Week',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Text(
                                days[value.toInt()],
                                style: TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}h',
                                style: TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: maxY > 8 ? maxY : 8, // Ensure minimum chart height
                      lineBarsData: [
                        LineChartBarData(
                          spots: weeklyHours.asMap().entries.map((entry) =>
                              FlSpot(entry.key.toDouble(), entry.value)).toList(),
                          isCurved: true,
                          color: Color(0xFF23b6e6),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Color(0xFF23b6e6).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildRecentActivity() {
    final User? user = FirebaseAuth.instance.currentUser;
    final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
        app: FirebaseDatabase.instance.app,
        databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
    ).ref();

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.child('employee_locations/${user?.uid}')
          .orderByChild('timestamp')
          .limitToLast(3)
          .onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || user == null) {
          return Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> activities = [];
        if (snapshot.data!.snapshot.value != null) {
          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          activities = data.entries.map((entry) {
            return {
              'type': 'location_update',
              'timestamp': entry.value['timestamp'],
              'location': entry.value['location'],
            };
          }).toList();
        }

        // Fetch attendance data asynchronously
        return FutureBuilder<DataSnapshot>(
          future: dbRef.child('attendance/${user.uid}').get(),
          builder: (context, attendanceSnapshot) {
            if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (attendanceSnapshot.hasData && attendanceSnapshot.data!.value != null) {
              final attendanceData = attendanceSnapshot.data!.value as Map<dynamic, dynamic>;

              // Process attendance data to add check-in/check-out activity
              attendanceData.forEach((key, value) {
                activities.add({
                  'type': value['status'] == 'Present' ? 'check_in' : 'check_out',
                  'timestamp': value['timestamp'],
                  'location': value['location'] ?? 'Unknown',
                });
              });
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...activities.reversed.map((activity) => _buildActivityItem(activity)).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            activity['type'] == 'location_update' ? Icons.location_on : Icons.check_circle,
            color: activity['type'] == 'location_update' ? Colors.blue : Colors.green,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['type'] == 'location_update'
                      ? 'Location updated'
                      : (activity['type'] == 'check_in' ? 'Checked In' : 'Checked Out'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Location: ${activity['location']}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Timestamp: ${DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(activity['timestamp']))}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}


