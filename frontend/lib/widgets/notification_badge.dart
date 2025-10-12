import 'package:flutter/material.dart';
import '../services/notification_manager.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.fontSize,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationManager(),
      builder: (context, _) {
        final notificationManager = NotificationManager();
        final unreadCount = notificationManager.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: padding ?? const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor ?? Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: fontSize ?? 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;

  const NotificationIcon({
    Key? key,
    this.onTap,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      child: IconButton(
        icon: Icon(
          Icons.notifications,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 24,
        ),
        onPressed: onTap ?? () {
          Navigator.pushNamed(context, '/notifications');
        },
      ),
    );
  }
}