import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class AnalyticsCharts extends StatefulWidget {
  const AnalyticsCharts({super.key});

  @override
  State<AnalyticsCharts> createState() => _AnalyticsChartsState();
}

class _AnalyticsChartsState extends State<AnalyticsCharts> {
  final DatabaseReference _database = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _isLoading = true;
  List<Map<String, dynamic>> _employeesData = [];
  Map<String, dynamic> _departmentStats = {};

  List<Map<String, dynamic>> get sortedEmployees {
    // Sort employees by productivity
    if (_employeesData.isEmpty) return [];
    return List<Map<String, dynamic>>.from(_employeesData)
      ..sort((a, b) => b['productivity'].compareTo(a['productivity']));
  }



  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch users data
      final usersSnapshot = await _database.child('users').once();
      final usersData = (usersSnapshot.snapshot.value as Map<dynamic,
          dynamic>?) ?? {};

      // Fetch attendance data for the selected date range
      final attendanceSnapshot = await _database.child('attendance').once();
      final attendanceData = (attendanceSnapshot.snapshot.value as Map<
          dynamic,
          dynamic>?) ?? {};

      // Fetch productivity data (assuming it's stored in users or a separate node)
      final productivityData = {}; // Add your productivity data fetching logic

      // Process data to calculate metrics
      _employeesData =
          _processEmployeeData(usersData, attendanceData, productivityData);
      _departmentStats = _calculateDepartmentStats(_employeesData);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics data: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _processEmployeeData(
      Map<dynamic, dynamic> usersData,
      Map<dynamic, dynamic> attendanceData,
      Map<dynamic, dynamic> productivityData,) {
    final List<Map<String, dynamic>> processedData = [];

    usersData.forEach((userId, userData) {
      // Calculate attendance for date range
      double attendancePercentage = _calculateEmployeeAttendance(
          userId, attendanceData);

      // Get productivity (example - adjust based on your data structure)
      int productivity = int.tryParse(
          userData['productivity']?.toString() ?? '0') ?? 0;

      processedData.add({
        'id': userId,
        'name': userData['name'] ?? 'Unknown',
        'department': userData['department'] ?? 'Unknown',
        'attendance': attendancePercentage,
        'productivity': productivity,
        'image': 'assets/images/avatar_${(userId.hashCode % 5) + 1}.png',
        // Example avatar
      });
    });

    return processedData;
  }

  double _calculateEmployeeAttendance(String userId, Map<dynamic, dynamic> attendanceData) {
    if (!attendanceData.containsKey(userId)) return 0.0;

    final userAttendance = attendanceData[userId] as Map<dynamic, dynamic>;
    double presentDays = 0;
    int totalDays = 0;

    userAttendance.forEach((dateStr, record) {
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      // Fix: added the closing parenthesis for the if condition
      if (date.isAfter(_dateRange.start.subtract(const Duration(days: 1)))) {
        totalDays++;
        if (record['status'] == 'Present') {
          presentDays++;
        } else if (record['status'] == 'On Leave') {
          presentDays += 0.5; // Half credit for leave days
        }
      }
    });

    return totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;
  }


