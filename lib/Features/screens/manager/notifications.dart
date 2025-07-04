import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _selectedFilter = "All"; // "All", "Unread", "Important"
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: "1",
      title: "New Task Assigned",
      message: "You have a new task from the HR team. Please review it.",
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      isImportant: true,
      category: "Task",
    ),
    NotificationModel(
      id: "2",
      title: "Leave Request Approved",
      message: "Your leave request for May 15 has been approved.",
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      isImportant: false,
      category: "Leave",
    ),
    NotificationModel(
      id: "3",
      title: "Urgent: Meeting Reminder",
      message: "Team sync meeting in 15 minutes. Don’t forget!",
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
      isImportant: true,
      category: "Meeting",
    ),
    NotificationModel(
      id: "4",
      title: "New Employee Onboarded",
      message: "John Doe has joined the Sales team today.",
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      isImportant: false,
      category: "HR",
    ),
    NotificationModel(
      id: "5",
      title: "Project Deadline Extended",
      message: "The deadline for Project X has been extended to June 30.",
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: false,
      isImportant: true,
      category: "Project",
    ),
  ];

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case "Unread":
        return _notifications.where((n) => !n.isRead).toList();
      case "Important":
        return _notifications.where((n) => n.isImportant).toList();
      default:
        return _notifications;
    }
  }

  void _markAsRead(String id) {
    setState(() {
      _notifications.firstWhere((n) => n.id == id).isRead = true;
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification deleted"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: () => _showFilterBottomSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = _filteredNotifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ["All", "Unread", "Important"].map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              selectedColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: _selectedFilter == filter ? Colors.blue[800] : Colors.grey[700],
                fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Iconsax.trash, color: Colors.red),
      ),
      onDismissed: (direction) => _deleteNotification(notification.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _markAsRead(notification.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isImportant ? Colors.red[100]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(notification.category),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(notification.category),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: notification.isRead ? Colors.black87 : Colors.blue[800],
                            ),
                          ),
                          if (notification.isImportant) ...[
                            const SizedBox(width: 8),
                            const Icon(Iconsax.warning_2, size: 16, color: Colors.red),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, h:mm a').format(notification.time),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (!notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "New",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.notification,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You’re all caught up!",
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Filter Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...["All", "Unread", "Important"].map((filter) {
                return ListTile(
                  title: Text(filter),
                  trailing: _selectedFilter == filter
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Task":
        return Colors.purple;
      case "Leave":
        return Colors.green;
      case "Meeting":
        return Colors.orange;
      case "HR":
        return Colors.blue;
      case "Project":
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Task":
        return Iconsax.task;
      case "Leave":
        return Iconsax.calendar;
      case "Meeting":
        return Iconsax.calendar_1;
      case "HR":
        return Iconsax.profile_2user;
      case "Project":
        return Iconsax.document;
      default:
        return Iconsax.notification;
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final bool isImportant;
  final String category;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.isImportant,
    required this.category,
  });
}