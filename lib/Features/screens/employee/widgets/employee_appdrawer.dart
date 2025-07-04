import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ModernEmployeeDrawer extends StatefulWidget {
  @override
  _ModernEmployeeDrawerState createState() => _ModernEmployeeDrawerState();
}

class _ModernEmployeeDrawerState extends State<ModernEmployeeDrawer> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  final Color primaryColor = Color(0xFF6C7EE1);
  final Color backgroundColor = Colors.white;

  final List<DrawerItem> _drawerItems = [
    DrawerItem(icon: Icons.dashboard_rounded, title: "Dashboard"),
    DrawerItem(icon: Icons.calendar_today_rounded, title: "Attendance"),
    DrawerItem(icon: Icons.people_alt_rounded, title: "Team"),
    DrawerItem(icon: Icons.analytics_rounded, title: "Reports"),
    DrawerItem(icon: Icons.location_on_rounded, title: "Tracking"),
    DrawerItem(icon: Icons.settings_rounded, title: "Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 16,
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            // Header with fixed height container to prevent overflow
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 170,
                maxHeight: _isExpanded ? 280 : 170,
              ),
              child: _buildHeader(),
            ),
            // Menu items in an Expanded widget to take remaining space
            Expanded(
              child: _buildMenuItems(),
            ),
            // Footer with fixed height
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(), // Disable scrolling
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important for Column in Column
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: _isExpanded ? 40 : 30,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: Icon(Icons.person,
                      color: primaryColor,
                      size: _isExpanded ? 40 : 30),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            if (_isExpanded) ...[
              SizedBox(height: 5),
              Text(
                "John Doe",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Admin",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _buildProfileActionButton(FontAwesomeIcons.userEdit, "Edit"),
                  _buildProfileActionButton(Icons.logout, "Logout"),
                ],
              ),
              SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return ListView.builder(
      padding: EdgeInsets.only(top: 20),
      itemCount: _drawerItems.length,
      itemBuilder: (context, index) {
        final item = _drawerItems[index];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Material(
            color: _selectedIndex == index
                ? primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index
                            ? primaryColor.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: _selectedIndex == index
                            ? primaryColor
                            : Colors.black54,
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 15),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: _selectedIndex == index
                            ? primaryColor
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Spacer(),
                    if (_selectedIndex == index)
                      Container(
                        width: 5,
                        height: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(color: Colors.grey.shade300),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "v1.0.0",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.help_outline, color: Colors.black54),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.black54),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;

  DrawerItem({required this.icon, required this.title});
}