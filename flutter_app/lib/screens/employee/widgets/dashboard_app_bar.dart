import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/notification_bell.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.onPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ColorFiltered(
                        colorFilter: ColorFilter.mode(context.onPrimary, BlendMode.srcIn),
                        child: Image.asset('assets/icon/app-icon.png',
                            width: 22, height: 22)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quickpass',
                    style: TextStyle(
                      fontSize: responsiveFontSize(context, 20),
                      fontWeight: FontWeight.w700,
                      color: context.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  const NotificationBell(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
