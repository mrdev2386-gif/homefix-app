import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Smart Empty State Widget (Section 5)
/// Premium empty UI with icon, text, and retry button
class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const EmptyStateView({
    super.key,
    this.title = 'No services found',
    this.subtitle = 'Try adjusting your search or category',
    this.icon = Icons.search_off_rounded,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  retryLabel ?? 'Try Again',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error State Widget (Section 6)
/// Handles loading, permission denied, failed-precondition, network errors
class ErrorStateView extends StatelessWidget {
  final ErrorType errorType;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.errorType,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 56,
                color: _getIconColor(),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              _getTitle(),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              _getSubtitle(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Retry',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (errorType) {
      case ErrorType.networkError:
        return Colors.red.shade50;
      case ErrorType.permissionDenied:
        return Colors.orange.shade50;
      case ErrorType.failedPrecondition:
        return Colors.blue.shade50;
      case ErrorType.unknown:
        return Colors.grey.shade100;
    }
  }

  IconData _getIcon() {
    switch (errorType) {
      case ErrorType.networkError:
        return Icons.wifi_off_rounded;
      case ErrorType.permissionDenied:
        return Icons.lock_outline_rounded;
      case ErrorType.failedPrecondition:
        return Icons.build_circle_outlined;
      case ErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  Color _getIconColor() {
    switch (errorType) {
      case ErrorType.networkError:
        return AppTheme.errorColor;
      case ErrorType.permissionDenied:
        return Colors.orange;
      case ErrorType.failedPrecondition:
        return Colors.blue;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  String _getTitle() {
    switch (errorType) {
      case ErrorType.networkError:
        return 'No Internet Connection';
      case ErrorType.permissionDenied:
        return 'Access Denied';
      case ErrorType.failedPrecondition:
        return 'Service Temporarily Unavailable';
      case ErrorType.unknown:
        return 'Something Went Wrong';
    }
  }

  String _getSubtitle() {
    switch (errorType) {
      case ErrorType.networkError:
        return 'Please check your internet connection and try again';
      case ErrorType.permissionDenied:
        return 'You don\'t have permission to access this content';
      case ErrorType.failedPrecondition:
        return 'We\'re working on fixing this issue. Please try again later';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again';
    }
  }
}

/// Error types for proper error handling
enum ErrorType {
  networkError,
  permissionDenied,
  failedPrecondition,
  unknown,
}

/// Loading State Widget
class LoadingStateView extends StatelessWidget {
  final String? message;

  const LoadingStateView({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
