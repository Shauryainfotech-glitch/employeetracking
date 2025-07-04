import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();

  final User? _user = FirebaseAuth.instance.currentUser;
  DateTime _selectedDate = DateTime.now();
  bool _isPresent = false;
  bool _isOnLeave = false;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isLoading = true;

  List<AttendanceRecord> _attendanceRecords = [];
  Map<DateTime, double> _dailyWorkingHours = {};
  double _monthlyAttendancePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    // Load today's attendance
    await _loadTodayAttendance();

    // Load all attendance records
    final snapshot = await _dbRef.child('attendance/${_user!.uid}').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      _attendanceRecords = [];
      _dailyWorkingHours = {};

      data.forEach((dateStr, recordData) {
        final date = DateTime.parse(dateStr);
        final checkInParts = recordData['checkIn']?.toString().split(':') ?? [];
        final checkOutParts = recordData['checkOut']?.toString().split(':') ??
            [];

        final checkIn = checkInParts.isNotEmpty
            ? TimeOfDay(hour: int.parse(checkInParts[0]),
            minute: int.parse(checkInParts[1]))
            : null;
        final checkOut = checkOutParts.isNotEmpty
            ? TimeOfDay(hour: int.parse(checkOutParts[0]),
            minute: int.parse(checkOutParts[1]))
            : null;

        // Calculate working hours
        double workingHours = 0.0;
        if (checkIn != null && checkOut != null) {
          final checkInDateTime = DateTime(
              date.year, date.month, date.day, checkIn.hour, checkIn.minute);
          final checkOutDateTime = DateTime(
              date.year, date.month, date.day, checkOut.hour, checkOut.minute);
          workingHours = checkOutDateTime
              .difference(checkInDateTime)
              .inMinutes / 60.0;
        }

        _dailyWorkingHours[date] = workingHours;

        _attendanceRecords.add(AttendanceRecord(
          date: date,
          checkIn: checkIn,
          checkOut: checkOut,
          status: recordData['status'] ?? 'Absent',
          location: recordData['location'],
          workingHours: workingHours,
        ));
      });

      // Sort records by date (newest first)
      _attendanceRecords.sort((a, b) => b.date.compareTo(a.date));

      // Calculate monthly attendance percentage
      _calculateMonthlyAttendance();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadTodayAttendance() async {
    if (_user == null) return;

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapshot = await _dbRef
        .child('attendance/${_user!.uid}/$todayKey')
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _isPresent = data['status'] == 'Present';
        _isOnLeave = data['status'] == 'On Leave';
        if (data['checkIn'] != null) {
          final checkInParts = data['checkIn'].toString().split(':');
          _checkInTime = TimeOfDay(
            hour: int.parse(checkInParts[0]),
            minute: int.parse(checkInParts[1]),
          );
        }
        if (data['checkOut'] != null) {
          final checkOutParts = data['checkOut'].toString().split(':');
          _checkOutTime = TimeOfDay(
            hour: int.parse(checkOutParts[0]),
            minute: int.parse(checkOutParts[1]),
          );
        }
      });
    }
  }

  double _calculateMonthlyAttendance() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    int workingDays = 0;
    int presentDays = 0;

    for (var day = firstDayOfMonth; day.isBefore(lastDayOfMonth.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
      if (day.weekday >= DateTime.monday && day.weekday <= DateTime.friday) {
        workingDays++;

        final dayKey = DateFormat('yyyy-MM-dd').format(day);
        final record = _attendanceRecords.firstWhere(
              (r) => DateFormat('yyyy-MM-dd').format(r.date) == dayKey,
          orElse: () => AttendanceRecord(
            date: day,
            status: 'Absent',
            workingHours: 0,
          ),
        );

        if (record.status == 'Present' && record.workingHours >= 4) {
          presentDays++;
        } else if (record.status == 'On Leave') {
          workingDays--;
        }
      }
    }

    // Return the calculated attendance percentage as a double
    return workingDays > 0 ? presentDays / workingDays : 0.0;
  }



  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _recordAttendance(bool isCheckIn) async {
    if (_user == null) return;

    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    final timeNow = TimeOfDay.fromDateTime(now);

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool? enableLocation = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Location Required'),
          content: Text('Please enable location services to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Enable'),
            ),
          ],
        ),
      );

      if (enableLocation == true) {
        await Geolocator.openLocationSettings();
      }
      return;
    }

    // For check-out, show confirmation dialog
    if (!isCheckIn) {
      bool? confirmCheckOut = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    Icons.logout_rounded,
                    key: ValueKey('checkout-icon'),
                    size: 48,
                    color: Colors.orange.shade700,
                  ),
                ),
                SizedBox(height: 20),

                // Title with gradient text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.orange.shade700,
                      Colors.red.shade600,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Confirm Check Out',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Message
                Text(
                  'Are you sure you want to check out now?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cancel button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Check Out button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.orange.shade700,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.orange.shade900,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Check Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmCheckOut != true) return;
    }

    // Get current location
    setState(() => _isLoadingLocation = true);
    try {
      await _getCurrentLocation();
    } finally {
      setState(() => _isLoadingLocation = false);
    }

    if (isCheckIn && _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not determine your location')),
      );
      return;
    }

    final attendanceData = {
      'date': todayKey,
      'timestamp': now.millisecondsSinceEpoch,
      'status': isCheckIn ? 'Present' : (_isOnLeave ? 'On Leave' : 'Present'),
      'employeeId': _user!.uid,
      if (isCheckIn) 'checkIn': '${timeNow.hour}:${timeNow.minute}',
      if (!isCheckIn) 'checkOut': '${timeNow.hour}:${timeNow.minute}',
      if (_currentPosition != null)
        'location': {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'timestamp': now.millisecondsSinceEpoch,
        },
    };

    try {
      await _dbRef.child('attendance/${_user!.uid}/$todayKey').update(
          attendanceData);

      // Reload data after update
      await _loadAttendanceData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isCheckIn
            ? 'Checked in successfully!'
            : 'Checked out successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attendance: $e')),
      );
    }
  }

  Widget _buildTimeTracker() {
    final currentWorkingHours = _checkInTime != null && _checkOutTime != null
        ? _dailyWorkingHours[DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day)] ?? 0.0
        : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeCard('Check In', _checkInTime),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                _buildTimeCard('Check Out', _checkOutTime),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                _buildTimeCard('Hours', null, hours: currentWorkingHours),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: currentWorkingHours / 8.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  currentWorkingHours >= 8 ? Colors.green : Colors.blue),
              minHeight: 10,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today\'s Progress', style: TextStyle(color: Colors.grey)),
                Text(
                  '${currentWorkingHours.toStringAsFixed(1)} / 8 hours',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPresent ? Colors.red : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isLoadingLocation
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                _isPresent ? 'CHECK OUT' : 'CHECK IN',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () => _recordAttendance(!_isPresent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(String label, TimeOfDay? time, {double? hours}) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 4),
        Text(
          hours != null
              ? '${hours.toStringAsFixed(1)}h'
              : time != null
              ? time.format(context)
              : '--:--',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Tracking'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendanceData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateHeader(),
            SizedBox(height: 20),
            _buildAttendanceStatusCard(),
            SizedBox(height: 20),
            _buildTimeTracker(),
            SizedBox(height: 20),
            // _buildCalendarView(),
            // SizedBox(height: 20),
            _buildAttendanceHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('EEEE, MMMM d').format(_selectedDate),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Chip(
          label: Text(
            DateFormat('yyyy').format(_selectedDate),
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusCard() {
    String status = _isOnLeave ? 'On Leave' : (_isPresent
        ? 'Present'
        : 'Absent');
    Color statusColor = _isOnLeave ? Colors.orange : (_isPresent
        ? Colors.green
        : Colors.red);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: _calculateMonthlyAttendance(),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Attendance',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  '${(_calculateMonthlyAttendance() * 100).toStringAsFixed(
                      0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildTimeTracker() {
  //   return Card(
  //     elevation: 4,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _buildTimeCard('Check In', _checkInTime ?? TimeOfDay.now()),
  //               Container(
  //                 width: 1,
  //                 height: 50,
  //                 color: Colors.grey[300],
  //               ),
  //               _buildTimeCard('Check Out', _checkOutTime ?? TimeOfDay.now()),
  //             ],
  //           ),
  //           SizedBox(height: 12),
  //           ElevatedButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blue,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //             ),
  //             child: Text(
  //               _isPresent ? 'Check Out' : 'Check In',
  //               style: TextStyle(fontSize: 16),
  //             ),
  //             onPressed: () => _recordAttendance(!_isPresent),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildTimeCard(String label, TimeOfDay time) {
  //   return Column(
  //     children: [
  //       Text(
  //         label,
  //         style: TextStyle(color: Colors.grey),
  //       ),
  //       SizedBox(height: 4),
  //       Text(
  //         time.format(context),
  //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildCalendarView() {
  //   return Card(
  //     elevation: 4,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Container(
  //       height: 350,
  //       padding: EdgeInsets.all(8),
  //       child: SfCalendar(
  //         view: CalendarView.month,
  //         dataSource: _AttendanceDataSource(_getAppointments()),
  //         monthViewSettings: MonthViewSettings(
  //           showAgenda: true,
  //           appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
  //         ),
  //         onTap: (CalendarTapDetails details) {
  //           if (details.targetElement == CalendarElement.calendarCell) {
  //             setState(() {
  //               _selectedDate = details.date!;
  //             });
  //           }
  //         },
  //       ),
  //     ),
  //   );
  // }



  Widget _buildAttendanceHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Attendance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        ..._attendanceRecords.map((record) =>
            _buildAttendanceRecordItem(record)).toList(),
      ],
    );
  }

  Widget _buildAttendanceRecordItem(AttendanceRecord record) {
    Color statusColor = record.status == 'Present'
        ? Colors.green
        : record.status == 'On Leave'
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              DateFormat('d').format(record.date),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(DateFormat('EEEE, MMMM d').format(record.date)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.checkIn != null && record.checkOut != null)
              Text('${record.checkIn!.format(context)} - ${record.checkOut!
                  .format(context)}'),
            if (record.location != null)
              Text('Location: ${record.location!['latitude']?.toStringAsFixed(
                  4)}, '
                  '${record.location!['longitude']?.toStringAsFixed(4)}'),
          ],
        ),
        trailing: Chip(
          label: Text(
            record.status,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: statusColor,
        ),
        onTap: () {
          if (record.location != null) {
            // _showLocationOnMap(record.location!);
          }
        },
      ),
    );
  }
}

class AttendanceRecord {
  final DateTime date;
  final TimeOfDay? checkIn;
  final TimeOfDay? checkOut;
  final String status;
  final dynamic location;
  final double workingHours;

  AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.location,
    required this.workingHours,
  });
}

