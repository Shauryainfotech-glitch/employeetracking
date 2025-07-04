import 'package:flutter/material.dart';


class ModernAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showNotifications;
  final bool showProfile;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  ModernAppBar({
    required this.title,
    this.showSearch = true,
    this.showNotifications = true,
    this.showProfile = true,
    this.onSearchPressed,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(120);

  @override
  _ModernAppBarState createState() => _ModernAppBarState();
}

class _ModernAppBarState extends State<ModernAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A11CB),
            Color(0xFF2575FC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!_isSearching) ...[
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                    _buildTitle(),
                    _buildActionIcons(),
                  ] else ...[
                    Expanded(
                      child: _buildSearchField(),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleSearch,
                    ),
                  ],
                ],
              ),
            ),
            _buildTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _isSearching
          ? SizedBox.shrink()
          : Text(
        widget.title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSearch)
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
        if (widget.showNotifications)
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.doorbell, color: Colors.white),
                onPressed: widget.onNotificationPressed,
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        if (widget.showProfile)
          GestureDetector(
            onTap: widget.onProfilePressed,
            child: Container(
              width: 36,
              height: 36,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                image: DecorationImage(
                  image: NetworkImage(
                      'https://randomuser.me/api/portraits/men/41.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        cursorColor: Colors.white,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildTabItem('Dashboard', Icons.dashboard, isActive: true),
          _buildTabItem('Attendance', Icons.calendar_today),
          _buildTabItem('Team', Icons.people),
          _buildTabItem('Reports', Icons.analytics),
          _buildTabItem('Settings', Icons.settings),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, IconData icon, {bool isActive = false}) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}