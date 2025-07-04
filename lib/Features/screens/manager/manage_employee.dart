import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class EmployeeManagementScreen extends StatefulWidget {
  @override
  _EmployeeManagementScreenState createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Development', 'Design', 'Marketing', 'Management'];
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Employee Management'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/women/65.jpg'),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[800],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[800],
          tabs: [
            Tab(text: 'All Employees'),
            Tab(text: 'Active'),
            Tab(text: 'On Leave'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          if (_showAdvancedFilters) _buildAdvancedFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeeList(_filterEmployees('All')),
                _buildEmployeeList(_filterEmployees('Active')),
                _buildEmployeeList(_filterEmployees('On Leave')),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEmployeeDialog(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search employees...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          selectedColor: Colors.blue[800],
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter ? Colors.white : Colors.black,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _showAdvancedFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _showAdvancedFilters ? Colors.blue[800] : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
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
                  Text('Advanced Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _showAdvancedFilters = false;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 8),
              _buildFilterOption('High Performers (90%+)', false),
              _buildFilterOption('Low Attendance (<80%)', false),
              _buildFilterOption('Recently Joined (<6 months)', false),
              _buildFilterOption('Contract Ending Soon', false),
              SizedBox(height: 8),
              Text('Productivity Range', style: TextStyle(color: Colors.grey[600])),
              RangeSlider(
                values: RangeValues(0, 100),
                min: 0,
                max: 100,
                divisions: 10,
                labels: RangeLabels('0%', '100%'),
                onChanged: (RangeValues values) {},
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = false;
                  });
                },
                child: Text('Apply Filters'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool value) {
    return CheckboxListTile(
      title: Text(label, style: TextStyle(fontSize: 14)),
      value: value,
      onChanged: (newValue) {},
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  List<Employee> _filterEmployees(String tab) {
    List<Employee> filtered = dummyEmployees;

    // Apply tab filter
    if (tab == 'Active') {
      filtered = filtered.where((e) => e.status == EmployeeStatus.active).toList();
    } else if (tab == 'On Leave') {
      filtered = filtered.where((e) => e.status == EmployeeStatus.onLeave).toList();
    }

    // Apply department filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((e) => e.department == _selectedFilter).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((e) =>
      e.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          e.position.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          e.department.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }

    return filtered;
  }

  Widget _buildEmployeeList(List<Employee> employees) {
    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/empty.svg',
              height: 150,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text('No employees found', style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 8),
            Text('Try adjusting your filters', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: employees.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final employee = employees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return InkWell(
      onTap: () => _showEmployeeDetails(employee),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(employee.photoUrl),
                  ),
                  if (employee.status == EmployeeStatus.active)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      employee.position,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDepartmentColor(employee.department).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            employee.department,
                            style: TextStyle(
                              color: _getDepartmentColor(employee.department),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Spacer(),
                        if (employee.status == EmployeeStatus.onLeave)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.beach_access, size: 14, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'On Leave',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => _showEmployeeActions(employee),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'Development':
        return Colors.blue;
      case 'Design':
        return Colors.purple;
      case 'Marketing':
        return Colors.green;
      case 'Management':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showEmployeeDetails(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  image: DecorationImage(
                    image: NetworkImage('https://source.unsplash.com/random/800x600/?office'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(employee.photoUrl),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            employee.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: employee.status == EmployeeStatus.active
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              employee.status == EmployeeStatus.active ? 'Active' : 'On Leave',
                              style: TextStyle(
                                color: employee.status == EmployeeStatus.active
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        employee.position,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          _buildDetailChip(Icons.business, employee.department),
                          SizedBox(width: 12),
                          _buildDetailChip(Icons.email, employee.email),
                          SizedBox(width: 12),
                          _buildDetailChip(Icons.phone, employee.phone),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Performance Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricCard('Productivity', '${employee.productivity}%', Icons.trending_up,
                              _getPerformanceColor(employee.productivity)),
                          _buildMetricCard('Attendance', '${employee.attendance}%', Icons.calendar_today,
                              _getAttendanceColor(employee.attendance)),
                          _buildMetricCard('Projects', employee.projects.toString(), Icons.work_outline, Colors.purple),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Joined ${DateFormat('MMMM yyyy').format(employee.joinDate)} • ${employee.yearsOfExperience} years experience',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        employee.bio,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: Text('Message'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeActions(Employee employee) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person_outline),
                title: Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _showEmployeeDetails(employee);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit Employee'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditEmployeeDialog(employee);
                },
              ),
              ListTile(
                leading: Icon(Icons.email_outlined),
                title: Text('Send Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageDialog(employee);
                },
              ),
              if (employee.status == EmployeeStatus.active)
                ListTile(
                  leading: Icon(Icons.beach_access),
                  title: Text('Mark as On Leave'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateEmployeeStatus(employee, EmployeeStatus.onLeave);
                  },
                ),
              if (employee.status == EmployeeStatus.onLeave)
                ListTile(
                  leading: Icon(Icons.work_outline),
                  title: Text('Mark as Active'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateEmployeeStatus(employee, EmployeeStatus.active);
                  },
                ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete Employee', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(employee);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Full Name'),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Position'),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Department'),
                  items: _filters
                      .where((f) => f != 'All')
                      .map((department) => DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  ))
                      .toList(),
                  onChanged: (value) {},
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('New employee added successfully')),
                );
              },
              child: Text('Add Employee'),
            ),
          ],
        );
      },
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Full Name'),
                  controller: TextEditingController(text: employee.name),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Position'),
                  controller: TextEditingController(text: employee.position),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Department'),
                  value: employee.department,
                  items: _filters
                      .where((f) => f != 'All')
                      .map((department) => DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  ))
                      .toList(),
                  onChanged: (value) {},
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Productivity (%)'),
                  controller: TextEditingController(text: employee.productivity.toString()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Attendance (%)'),
                  controller: TextEditingController(text: employee.attendance.toString()),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Employee updated successfully')),
                );
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageDialog(Employee employee) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Message ${employee.name}'),
          content: TextField(
            controller: messageController,
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Message sent to ${employee.name}')),
                );
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _updateEmployeeStatus(Employee employee, EmployeeStatus newStatus) {
    setState(() {
      employee.status = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${employee.name} marked as ${newStatus == EmployeeStatus.active ? 'Active' : 'On Leave'}'),
      ),
    );
  }

  void _showDeleteConfirmation(Employee employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Employee?'),
          content: Text('Are you sure you want to delete ${employee.name} from the system? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  dummyEmployees.remove(employee);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${employee.name} has been deleted')),
                );
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Color _getPerformanceColor(int performance) {
    if (performance >= 90) return Colors.green;
    if (performance >= 75) return Colors.blue;
    if (performance >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getAttendanceColor(int attendance) {
    if (attendance >= 95) return Colors.green;
    if (attendance >= 85) return Colors.blue;
    if (attendance >= 70) return Colors.orange;
    return Colors.red;
  }
}

enum EmployeeStatus { active, onLeave }

class Employee {
  final String id;
  final String name;
  final String position;
  final String department;
  final String email;
  final String phone;
  final String photoUrl;
  final String bio;
  final int productivity;
  final int attendance;
  final int projects;
  final int yearsOfExperience;
  final DateTime joinDate;
  EmployeeStatus status;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.bio,
    required this.productivity,
    required this.attendance,
    required this.projects,
    required this.yearsOfExperience,
    required this.joinDate,
    required this.status,
  });
}

