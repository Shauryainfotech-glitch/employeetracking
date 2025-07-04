import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _locationTracking = true;
  bool _biometricAuth = false;
  String _selectedTheme = 'System Default';
  final List<String> _themes = ['System Default', 'Light', 'Dark'];
  double _mapOpacity = 0.8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildAppearanceSection(),
              _buildSecuritySection(),
              _buildNotificationSection(),
              _buildLocationSection(),
              _buildAccountSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage your app preferences',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance'),
        _buildThemeSelector(),
        _buildDarkModeSwitch(),
        _buildMapOpacitySlider(),
        _buildDivider(),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Security'),
        _buildBiometricAuthSwitch(),
        _buildChangePasswordTile(),
        _buildDivider(),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Notifications'),
        _buildNotificationSwitch(),
        _buildNotificationSoundTile(),
        _buildDivider(),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Location'),
        _buildLocationTrackingSwitch(),
        _buildLocationAccuracyTile(),
        _buildDivider(),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Account'),
        _buildEditProfileTile(),
        SizedBox(height: 24),
        _buildLogoutButton(),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1),
    );
  }

  Widget _buildDarkModeSwitch() {
    return _buildSettingTile(
      icon: Icons.dark_mode,
      title: 'Dark Mode',
      trailing: SizedBox(
        width: 50,
        child: FlutterSwitch(
          width: 50,
          height: 28,
          toggleSize: 24,
          value: _darkMode,
          borderRadius: 30,
          padding: 2,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300]!,
          onToggle: (val) {
            setState(() => _darkMode = val);
          },
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return _buildSettingTile(
      icon: Icons.color_lens,
      title: 'App Theme',
      trailing: DropdownButton<String>(
        value: _selectedTheme,
        underline: Container(),
        items: _themes.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() => _selectedTheme = newValue!);
        },
      ),
    );
  }

  Widget _buildMapOpacitySlider() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Icon(Icons.opacity, color: Colors.grey[600], size: 24),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map Opacity',
                  style: TextStyle(fontSize: 16),
                ),
                Slider(
                  value: _mapOpacity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _mapOpacity.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() => _mapOpacity = value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch() {
    return _buildSettingTile(
      icon: Icons.notifications_active,
      title: 'Notifications',
      trailing: SizedBox(
        width: 50,
        child: FlutterSwitch(
          width: 50,
          height: 28,
          toggleSize: 24,
          value: _notificationsEnabled,
          borderRadius: 30,
          padding: 2,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300]!,
          onToggle: (val) {
            setState(() => _notificationsEnabled = val);
          },
        ),
      ),
    );
  }

  Widget _buildLocationTrackingSwitch() {
    return _buildSettingTile(
      icon: Icons.location_on,
      title: 'Location Tracking',
      trailing: SizedBox(
        width: 50,
        child: FlutterSwitch(
          width: 50,
          height: 28,
          toggleSize: 24,
          value: _locationTracking,
          borderRadius: 30,
          padding: 2,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300]!,
          onToggle: (val) {
            setState(() => _locationTracking = val);
          },
        ),
      ),
    );
  }

  Widget _buildBiometricAuthSwitch() {
    return _buildSettingTile(
      icon: Icons.fingerprint,
      title: 'Biometric Authentication',
      trailing: SizedBox(
        width: 50,
        child: FlutterSwitch(
          width: 50,
          height: 28,
          toggleSize: 24,
          value: _biometricAuth,
          borderRadius: 30,
          padding: 2,
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300]!,
          onToggle: (val) {
            setState(() => _biometricAuth = val);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationSoundTile() {
    return _buildSettingTile(
      icon: Icons.volume_up,
      title: 'Notification Sound',
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Open notification sound settings
      },
    );
  }

  Widget _buildLocationAccuracyTile() {
    return _buildSettingTile(
      icon: Icons.gps_fixed,
      title: 'Location Accuracy',
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Open location accuracy settings
      },
    );
  }

  Widget _buildChangePasswordTile() {
    return _buildSettingTile(
      icon: Icons.lock,
      title: 'Change Password',
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Open change password screen
      },
    );
  }

  Widget _buildEditProfileTile() {
    return _buildSettingTile(
      icon: Icons.person,
      title: 'Edit Profile',
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Open edit profile screen
      },
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[400],
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Log Out',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          onPressed: () {
            // Handle logout
          },
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}