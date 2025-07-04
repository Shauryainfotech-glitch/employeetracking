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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _getCurrentLocation();
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

  Future<void> _sendLocationToFirebase() async {
    if (_currentPosition == null || _user == null) return;

    try {
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

      // Create location data
      final now = DateTime.now();
      final locationData = {
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
        'user': {
          'uid': _user!.uid,
          'name': _user!.displayName ?? 'Unknown',
          'email': _user!.email ?? 'No email',
          'phone': _user!.phoneNumber ?? 'No phone',
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

      // Save to Firebase
      await _database
          .child('employee_locations')
          .child(_user!.uid)
          .child(now.millisecondsSinceEpoch.toString())
          .set(locationData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Failed to save location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save location: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            bottom: MediaQuery.of(context).padding.bottom + 180,
            left: 16,
            right: 16,
            child: _buildStatsPanel(),
          ),

          // Tracking Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 120,
            right: 16,
            child: _buildTrackingButton(),
          ),

          // Send Location Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: _buildSendLocationButton(),
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

  Widget _buildStatsPanel() {
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
                _buildStatItem('Battery', '${(_batteryLevel * 100).toStringAsFixed(0)}%', Icons.battery_std),
              ],
            ),
            SizedBox(height: 30),
            _buildBatteryGauge(),
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

  Widget _buildBatteryGauge() {
    return SizedBox(
      height: 100,
      child: SfLinearGauge(
        minimum: 0,
        maximum: 100,
        interval: 25,
        orientation: LinearGaugeOrientation.horizontal,
        ranges: [
          LinearGaugeRange(
            startValue: 0,
            endValue: 20,
            color: Colors.red,
          ),
          LinearGaugeRange(
            startValue: 20,
            endValue: 50,
            color: Colors.orange,
          ),
          LinearGaugeRange(
            startValue: 50,
            endValue: 100,
            color: Colors.green,
          ),
        ],
        markerPointers: [
          LinearShapePointer(
            value: _batteryLevel * 100,
            height: 15,
            width: 15,
            shapeType: LinearShapePointerType.diamond,
          )
        ],
        barPointers: [
          LinearBarPointer(
            value: _batteryLevel * 100,
            thickness: 10,
            color: Colors.transparent,
            edgeStyle: LinearEdgeStyle.bothFlat,
          )
        ],
      ),
    );
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

  Widget _buildSendLocationButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.send, size: 20),
      label: Text('SEND LOCATION'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: _sendLocationToFirebase,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}