List<Employee> dummyEmployees = [
  Employee(
    id: '1',
    name: 'Sarah Johnson',
    position: 'Senior Flutter Developer',
    department: 'Development',
    email: 'sarah.j@company.com',
    phone: '+1 (555) 123-4567',
    photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
    bio: 'Experienced mobile developer with 5+ years of experience building cross-platform applications. Specializes in Flutter and Firebase.',
    productivity: 92,
    attendance: 98,
    projects: 8,
    yearsOfExperience: 5,
    joinDate: DateTime(2019, 3, 15),
    status: EmployeeStatus.active,
  ),
  Employee(
    id: '2',
    name: 'Michael Chen',
    position: 'UI/UX Designer',
    department: 'Design',
    email: 'michael.c@company.com',
    phone: '+1 (555) 234-5678',
    photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
    bio: 'Creative designer with a passion for user-centered design. Creates beautiful and functional interfaces for web and mobile.',
    productivity: 88,
    attendance: 95,
    projects: 12,
    yearsOfExperience: 4,
    joinDate: DateTime(2020, 7, 22),
    status: EmployeeStatus.active,
  ),
  Employee(
    id: '3',
    name: 'Emily Rodriguez',
    position: 'Marketing Manager',
    department: 'Marketing',
    email: 'emily.r@company.com',
    phone: '+1 (555) 345-6789',
    photoUrl: 'https://randomuser.me/api/portraits/women/63.jpg',
    bio: 'Strategic marketing professional with expertise in digital campaigns and brand development. Leads our marketing team with creativity and data-driven decisions.',
    productivity: 85,
    attendance: 90,
    projects: 6,
    yearsOfExperience: 7,
    joinDate: DateTime(2018, 11, 5),
    status: EmployeeStatus.onLeave,
  ),
  Employee(
    id: '4',
    name: 'David Kim',
    position: 'Product Manager',
    department: 'Management',
    email: 'david.k@company.com',
    phone: '+1 (555) 456-7890',
    photoUrl: 'https://randomuser.me/api/portraits/men/75.jpg',
    bio: 'Product leader with technical background. Bridges the gap between business, design, and engineering to build products users love.',
    productivity: 90,
    attendance: 97,
    projects: 5,
    yearsOfExperience: 6,
    joinDate: DateTime(2019, 9, 30),
    status: EmployeeStatus.active,
  ),
  Employee(
    id: '5',
    name: 'Jessica Williams',
    position: 'QA Engineer',
    department: 'Development',
    email: 'jessica.w@company.com',
    phone: '+1 (555) 567-8901',
    photoUrl: 'https://randomuser.me/api/portraits/women/28.jpg',
    bio: 'Detail-oriented quality assurance specialist ensuring our products meet the highest standards before reaching customers.',
    productivity: 87,
    attendance: 93,
    projects: 9,
    yearsOfExperience: 3,
    joinDate: DateTime(2021, 2, 14),
    status: EmployeeStatus.active,
  ),
  Employee(
    id: '6',
    name: 'Robert Taylor',
    position: 'DevOps Engineer',
    department: 'Development',
    email: 'robert.t@company.com',
    phone: '+1 (555) 678-9012',
    photoUrl: 'https://randomuser.me/api/portraits/men/41.jpg',
    bio: 'Cloud infrastructure specialist focused on building scalable and reliable deployment pipelines. Automates everything possible.',
    productivity: 94,
    attendance: 96,
    projects: 7,
    yearsOfExperience: 5,
    joinDate: DateTime(2020, 5, 18),
    status: EmployeeStatus.onLeave,
  ),
];