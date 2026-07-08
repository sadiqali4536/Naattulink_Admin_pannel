// File: lib/MVVM/utils/notification.dart

import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int count;

  const NotificationBadge({
    super.key,
    required this.icon,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: const Color.fromARGB(255, 92, 92, 92),size: 30,),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            bottom: 19,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 15,
                minHeight: 15,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
