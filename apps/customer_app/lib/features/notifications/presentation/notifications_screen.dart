import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ==========================================
// HAPTIC FEEDBACK HELPER
// ==========================================

class HapticHelper {
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

  Future<void> heavyImpact() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.vibrate();
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final HapticHelper _haptic = HapticHelper();
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
            ? await NotificationsService.getNotification(lastNotification.id) 
                as DocumentSnapshot
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
    final unreadCount = context.select<NotificationsService, int>(
      (provider) => provider.unreadCount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(unreadCount),
      body: _isInitialLoading && _allNotifications.isEmpty
          ? _buildShimmerLoading()
          : _allNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationList(),
    );
  }

  PreferredSizeWidget _buildAppBar(int unreadCount) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications'),
          if (unreadCount > 0)
            Text(
              '$unreadCount unread',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.surface,
      elevation: 0,
      actions: [
        if (unreadCount > 0)
          TextButton.icon(
            onPressed: () => _markAllAsRead(),
            icon: const Icon(Icons.done_all, size: 20),
            label: const Text('Mark all read'),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'delete_all':
                _deleteAllNotifications();
                break;
              case 'settings':
                _openSettings();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete_all',
              child: Text('Delete all read'),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Text('Notification settings'),
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
          Text(
            'No notifications yet',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
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
                : AppColors.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead 
                  ? Colors.grey[200]! 
                  : AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              _buildNotificationIcon(notification),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyMedium.copyWith(
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
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
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
      case 'booking_confirmed':
        iconData = Icons.check_circle;
        backgroundColor = Colors.green;
        break;
      case 'booking_cancelled':
        iconData = Icons.cancel;
        backgroundColor = Colors.red;
        break;
      case 'technician_en_route':
      case 'technician_arrived':
        iconData = Icons.directions_car;
        backgroundColor = Colors.blue;
        break;
      case 'job_completed':
        iconData = Icons.task_alt;
        backgroundColor = Colors.green;
        break;
      case 'payment_success':
        iconData = Icons.payment;
        backgroundColor = Colors.green;
        break;
      case 'payment_failed':
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
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    await _haptic.selectionClick();
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text('Are you sure you want to delete this notification?'),
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
    // Haptic feedback based on priority
    if (notification.isHighPriority) {
      await _haptic.mediumImpact();
    } else {
      await _haptic.lightImpact();
    }

    // Mark as read
    if (!notification.isRead) {
      await NotificationsService.markAsRead(notification.id);
    }

    // Navigate based on deep link
    _navigateToScreen(notification);
  }

  void _navigateToScreen(NotificationModel notification) {
    final screen = notification.data['screen'] ?? '';
    final bookingId = notification.data['bookingId'] ?? '';
    final requestId = notification.data['requestId'] ?? '';

    // Determine navigation path
    switch (notification.type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'job_completed':
        if (bookingId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/booking/$bookingId',
            arguments: {'bookingId': bookingId},
          );
        }
        break;
      case 'technician_en_route':
      case 'technician_arrived':
        if (bookingId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/booking/$bookingId/tracking',
            arguments: {'bookingId': bookingId},
          );
        }
        break;
      case 'payment_success':
      case 'payment_failed':
        if (bookingId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/payment/$bookingId',
            arguments: {'bookingId': bookingId},
          );
        }
        break;
      default:
        if (screen.isNotEmpty) {
          Navigator.pushNamed(context, '/$screen');
        }
    }
  }

  void _markAllAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await NotificationsService.markAllAsRead(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to mark all as read');
    }
  }

  void _deleteNotification(String notificationId) async {
    try {
      await NotificationsService.deleteNotification(notificationId);
    } catch (e) {
      _showErrorSnackbar('Failed to delete notification');
    }
  }

  void _deleteAllNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await NotificationsService.deleteAllNotifications(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications deleted')),
          );
        }
      } catch (e) {
        _showErrorSnackbar('Failed to delete notifications');
      }
    }
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/settings/notifications');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
