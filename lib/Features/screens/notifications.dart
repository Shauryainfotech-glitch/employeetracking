import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:badges/badges.dart' as badges;

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'New Task Assigned',
      message: 'You have been assigned a new project: Mobile App Redesign',
      time: DateTime.now().subtract(Duration(minutes: 5)),
      isRead: false,
      type: NotificationType.task,
      icon: Icons.task_rounded,
      color: Colors.blue,
    ),
    NotificationItem(
      id: '2',
      title: 'Attendance Approved',
      message: 'Your attendance for yesterday has been approved by HR',
      time: DateTime.now().subtract(Duration(hours: 2)),
      isRead: false,
      type: NotificationType.approval,
      icon: Icons.verified_user_rounded,
      color: Colors.green,
    ),
    NotificationItem(
      id: '3',
      title: 'Meeting Reminder',
      message: 'Team sync meeting starts in 15 minutes',
      time: DateTime.now().subtract(Duration(hours: 5)),
      isRead: true,
      type: NotificationType.reminder,
      icon: Icons.calendar_today_rounded,
      color: Colors.orange,
    ),
    NotificationItem(
      id: '4',
      title: 'New Message',
      message: 'John Doe: "Hey, can you review the latest designs?"',
      time: DateTime.now().subtract(Duration(days: 1)),
      isRead: true,
      type: NotificationType.message,
      icon: Icons.chat_bubble_rounded,
      color: Colors.purple,
    ),
    NotificationItem(
      id: '5',
      title: 'System Update',
      message: 'New version 2.3.0 is available with bug fixes',
      time: DateTime.now().subtract(Duration(days: 2)),
      isRead: true,
      type: NotificationType.system,
      icon: Icons.system_update_rounded,
      color: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.checklist_rounded),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: Icon(Icons.filter_alt_rounded),
            onPressed: _showFilterOptions,
            tooltip: 'Filter notifications',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.separated(
                padding: EdgeInsets.only(top: 8),
                itemCount: _notifications.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildNotificationItem(_notifications[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              badges.Badge(
                badgeContent: Text(
                  unreadCount.toString(),
                  style: TextStyle(color: Colors.white),
                ),
                showBadge: unreadCount > 0,
                child: Icon(Icons.notifications_active_rounded, size: 24),
              ),
              SizedBox(width: 8),
              Text(
                '$unreadCount Unread',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark all as read',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red[100],
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      secondaryBackground: Container(
        color: Colors.red[100],
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Notification'),
            content: Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  _notifications.add(notification);
                  _notifications.sort((a, b) => b.time.compareTo(a.time));
                });
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          setState(() {
            notification.isRead = true;
          });
          _showNotificationDetails(notification);
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: notification.isRead
                                ? Colors.grey[800]
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          _formatTime(notification.time),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildNotificationTypeChip(notification.type),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTypeChip(NotificationType type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getTypeText(type),
        style: TextStyle(
          fontSize: 12,
          color: _getTypeColor(type),
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return Colors.blue;
      case NotificationType.approval:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.message:
        return Colors.purple;
      case NotificationType.system:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(NotificationType type) {
    return type.toString().split('.').last.capitalize();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Future<void> _refreshNotifications() async {
    // Simulate network request
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _notifications.sort((a, b) => b.time.compareTo(a.time));
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...NotificationType.values.map((type) {
                return ListTile(
                  leading: Icon(
                    _getIconForType(type),
                    color: _getTypeColor(type),
                  ),
                  title: Text(_getTypeText(type)),
                  trailing: Switch(
                    value: true, // You would track filter state here
                    onChanged: (value) {},
                  ),
                  onTap: () {
                    // Implement filter logic
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

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.task:
        return Icons.task_rounded;
      case NotificationType.approval:
        return Icons.verified_user_rounded;
      case NotificationType.reminder:
        return Icons.calendar_today_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
      case NotificationType.system:
        return Icons.system_update_rounded;
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 18,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy - hh:mm a').format(notification.time),
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            if (notification.type == NotificationType.task ||
                notification.type == NotificationType.message)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to relevant screen
                },
                child: Text('View Details'),
              ),
          ],
        );
      },
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final NotificationType type;
  final IconData icon;
  final Color color;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
    required this.icon,
    required this.color,
  });
}

enum NotificationType {
  task,
  approval,
  reminder,
  message,
  system,
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
