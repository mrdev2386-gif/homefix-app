import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/core/models/category.dart';
import 'package:customer_app/core/models/service.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'package:customer_app/core/services/category_service.dart';
import '../../dashboard/widgets/unified_service_card.dart';
import '../../services/presentation/service_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SubServiceScreen extends StatefulWidget {
  final Category category;
  final HomeService service;

  const SubServiceScreen({
    super.key,
    required this.category,
    required this.service,
  });

  @override
  State<SubServiceScreen> createState() => _SubServiceScreenState();
}

class _SubServiceScreenState extends State<SubServiceScreen> {
  late final CategoryService _categoryService;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _categoryService = context.read<CategoryService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service.title, 
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<HomeService>>(
        stream: _categoryService.getSubServices(widget.category.id, widget.service.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 16),
                  Text('Loading options...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString().toLowerCase();
            debugPrint('🕵️ [SubServiceScreen] Error: $error');

            return _buildErrorState(
              icon: error.contains('failed-precondition') 
                  ? Icons.settings_suggest_rounded 
                  : Icons.error_outline_rounded,
              title: error.contains('failed-precondition') 
                  ? 'Setting up data...' 
                  : 'Something went wrong',
              message: error.contains('failed-precondition')
                  ? 'Please try again in a moment'
                  : 'Check your connection and try again',
            );
          }

          final subServices = snapshot.data ?? [];

          if (subServices.isEmpty) {
            return _buildErrorState(
              icon: Icons.search_off_rounded,
              title: 'No options found',
              message: 'Try a different category',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: subServices.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final subService = subServices[index];
              return UniversalServiceCard(
                service: subService,
                onNavigateToDetails: () => _navigateToDetails(subService),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToDetails(HomeService subService) {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailsScreen(
          serviceId: subService.id,
          categoryId: widget.category.id, // Reference original category ID
          serviceName: subService.title,
          serviceData: subService,
        ),
      ),
    ).then((_) {
      if (mounted) _isNavigating = false;
    });
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18, 
                fontWeight: FontWeight.w700, 
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
