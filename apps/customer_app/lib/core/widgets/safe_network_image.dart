import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SafeNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  
  final String? serviceName;
  final bool usePlaceholder;
  final String? fallbackUrl;
  
  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
    this.serviceName,
    this.usePlaceholder = true,
    this.fallbackUrl,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  late String _currentUrl;
  bool _primaryFailed = false;
  
  @override
  void initState() {
    super.initState();
    _currentUrl = _getValidUrl() ?? AppConstants.fallbackServiceImage;
  }

  @override
  void didUpdateWidget(SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _primaryFailed = false;
      _currentUrl = _getValidUrl() ?? AppConstants.fallbackServiceImage;
    }
  }
  
  double _safeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    if (value == double.infinity ||
        value == double.negativeInfinity ||
        value != value ||
        value <= 0) {
      return fallback;
    }
    return value;
  }
  
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  double _sanitizeDimension(double? value, {double fallback = 100}) {
    if (value == null) return fallback;
    if (value.isNaN || value.isInfinite) return fallback;
    if (value <= 0) return fallback;
    return value;
  }

  String? _getValidUrl() {
    if (_isValidUrl(widget.imageUrl)) {
      return widget.imageUrl;
    }
    if (_isValidUrl(widget.fallbackUrl)) {
      return widget.fallbackUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // If no valid URL found, show fallback widget
    if (!_isValidUrl(_currentUrl)) {
      return _buildFallback();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeWidth = _sanitizeDimension(
          (widget.width != null)
              ? widget.width
              : (constraints.maxWidth.isFinite ? constraints.maxWidth : null),
        );
        final safeHeight = _sanitizeDimension(
          (widget.height != null)
              ? widget.height
              : (constraints.maxHeight.isFinite ? constraints.maxHeight : null),
        );
        return _buildImage(safeWidth, safeHeight);
      },
    );
  }

  Widget _buildImage(double safeWidth, double safeHeight) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: _currentUrl,
      width: safeWidth,
      height: safeHeight,
      fit: widget.fit,
      placeholder: (context, url) => 
          widget.placeholder ?? _buildPlaceholder(safeWidth, safeHeight),
      errorWidget: (context, url, error) {
        // If primary URL failed and we have fallback, try fallback
        if (!_primaryFailed && _isValidUrl(widget.fallbackUrl)) {
          _primaryFailed = true;
          _currentUrl = widget.fallbackUrl!;
          // Rebuild with fallback URL
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          return _buildPlaceholder(safeWidth, safeHeight);
        }
        
        return widget.errorWidget ?? _buildFallback(safeWidth, safeHeight);
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
    
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    if (widget.backgroundColor != null) {
      imageWidget = Container(
        width: safeWidth,
        height: safeHeight,
        color: widget.backgroundColor,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
  
  Widget _buildPlaceholder([double? safeWidth, double? safeHeight]) {
    final w = safeWidth ?? _safeDimension(widget.width);
    final h = safeHeight ?? _safeDimension(widget.height);
    
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFallback([double? safeWidth, double? safeHeight]) {
    final w = safeWidth ?? _safeDimension(widget.width);
    final h = safeHeight ?? _safeDimension(widget.height);
    
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: (w < h ? w * 0.4 : h * 0.4).clamp(24, 48),
        ),
      ),
    );
  }
}

class SafeCircularNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const SafeCircularNetworkImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SafeNetworkImage(
        imageUrl: imageUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }
}
