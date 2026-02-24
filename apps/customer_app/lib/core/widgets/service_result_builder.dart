
import 'package:flutter/material.dart';
import '../models/service_result.dart';

class ServiceResultBuilder<T> extends StatelessWidget {
  final Stream<ServiceResult<T>> stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final VoidCallback? onRetry;

  const ServiceResultBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceResult<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }

        final result = snapshot.data;
        
        if (result == null || result.isLoading) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }

        if (result.isError) {
          return errorWidget ?? _buildDefaultError(context, result.errorMessage ?? 'Something went wrong');
        }

        if (result.isEmpty) {
          return emptyWidget ?? _buildDefaultEmpty(context);
        }

        if (result.isSuccess && result.data != null) {
          return builder(context, result.data as T);
        }

        return errorWidget ?? _buildDefaultError(context, 'Unexpected state');
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 16),
          Text('Nothing found here', style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}
