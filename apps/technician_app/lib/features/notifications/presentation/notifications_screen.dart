import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/app_theme.dart';

// ==========================================
// HAPTIC FEEDBACK HELPER
// ==========================================

class HapticFeedback {
  Future<void> lightImpact() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await HapticFeedback.vibrate();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> mediumImpact() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await HapticFeedback.vibrate();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}

class TechnicianNotificationsScreen extends StatefulWidget {
  const TechnicianNotificationsScreen({super.key});

  @override
  State<Tech technicianNotificationsScreen> createState() => _TechnicianNotificationsScreenState();
}

class _TechnicianNotificationsScreenState extends State<TechnicianNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final HapticFeedback _haptic = HapticFeedback();
  bool _isLoadingMore = false;
  static const int _pageSize = 20;
  List<NotificationModel> _allNotifications = [];
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialNotifications();
  }

  Future<void> _loadInitialNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isInitialLoading = true);
    
    try {
      final notifications = await NotificationsService.getNotificationsPaginated(
        userId,
        limit: _pageSize,
      );
      
      if (mounted) {
        setState(() {
          _allNotifications = notifications;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
        _showErrorSnackbar('Failed to load notifications');
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final lastNotification = _allNotifications.isNotEmpty ? _allNotifications.last : null;
      final newNotifications = await NotificationsService.getNotificationsPaginated(
        userId,
        limit: _pageSize,
        startAfter: lastNotification != null 
            ? await NotificationsService.getNotificationsPaginated(
                userId,
                limit: 1,
                startAfter: await _getDocSnapshot(lastNotification.id),
              ).then((_) => null)
                as DocumentSnapshot?
                : null,
      );

      if (mounted) {
        setState(() {
          _allNotifications.addAll(newNotifications);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<DocumentSnapshot> _getDocSnapshot(String docId) async {
    return await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .get();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.background,
      appBar: _buildAppBar(),
      body: _isInitialLoading && _allNotifications.isEmpty
          ? _buildShimmerLoading()
          : _allNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications'),
          Text(
            'Job updates and alerts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      backgroundColor: AppThemeColors.surface,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete_all') {
              _deleteAllNotifications();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete_all',
              child: Text('Delete all read'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerTile(),
    );
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see job updates here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadInitialNotifications,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _allNotifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _allNotifications.length) {
            return _buildLoadingMoreIndicator();
          }
          return _buildNotificationTile(_allNotifications[index]);
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation();
      },
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? Colors.white 
                : AppThemeColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead 
                  ? Colors.grey[200]! 
                  : AppThemeColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.isHighPriority)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'URGENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppThemeColors.primary,
                              shape: BoxShape.circle,
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
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData iconData;
    Color backgroundColor;

    switch (notification.type) {
      case 'new_request_nearby':
      case 'new_instant_booking':
        iconData = Icons.work;
        backgroundColor = Colors.blue;
        break;
      case 'payout_processed':
        iconData = Icons.payments;
        backgroundColor = Colors.green;
        break;
      case 'new_review':
        iconData = Icons.star;
        backgroundColor = Colors.orange;
        break;
      case 'booking_cancelled':
        iconData = Icons.cancel;
        backgroundColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        backgroundColor = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: backgroundColor,
        size: 24,
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete'),
            content: const Text('Remove this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _onNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      await NotificationsService.markAsRead(notification.id);
    }
    _navigateToScreen(notification);
  }

  void _navigateToScreen(NotificationModel notification) {
    switch (notification.type) {
      case 'new_request_nearby':
      case 'new_instant_booking':
        Navigator.pushNamed(context, '/requests');
        break;
      case 'payout_processed':
        Navigator.pushNamed(context, '/wallet');
        break;
      case 'new_review':
        Navigator.pushNamed(context, '/reviews');
        break;
      default:
        if (notification.data['screen'] != null) {
          Navigator.pushNamed(context, '/${notification.data['screen']}');
        }
    }
  }

  void _deleteNotification(String notificationId) async {
    try {
      await NotificationsService.deleteNotification(notificationId);
    } catch (e) {
      _showErrorSnackbar('Failed to delete');
    }
  }

  void _deleteAllNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All'),
        content: const Text('Delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implementation for deleting all
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Import for DocumentSnapshot
import 'package:cloud_firestore/cloud_firestore.dart';
