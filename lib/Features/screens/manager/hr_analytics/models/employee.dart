class Employee {
  final String id;
  final String name;
  final String position;
  final int productivity;
  final int attendance;
  final DateTime lastActive;
  final bool isActive;
  final String department;
  final List<String> skills;
  final DateTime joinDate;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.productivity,
    required this.attendance,
    required this.lastActive,
    required this.isActive,
    required this.department,
    required this.skills,
    required this.joinDate,
  });
}