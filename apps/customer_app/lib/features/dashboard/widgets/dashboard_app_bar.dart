import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../screens/notifications_screen.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: InkWell(
        onTap: onLocationTap,
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
                        city,
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
                    address,
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
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('notifications')
              .where('isRead', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            int unreadCount = 0;
            if (snapshot.hasData) {
              unreadCount = snapshot.data!.docs.length;
            }
            
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                  onPressed: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
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
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
          onPressed: onCartTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
