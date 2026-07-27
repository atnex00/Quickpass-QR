import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/employee/leave_history_screen.dart';
import '../screens/supervisor/supervisor_dashboard.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined,
              color: color ?? context.onPrimary),
          if (notifProv.hasUnread)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: context.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color ?? context.onPrimary,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${notifProv.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        notifProv.reset();
        final auth = context.read<AuthProvider>();
        if (auth.isSupervisor || auth.isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SupervisorDashboard()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaveHistoryScreen()),
          );
        }
      },
    );
  }
}
