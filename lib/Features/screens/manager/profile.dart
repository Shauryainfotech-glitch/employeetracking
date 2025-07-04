import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController(text: "Alex Johnson");
  final TextEditingController _emailController = TextEditingController(text: "alex.johnson@company.com");
  final TextEditingController _phoneController = TextEditingController(text: "+1 (555) 123-4567");
  final TextEditingController _positionController = TextEditingController(text: "Senior Manager");
  final TextEditingController _departmentController = TextEditingController(text: "Operations");
  final TextEditingController _locationController = TextEditingController(text: "San Francisco, CA");

  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Iconsax.tick_circle : Iconsax.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile updated successfully!"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildProfileDetails(),
            const SizedBox(height: 24),
            _buildTeamSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[400]!, Colors.blue[800]!],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.camera, color: Colors.white, size: 20),
          ),
        ),
        Column(
          children: [
            Hero(
              tag: 'profile-picture',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: Image.network(
                    "https://randomuser.me/api/portraits/men/42.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _nameController.text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _positionController.text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEditableField(
              label: "Full Name",
              icon: Iconsax.user,
              controller: _nameController,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: "Email",
              icon: Iconsax.sms,
              controller: _emailController,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: "Phone",
              icon: Iconsax.call,
              controller: _phoneController,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: "Position",
              icon: Iconsax.briefcase,
              controller: _positionController,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: "Department",
              icon: Iconsax.building,
              controller: _departmentController,
            ),
            const Divider(height: 24),
            _buildEditableField(
              label: "Location",
              icon: Iconsax.location,
              controller: _locationController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _isEditing
              ? TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "My Team",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTeamMember("Sarah", "HR Manager", "https://randomuser.me/api/portraits/women/44.jpg"),
              _buildTeamMember("Michael", "Sales Lead", "https://randomuser.me/api/portraits/men/32.jpg"),
              _buildTeamMember("Emily", "Marketing", "https://randomuser.me/api/portraits/women/63.jpg"),
              _buildTeamMember("David", "Developer", "https://randomuser.me/api/portraits/men/75.jpg"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMember(String name, String role, String imageUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue[100]!, width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            role,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}