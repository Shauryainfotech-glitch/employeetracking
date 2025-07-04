import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      home: const EmployeeLocationTracker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EmployeeLocationTracker extends StatefulWidget {
  const EmployeeLocationTracker({super.key});

  @override
  _EmployeeLocationTrackerState createState() => _EmployeeLocationTrackerState();
}

class _EmployeeLocationTrackerState extends State<EmployeeLocationTracker> {
  List<EmployeeLocation> _employees = [];
  EmployeeLocation? _selectedEmployee;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    setState(() {
      _employees = [
        EmployeeLocation(
          id: '1',
          name: 'Sarah Johnson',
          position: 'Field Agent',
          avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
          lastUpdated: DateTime.now(),
          latitude: 37.7749,
          longitude: -122.4194,
          areaName: 'Downtown San Francisco',
          state: 'California',
          district: 'San Francisco County',
          taluka: 'San Francisco',
          status: 'Active',
          batteryLevel: 85,
          speed: 12.5,
        ),
        EmployeeLocation(
          id: '2',
          name: 'Michael Chen',
          position: 'Delivery Driver',
          avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
          latitude: 37.7812,
          longitude: -122.4115,
          areaName: 'Financial District',
          state: 'California',
          district: 'San Francisco County',
          taluka: 'San Francisco',
          status: 'Moving',
          batteryLevel: 42,
          speed: 28.3,
        ),
        EmployeeLocation(
          id: '3',
          name: 'Emily Rodriguez',
          position: 'Sales Representative',
          avatarUrl: 'https://randomuser.me/api/portraits/women/63.jpg',
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
          latitude: 37.7689,
          longitude: -122.4269,
          areaName: 'Mission District',
          state: 'California',
          district: 'San Francisco County',
          taluka: 'San Francisco',
          status: 'Idle',
          batteryLevel: 76,
          speed: 0.0,
        ),
      ];
    });
  }

  void _selectEmployee(EmployeeLocation employee) {
    setState(() {
      _selectedEmployee = employee;
    });
    // Auto-scroll to top when selecting an employee
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Team Location Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _initializeData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedEmployee != null) _buildEmployeeDetailsCard(),
          Expanded(
            child: _buildEmployeeListSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetailsCard() {
    final employee = _selectedEmployee!;
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'avatar-${employee.id}',
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor(employee.status),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          employee.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
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
                          employee.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          employee.position,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedEmployee = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(employee.status),
                  _buildBatteryChip(employee.batteryLevel),
                  if (employee.speed > 0) _buildSpeedChip(employee.speed),
                ],
              ),
              const SizedBox(height: 16),
              _buildLocationSection(employee),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Updated ${DateFormat('h:mm a').format(employee.lastUpdated)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(
        status,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getStatusColor(status),
      avatar: Icon(
        _getStatusIcon(status),
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildBatteryChip(int level) {
    return Chip(
      label: Text(
        '$level%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: _getBatteryColor(level),
      avatar: Icon(
        _getBatteryIcon(level),
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSpeedChip(double speed) {
    return Chip(
      label: Text(
        '${speed.toStringAsFixed(1)} km/h',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.blue[600],
      avatar: const Icon(
        Iconsax.speedometer,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLocationSection(EmployeeLocation employee) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationTile(Iconsax.location, 'Coordinates',
              '${employee.latitude.toStringAsFixed(6)}, ${employee.longitude.toStringAsFixed(6)}'),
          const Divider(height: 16),
          _buildLocationTile(Iconsax.map, 'Area', employee.areaName),
          const Divider(height: 16),
          _buildLocationTile(Iconsax.building, 'State/District',
              '${employee.state} / ${employee.district}'),
          const Divider(height: 16),
          _buildLocationTile(Iconsax.house, 'Taluka', employee.taluka),
        ],
      ),
    );
  }

  Widget _buildLocationTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.blue[600]),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmployeeListSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Text(
                  'TEAM MEMBERS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_employees.length} ACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final employee = _employees[index];
                return _buildEmployeeCard(employee);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeLocation employee) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectEmployee(employee),
        child: Container(
          decoration: BoxDecoration(
            gradient: employee == _selectedEmployee
                ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: employee == _selectedEmployee
                  ? Colors.blue.shade200!
                  : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar-${employee.id}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getStatusColor(employee.status),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        employee.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
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
                        employee.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.position,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              employee.areaName,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(employee.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        employee.status,
                        style: TextStyle(
                          color: _getStatusColor(employee.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${employee.latitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      '${employee.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Iconsax.activity;
      case 'moving':
        return Iconsax.driving;
      case 'idle':
        return Iconsax.clock;
      case 'offline':
        return Iconsax.wifi;
      default:
        return Iconsax.user;
    }
  }

  IconData _getBatteryIcon(int level) {
    if (level > 70) return Iconsax.battery_full;
    if (level > 30) return Iconsax.battery_3full3;
    return Iconsax.battery_empty3;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'moving':
        return Colors.blue;
      case 'idle':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 70) return Colors.green;
    if (level > 30) return Colors.orange;
    return Colors.red;
  }
}

class EmployeeLocation {
  final String id;
  final String name;
  final String position;
  final String avatarUrl;
  final DateTime lastUpdated;
  final double latitude;
  final double longitude;
  final String areaName;
  final String state;
  final String district;
  final String taluka;
  final String status;
  final int batteryLevel;
  final double speed;

  EmployeeLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.avatarUrl,
    required this.lastUpdated,
    required this.latitude,
    required this.longitude,
    required this.areaName,
    required this.state,
    required this.district,
    required this.taluka,
    required this.status,
    required this.batteryLevel,
    required this.speed,
  });
}