  Map<String, dynamic> _calculateDepartmentStats(
      List<Map<String, dynamic>> employees) {
    final Map<String, dynamic> stats = {};

    for (var employee in employees) {
      final dept = employee['department'];
      if (!stats.containsKey(dept)) {
        stats[dept] = {
          'count': 0,
          'totalAttendance': 0.0,
          'totalProductivity': 0,
          'members': [],
        };
      }

      stats[dept]['count']++;
      stats[dept]['totalAttendance'] += employee['attendance'];
      stats[dept]['totalProductivity'] += employee['productivity'];
      stats[dept]['members'].add(employee);
    }

    // Calculate averages
    stats.forEach((dept, data) {
      data['avgAttendance'] = data['totalAttendance'] / data['count'];
      data['avgProductivity'] = data['totalProductivity'] / data['count'];
    });

    return stats;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3366FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
        _fetchAnalyticsData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateRangeSelector(),
        const SizedBox(height: 16),
        _isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : Expanded(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPageIndex = index),
                  children: [
                    _buildProductivityChart(),
                    _buildAttendanceChart(),
                    _buildDepartmentComparisonChart(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPageIndicator(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          InkWell(
            onTap: () => _selectDateRange(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(
                      Icons.calendar_today, size: 16, color: Color(0xFF3366FF)),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d').format(
                        _dateRange.start)} - ${DateFormat('MMM d').format(
                        _dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityChart() {
    // Sort employees by productivity
    final sortedEmployees = List<Map<String, dynamic>>.from(_employeesData)
      ..sort((a, b) => b['productivity'].compareTo(a['productivity']));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Productivity Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline,
                        size: 20, color: Color(0xFF5F6C7D)),
                    onPressed: () =>
                        _showInfoDialog(
                          'Productivity Insights',
                          'Measures employee output based on completed tasks, deadlines, and quality metrics.',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.refresh, size: 20, color: Color(0xFF5F6C7D)),
                    onPressed: _fetchAnalyticsData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat(
                'MMM d').format(_dateRange.end)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6C7D),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: 100,
                minY: 0,
                groupsSpace: 12,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final employee = sortedEmployees[groupIndex];
                      return BarTooltipItem(
                        '${employee['name']}\nDepartment: ${employee['department']}\nProductivity: ${rod
                            .toY.toInt()}%',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '\n${_getPerformanceText(rod.toY.toInt())}',
                            style: TextStyle(
                              color: _getPerformanceColor(rod.toY.toInt()),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (response?.spot != null) {
                      HapticFeedback.selectionClick();
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedEmployees.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedEmployees[value.toInt()]['name'].split(
                                  ' ')[0],
                              style: const TextStyle(
                                color: Color(0xFF5F6C7D),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF5F6C7D),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(
                        color: const Color(0xFFEAECF0),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEmployees
                    .asMap()
                    .entries
                    .map((entry) {
                  final productivity = entry.value['productivity'].toDouble();
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: productivity,
                        gradient: _getPerformanceGradient(
                            entry.value['productivity']),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: const Color(0xFFEAECF0),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLegendItem('Excellent', const Color(0xFF00A76F)),
                _buildLegendItem('Good', const Color(0xFF3366FF)),
                _buildLegendItem('Average', const Color(0xFFFFAB00)),
                _buildLegendItem('Needs Improvement', const Color(0xFFFF5630)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    // Sort employees by attendance
    final sortedEmployees = List<Map<String, dynamic>>.from(_employeesData)
      ..sort((a, b) => b['attendance'].compareTo(a['attendance']));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance Rate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline,
                        size: 20, color: Color(0xFF5F6C7D)),
                    onPressed: () =>
                        _showInfoDialog(
                          'Attendance Insights',
                          'Shows the percentage of days employees were present and on time.',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.refresh, size: 20, color: Color(0xFF5F6C7D)),
                    onPressed: _fetchAnalyticsData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat(
                'MMM d').format(_dateRange.end)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6C7D),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 60,
                sections: sortedEmployees.take(5).map((employee) {
                  return PieChartSectionData(
                    color: _getAttendanceColor(employee['attendance'].toInt()),
                    value: employee['attendance'].toDouble(),
                    title: '${employee['attendance'].toStringAsFixed(1)}%',
                    radius: 30,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: _buildEmployeeBadge(employee),
                    badgePositionPercentageOffset: 0.98,
                  );
                }).toList(),
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (event is FlTapUpEvent &&
                        pieTouchResponse?.touchedSection != null) {
                      HapticFeedback.lightImpact();
                      _showEmployeeDetails(
                          sortedEmployees[pieTouchResponse!.touchedSection!
                              .touchedSectionIndex]);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Top 5 Employees by Attendance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...sortedEmployees.take(5).map((employee) =>
              _buildEmployeeAttendanceItem(employee)),
        ],
      ),
    );
  }

  Widget _buildDepartmentComparisonChart() {
    final departmentList = _departmentStats.keys.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Department Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline,
                        size: 20, color: Color(0xFF5F6C7D)),
                    onPressed: () =>
                        _showInfoDialog(
                          'Department Insights',
                          'Compares average productivity and attendance across departments.',
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.refresh, size: 20, color: Color(0xFF5F6C7D)),
                    onPressed: _fetchAnalyticsData,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat(
                'MMM d').format(_dateRange.end)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6C7D),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: departmentList
                    .asMap()
                    .entries
                    .map((entry) {
                  final dept = entry.value;
                  final stats = _departmentStats[dept];
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: stats['avgProductivity'].toDouble(),
                        color: const Color(0xFF3366FF),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: stats['avgAttendance'].toDouble(),
                        color: const Color(0xFF00A76F),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData:FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (sortedEmployees.isNotEmpty && value.toInt() >= 0 && value.toInt() < sortedEmployees.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sortedEmployees[value.toInt()]['name'].split(' ')[0], // First name
                              style: const TextStyle(
                                color: Color(0xFF5F6C7D),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 32,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                            color: Color(0xFF5F6C7D),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),


                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(
                        color: const Color(0xFFEAECF0),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFFEAECF0), width: 1),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Productivity', const Color(0xFF3366FF)),
              const SizedBox(width: 16),
              _buildLegendItem('Attendance', const Color(0xFF00A76F)),
            ],
          ),
          const SizedBox(height: 16),
          ...departmentList.map((dept) =>
              _buildDepartmentListItem(dept, _departmentStats[dept])),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentPageIndex == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _currentPageIndex == index
                ? const Color(0xFF3366FF)
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeBadge(Map<String, dynamic> employee) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: _getAttendanceColor(employee['attendance'].toInt()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          employee['name'][0],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getAttendanceColor(employee['attendance'].toInt()),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeAttendanceItem(Map<String, dynamic> employee) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              image: DecorationImage(
                image: AssetImage(employee['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  employee['department'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getAttendanceColor(employee['attendance'].toInt())
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${employee['attendance'].toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getAttendanceColor(employee['attendance'].toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentListItem(String dept, Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dept,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${stats['avgProductivity'].toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3366FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${stats['avgAttendance'].toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00A76F),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: stats['avgProductivity'] / 100,
                  backgroundColor: const Color(0xFF3366FF).withOpacity(0.1),
                  minHeight: 6,
                  color: const Color(0xFF3366FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LinearProgressIndicator(
                  value: stats['avgAttendance'] / 100,
                  backgroundColor: const Color(0xFF00A76F).withOpacity(0.1),
                  minHeight: 6,
                  color: const Color(0xFF00A76F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showEmployeeDetails(Map<String, dynamic> employee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.6,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                      image: DecorationImage(
                        image: AssetImage(employee['image']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    employee['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    employee['department'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailItem('Productivity', '${employee['productivity']}%',
                    _getPerformanceColor(employee['productivity'])),
                _buildDetailItem('Attendance',
                    '${employee['attendance'].toStringAsFixed(1)}%',
                    _getAttendanceColor(employee['attendance'].toInt())),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3366FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: int.parse(value.replaceAll('%', '')) / 100,
                  backgroundColor: color.withOpacity(0.1),
                  color: color,
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getPerformanceGradient(int performance) {
    if (performance >= 90) {
      return const LinearGradient(
        colors: [Color(0xFF00A76F), Color(0xFF00C853)],
      );
    }
    if (performance >= 75) {
      return const LinearGradient(
        colors: [Color(0xFF3366FF), Color(0xFF4285F4)],
      );
    }
    if (performance >= 50) {
      return const LinearGradient(
        colors: [Color(0xFFFFAB00), Color(0xFFFFC107)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFFF5630), Color(0xFFFF7043)],
    );
  }

  String _getPerformanceText(int performance) {
    if (performance >= 90) return 'Excellent';
    if (performance >= 75) return 'Good';
    if (performance >= 50) return 'Average';
    return 'Needs Improvement';
  }

  Color _getPerformanceColor(int performance) {
    if (performance >= 90) return const Color(0xFF00A76F);
    if (performance >= 75) return const Color(0xFF3366FF);
    if (performance >= 50) return const Color(0xFFFFAB00);
    return const Color(0xFFFF5630);
  }

  Color _getAttendanceColor(int attendance) {
    if (attendance >= 95) return const Color(0xFF00A76F);
    if (attendance >= 85) return const Color(0xFF3366FF);
    if (attendance >= 70) return const Color(0xFFFFAB00);
    return const Color(0xFFFF5630);
  }
}