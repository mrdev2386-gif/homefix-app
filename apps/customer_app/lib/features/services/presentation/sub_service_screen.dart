import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/category.dart';
import '../../../core/models/service.dart';
import '../../../core/models/sub_service.dart';
import '../../../core/firestore/category_service.dart';
import '../../../core/firestore/matching_service.dart';
import '../../../core/widgets/safe_network_image.dart';
import '../../../core/widgets/no_technicians_popup.dart';
import '../../../core/widgets/matching_loading_overlay.dart';
import 'technician_selection_screen.dart';
import '../../../../core/theme/app_theme.dart';

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
  final CategoryService _categoryService = CategoryService();
  final MatchingService _matchingService = MatchingService();
  bool _isLoading = true;
  List<SubService> _subServices = [];
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchSubServices();
  }

  Future<void> _fetchSubServices() async {
    _categoryService
        .getSubServices(widget.category.id, widget.service.id)
        .listen(
      (subServices) {
        if (mounted) {
          setState(() {
            _subServices = subServices;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error fetching sub-services: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _handleSubServiceTap(SubService subService) async {
    setState(() => _selectedIndex = _subServices.indexOf(subService));
    
    // Trigger matching with subServiceId
    await _matchTechnicians(widget.service.id, subService.id);
    
    if (mounted) {
      setState(() => _selectedIndex = null);
    }
  }

  Future<void> _matchTechnicians(String serviceId, String? subServiceId) async {
    // Use the new loading overlay with timeout
    bool isTimedOut = false;
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return MatchingLoadingOverlay(
          onTimeout: () {
            isTimedOut = true;
            Navigator.of(context).pop();
          },
          message: 'Finding best professionals...',
        );
      },
    );
    
    if (isTimedOut) {
      if (!mounted) return;
      NoTechniciansPopup.show(
        context: context,
        onRetry: () => _matchTechnicians(serviceId, subServiceId),
        onChangeService: () {
          Navigator.of(context)..pop()..pop();
        },
        customMessage: 'Taking longer than expected. Please try again or choose a different service.',
      );
      return;
    }
    
    if (!mounted) return;
    
    final response = await _matchingService.matchTechnicians(
      serviceId: serviceId,
      subServiceId: subServiceId,
    );
    
    if (!mounted) return;
    
    if (response.available && response.topTechnicians != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicianSelectionScreen(
            technicians: response.topTechnicians!,
            serviceId: serviceId,
            subServiceId: subServiceId,
          ),
        ),
      );
    } else {
      NoTechniciansPopup.show(
        context: context,
        onRetry: () => _matchTechnicians(serviceId, subServiceId),
        onChangeService: () {
          Navigator.of(context)..pop()..pop();
        },
        customMessage: response.error,
      );
    }
  }

  void _showLoadingDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secondaryAnim) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Finding professionals...',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category.name,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.service.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _subServices.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _subServices.length,
                  itemBuilder: (context, index) {
                    final subService = _subServices[index];
                    final isSelected = _selectedIndex == index;
                    return _SubServiceCard(
                      subService: subService,
                      isSelected: isSelected,
                      onTap: () => _handleSubServiceTap(subService),
                    );
                  },
                ),
    );
  }

  Widget _buildShimmerLoading() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
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
            Icons.handyman_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No sub-services available',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubServiceCard extends StatelessWidget {
  final SubService subService;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubServiceCard({
    required this.subService, 
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SubService image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SafeNetworkImage(
                  imageUrl: subService.imageUrl ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // SubService info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subService.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${subService.price.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
