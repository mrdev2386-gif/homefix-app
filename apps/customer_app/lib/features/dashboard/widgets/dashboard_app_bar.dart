import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../notifications/presentation/notifications_screen.dart';

// ============================================================================
// REUSABLE WIDGET: Notification Bell Button
// ============================================================================
/// A fully tappable notification bell button with:
/// - Material + InkWell wrapper for proper ripple effect
/// - Minimum 48x48 tap target
/// - Accessible with semantic labels
/// - Badge support for unread count
class NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Open notifications',
      hint: 'Tap to view notifications',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.black12,
          child: Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String city;
  final String address;
  final VoidCallback onLocationTap;
  final VoidCallback onCartTap;

  const DashboardAppBar({
    super.key,
    required this.city,
    required this.address,
    required this.onLocationTap,
    required this.onCartTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  State<DashboardAppBar> createState() => _DashboardAppBarState();
}

class _DashboardAppBarState extends State<DashboardAppBar> {
  late final Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: InkWell(
        onTap: widget.onLocationTap,
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.city,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.address,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }
            
            return NotificationBellButton(
              unreadCount: unreadCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerNotificationsScreen(),
                  ),
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
          onPressed: widget.onCartTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
