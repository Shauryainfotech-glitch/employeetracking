import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart' as geo;

class TrackingPage extends StatefulWidget {
  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> with SingleTickerProviderStateMixin {
  // Map and Location Variables
  late MapController _mapController;
  Position? _currentPosition;
  bool _isTracking = false;
  late AnimationController _animationController;
  List<LatLng> _routePoints = [];
  double _zoom = 15.0;

  // Firebase Variables
  final _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://smart-employee-tracking-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Device Metrics
  double _batteryLevel = 0.85;
  double _speed = 0.0;

  // Check-in/Check-out Variables
  bool _isCheckedIn = false;
  bool _alreadyCheckedOutToday = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  Duration _todayDuration = Duration.zero;
  Map<String, dynamic>? _checkInLocation;
  Map<String, dynamic>? _checkOutLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _getCurrentLocation();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    if (_user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapshot = await _database
        .child('employee_attendance')
        .child(_user!.uid)
        .child(today)
        .once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      setState(() {
        _isCheckedIn = data['check_out_time'] == null;
        _alreadyCheckedOutToday = data['check_out_time'] != null;
        _checkInTime = DateTime.parse(data['check_in_time']);
        _checkInLocation = data['check_in_location'];

        if (data['check_out_time'] != null) {
          _checkOutTime = DateTime.parse(data['check_out_time']);
          _checkOutLocation = data['check_out_location'];
          _todayDuration = _checkOutTime!.difference(_checkInTime!);
        } else {
          _todayDuration = DateTime.now().difference(_checkInTime!);
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
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

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best
      );
      setState(() {
        _currentPosition = position;
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _speed = position.speed;
      });

      if (_isTracking) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _zoom,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _getLocationData() async {
    if (_currentPosition == null) return {};

    // Create default placemark
    geo.Placemark placemark = geo.Placemark(
      street: 'Unknown street',
      subLocality: 'Unknown area',
      locality: 'Unknown city',
      administrativeArea: 'Unknown state',
      country: 'Unknown country',
      postalCode: 'Unknown postal code',
    );

    // Try to get actual location if plugin is available
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      if (placemarks.isNotEmpty) {
        placemark = placemarks.first;
      }
    } catch (e) {
      print('Geocoding error: $e');
      // Continue with default placemark values
    }

    final now = DateTime.now();
    return {
      'timestamp': now.millisecondsSinceEpoch,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'time': DateFormat('HH:mm:ss').format(now),
      'coordinates': {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'accuracy': _currentPosition!.accuracy,
        'altitude': _currentPosition!.altitude,
        'speed': _currentPosition!.speed,
      },
      'location': {
        'address': placemark.street ?? 'Unknown street',
        'area': placemark.subLocality ?? placemark.locality ?? 'Unknown area',
        'city': placemark.locality ?? 'Unknown city',
        'state': placemark.administrativeArea ?? 'Unknown state',
        'country': placemark.country ?? 'Unknown country',
        'postalCode': placemark.postalCode ?? 'Unknown postal code',
      },
      'device': {
        'battery': _batteryLevel,
        'speed': _speed,
      },
    };
  }

  Future<void> _checkIn() async {
    if (_user == null || _currentPosition == null) return;

    try {
      final locationData = await _getLocationData();
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      await _database
          .child('employee_attendance')
          .child(_user!.uid)
          .child(today)
          .set({
        'check_in_time': now.toIso8601String(),
        'check_in_location': locationData,
        'user': {
          'uid': _user!.uid,
          'name': _user!.displayName ?? 'Unknown',
          'email': _user!.email ?? 'No email',
          'phone': _user!.phoneNumber ?? 'No phone',
        },
      });

      setState(() {
        _isCheckedIn = true;
        _alreadyCheckedOutToday = false;
        _checkInTime = now;
        _checkOutTime = null;
        _checkInLocation = locationData;
        _checkOutLocation = null;
        _todayDuration = Duration.zero;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked in successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check in: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _checkOut() async {
    if (_user == null || _currentPosition == null || !_isCheckedIn) return;

    try {
      final locationData = await _getLocationData();
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final duration = now.difference(_checkInTime!);

      await _database
          .child('employee_attendance')
          .child(_user!.uid)
          .child(today)
          .update({
        'check_out_time': now.toIso8601String(),
        'check_out_location': locationData,
        'total_hours': duration.inHours + (duration.inMinutes % 60) / 60,
        'status': duration.inHours >= 8 ? 'completed' : 'incomplete',
      });

      setState(() {
        _isCheckedIn = false;
        _alreadyCheckedOutToday = true;
        _checkOutTime = now;
        _checkOutLocation = locationData;
        _todayDuration = duration;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked out successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check out: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLocationDetails(bool isCheckIn) {
    final locationData = isCheckIn ? _checkInLocation : _checkOutLocation;
    if (locationData == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCheckIn ? 'Check-in Location' : 'Check-out Location'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLocationDetailItem('Date', locationData['date']),
              _buildLocationDetailItem('Time', locationData['time']),
              _buildLocationDetailItem('Address', locationData['location']['address']),
              _buildLocationDetailItem('Area', locationData['location']['area']),
              _buildLocationDetailItem('City', locationData['location']['city']),
              _buildLocationDetailItem('State', locationData['location']['state']),
              _buildLocationDetailItem('Country', locationData['location']['country']),
              _buildLocationDetailItem('Postal Code', locationData['location']['postalCode']),
              SizedBox(height: 10),
              Text('Coordinates:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildLocationDetailItem('Latitude', locationData['coordinates']['latitude'].toString()),
              _buildLocationDetailItem('Longitude', locationData['coordinates']['longitude'].toString()),
              _buildLocationDetailItem('Accuracy', '${locationData['coordinates']['accuracy']} meters'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _todayDuration.inHours;
    final minutes = _todayDuration.inMinutes % 60;
    final progressColor = _todayDuration.inHours >= 8 ? Colors.green : Colors.red;

    return Scaffold(
      body: Stack(
        children: [
          // Map View
          _buildMap(),

          // Header Panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildHeaderPanel(),
          ),

          // Stats Panel
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + (_alreadyCheckedOutToday ? 180 : 220),
            left: 16,
            right: 16,
            child: _buildStatsPanel(progressColor, hours, minutes),
          ),

          // Location Details Buttons (only when checked in or out)
          if (_checkInTime != null || _checkOutTime != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 180,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_checkInLocation != null)
                    ElevatedButton.icon(
                      icon: Icon(Icons.login, size: 16),
                      label: Text('CHECK-IN LOCATION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showLocationDetails(true),
                    ),
                  if (_checkOutLocation != null)
                    ElevatedButton.icon(
                      icon: Icon(Icons.logout, size: 16),
                      label: Text('CHECK-OUT LOCATION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showLocationDetails(false),
                    ),
                ],
              ),
            ),

          // Tracking Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120,
            right: 16,
            child: _buildTrackingButton(),
          ),

          // Check-in/Check-out Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: _buildCheckInOutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return Center(child: CircularProgressIndicator());
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        initialZoom: _zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.employee_tracking',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              strokeWidth: 4.0,
              color: Colors.blue.withOpacity(0.7),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 40,
              height: 40,
              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              child: Transform.translate(
                offset: Offset(0, -20),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isTracking ? 1.0 + _animationController.value * 0.2 : 1.0,
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee Tracking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _currentPosition != null
                        ? '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}'
                        : 'Acquiring location...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _getCurrentLocation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(Color progressColor, int hours, int minutes) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Speed', '${_speed.toStringAsFixed(1)} km/h', Icons.speed),
                _buildStatItem('Accuracy', '${_currentPosition?.accuracy?.toStringAsFixed(1) ?? '0'} m', Icons.abc),
                _buildStatItem('Today', '$hours h $minutes m', Icons.timer),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: _todayDuration.inMinutes / (8 * 60),
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            SizedBox(height: 8),
            Text(
              'Today\'s Progress',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 8),
            if (_checkInTime != null)
              Text(
                'Checked in: ${DateFormat('HH:mm').format(_checkInTime!)}',
                style: TextStyle(fontSize: 12),
              ),
            if (_checkOutTime != null)
              Text(
                'Checked out: ${DateFormat('HH:mm').format(_checkOutTime!)}',
                style: TextStyle(fontSize: 12),
              ),
            if (_alreadyCheckedOutToday)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You have already checked out today',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            SizedBox(width: 4),
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
      if (_isTracking) {
        _animationController.repeat(reverse: true);
        _startLocationUpdates();
      } else {
        _animationController.stop();
      }
    });
  }

  void _startLocationUpdates() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!_isTracking) return;

      setState(() {
        _currentPosition = position;
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _speed = position.speed;
      });

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _zoom,
      );
    });
  }

  Widget _buildTrackingButton() {
    return FloatingActionButton(
      backgroundColor: _isTracking ? Colors.red : Colors.green,
      child: Icon(
        _isTracking ? Icons.stop : Icons.play_arrow,
        color: Colors.white,
      ),
      onPressed: _toggleTracking,
    );
  }

  Widget _buildCheckInOutButton() {
    if (_alreadyCheckedOutToday) {
      return ElevatedButton.icon(
        icon: Icon(Icons.done_all, size: 20),
        label: Text('ALREADY CHECKED OUT TODAY'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: null, // Disabled button
      );
    }

    return ElevatedButton.icon(
      icon: Icon(
        _isCheckedIn ? Icons.logout : Icons.login,
        size: 20,
      ),
      label: Text(_isCheckedIn ? 'CHECK OUT' : 'CHECK IN'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isCheckedIn ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        if (_isCheckedIn) {
          _checkOut();
        } else {
          _checkIn();
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}