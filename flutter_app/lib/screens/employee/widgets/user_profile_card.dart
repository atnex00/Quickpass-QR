import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../config/theme.dart';
import '../../../models/employee.dart';
import '../../../utils/responsive.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key, required this.user});
  final Employee? user;

  static String? _photo(Employee? u) => AppConfig.photoUrl(u?.profilePhoto);

  static String _initial(Employee? user) {
    final name = user?.fullName;
    return (name != null && name.isNotEmpty ? name[0] : 'U').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.primaryBlue.withValues(alpha: 0.1),
            backgroundImage: _photo(user) != null
                ? NetworkImage(_photo(user)!)
                : null,
            child: _photo(user) == null
                ? Text(
                    _initial(user),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: context.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.onSurfaceVariant,
                  ),
                ),
                Text(
                  user?.fullName ?? '',
                  style: TextStyle(
                    fontSize: responsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.position ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.01,
                          color: context.secondary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '\u2022',
                        style: TextStyle(fontSize: 10, color: context.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      'ID: ${user?.employeeId ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.05,
                        color: context.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
