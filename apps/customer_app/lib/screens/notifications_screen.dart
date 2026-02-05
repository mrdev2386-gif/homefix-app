import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/services/notifications_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
       return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all as read
              final batch = FirebaseFirestore.instance.batch();
              final snapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .get();
              
              for (var doc in snapshot.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final id = notifications[index].id;
              final isRead = notification['isRead'] ?? false;
              final timestamp = notification['createdAt'] as Timestamp?;
              final timeStr = timestamp != null 
                  ? DateFormat.yMMMd().add_jm().format(timestamp.toDate()) 
                  : 'Just now';

              return Container(
                color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey[200] : Colors.blue[100],
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : Colors.blue,
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      NotificationsService.markAsRead(id);
                    }
                    // Handle navigation if needed based on 'type' or 'data'
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
