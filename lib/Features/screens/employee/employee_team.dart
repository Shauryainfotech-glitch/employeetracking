import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceCalendarPage extends StatefulWidget {
  @override
  _AttendanceCalendarPageState createState() => _AttendanceCalendarPageState();
}

class _AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  // Replace your current database initialization with this:
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();
  final User? _user = FirebaseAuth.instance.currentUser;
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    final snapshot = await _dbRef.child('attendance/${_user!.uid}').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      _attendanceRecords = [];

      data.forEach((dateStr, recordData) {
        final date = DateTime.parse(dateStr);
        final checkInParts = recordData['checkIn']?.toString().split(':') ?? [];
        final checkOutParts = recordData['checkOut']?.toString().split(':') ?? [];

        final checkIn = checkInParts.isNotEmpty
            ? TimeOfDay(hour: int.parse(checkInParts[0]), minute: int.parse(checkInParts[1]))
            : null;
        final checkOut = checkOutParts.isNotEmpty
            ? TimeOfDay(hour: int.parse(checkOutParts[0]), minute: int.parse(checkOutParts[1]))
            : null;

        // Calculate working hours
        double workingHours = 0.0;
        if (checkIn != null && checkOut != null) {
          final checkInDateTime = DateTime(date.year, date.month, date.day, checkIn.hour, checkIn.minute);
          final checkOutDateTime = DateTime(date.year, date.month, date.day, checkOut.hour, checkOut.minute);
          workingHours = checkOutDateTime.difference(checkInDateTime).inMinutes / 60.0;
        }

        _attendanceRecords.add(AttendanceRecord(
          date: date,
          checkIn: checkIn,
          checkOut: checkOut,
          status: recordData['status'] ?? 'Absent',
          workingHours: workingHours,
        ));
      });
    }

    setState(() => _isLoading = false);
  }

  Color _getStatusColor(String status, double workingHours) {
    switch (status) {
      case 'Present':
        return workingHours >= 8 ? Colors.green : Colors.lightGreen;
      case 'On Leave':
        return Colors.orange;
      case 'Late':
        return Colors.purple;
      case 'Half Day':
        return Colors.blue;
      default: // Absent
        return Colors.red;
    }
  }

  List<Color> _getEventColors(DateTime day) {
    final record = _attendanceRecords.firstWhere(
          (r) => DateFormat('yyyy-MM-dd').format(r.date) == DateFormat('yyyy-MM-dd').format(day),
      orElse: () => AttendanceRecord(
        date: day,
        status: 'No Record',
        workingHours: 0,
      ),
    );

    return [_getStatusColor(record.status, record.workingHours)];
  }

  Widget _buildEventMarker(DateTime day, List events) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: events.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Calendar'),
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
          : Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventColors,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerSize: 8,
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return _buildEventMarker(date, events);
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          if (_selectedDay != null) _buildSelectedDayDetails(),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    final record = _attendanceRecords.firstWhere(
          (r) => DateFormat('yyyy-MM-dd').format(r.date) ==
          DateFormat('yyyy-MM-dd').format(_selectedDay!),
      orElse: () => AttendanceRecord(
        date: _selectedDay!,
        status: 'No Record',
        workingHours: 0,
      ),
    );

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay!),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(
                    record.status,
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(record.status, record.workingHours),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Check-in:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.checkIn?.format(context) ?? '--:--'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Check-out:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(record.checkOut?.format(context) ?? '--:--'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Working Hours:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${record.workingHours.toStringAsFixed(1)} hours'),
              ],
            ),
            if (record.workingHours > 0) ...[
              SizedBox(height: 16),
              LinearProgressIndicator(
                value: record.workingHours / 8.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(record.status, record.workingHours)),
                minHeight: 10,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily Progress:'),
                  Text('${(record.workingHours / 8.0 * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AttendanceRecord {
  final DateTime date;
  final TimeOfDay? checkIn;
  final TimeOfDay? checkOut;
  final String status;
  final double workingHours;

  AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.workingHours,
  });
}