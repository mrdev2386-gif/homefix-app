import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/partner_onboarding_provider.dart';

/// Service Categories Step - Step 2 of 8
/// 
/// FEATURES:
/// - Fetches categories from Firestore
/// - Expandable subcategories
/// - Modern chip-based selection
/// - Shows selection count
class OnboardingStepCategories extends StatefulWidget {
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const OnboardingStepCategories({
    super.key,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  State<OnboardingStepCategories> createState() => _OnboardingStepCategoriesState();
}

class _OnboardingStepCategoriesState extends State<OnboardingStepCategories> {
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Map<String, dynamic>>> _subcategories = {};
  bool _isLoading = true;
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Fetch categories from Firestore
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('technician_categories')
          .orderBy('name')
          .get();

      final categories = categoriesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? '',
        'icon': doc.data()['icon'] ?? 'build',
      }).toList();

      // If no categories in Firestore, use defaults
      if (categories.isEmpty) {
        _categories = [
          {'id': 'plumbing', 'name': 'Plumbing', 'icon': 'plumbing'},
          {'id': 'electrical', 'name': 'Electrical', 'icon': 'electrical_services'},
          {'id': 'carpentry', 'name': 'Carpentry', 'icon': 'carpenter'},
          {'id': 'painting', 'name': 'Painting', 'icon': 'format_paint'},
          {'id': 'cleaning', 'name': 'Cleaning', 'icon': 'cleaning_services'},
          {'id': 'appliance', 'name': 'Appliance Repair', 'icon': 'kitchen'},
          {'id': 'ac', 'name': 'AC Service', 'icon': 'ac_unit'},
          {'id': 'pest', 'name': 'Pest Control', 'icon': 'pest_control'},
        ];
        
        // Default subcategories
        _subcategories = {
          'plumbing': [
            {'id': 'plumbing_leak', 'name': 'Leak Repair'},
            {'id': 'plumbing_install', 'name': 'Installation'},
            {'id': 'plumbing_drain', 'name': 'Drain Cleaning'},
          ],
          'electrical': [
            {'id': 'electrical_wiring', 'name': 'Wiring'},
            {'id': 'electrical_switch', 'name': 'Switch/Socket'},
            {'id': 'electrical_fan', 'name': 'Fan Installation'},
          ],
          'carpentry': [
            {'id': 'carpentry_furniture', 'name': 'Furniture Repair'},
            {'id': 'carpentry_door', 'name': 'Door/Window'},
            {'id': 'carpentry_custom', 'name': 'Custom Work'},
          ],
          'painting': [
            {'id': 'painting_interior', 'name': 'Interior'},
            {'id': 'painting_exterior', 'name': 'Exterior'},
            {'id': 'painting_texture', 'name': 'Texture'},
          ],
          'cleaning': [
            {'id': 'cleaning_deep', 'name': 'Deep Cleaning'},
            {'id': 'cleaning_regular', 'name': 'Regular'},
            {'id': 'cleaning_sofa', 'name': 'Sofa/Carpet'},
          ],
          'appliance': [
            {'id': 'appliance_washing', 'name': 'Washing Machine'},
            {'id': 'appliance_fridge', 'name': 'Refrigerator'},
            {'id': 'appliance_microwave', 'name': 'Microwave'},
          ],
          'ac': [
            {'id': 'ac_service', 'name': 'Service'},
            {'id': 'ac_install', 'name': 'Installation'},
            {'id': 'ac_repair', 'name': 'Repair'},
          ],
          'pest': [
            {'id': 'pest_general', 'name': 'General'},
            {'id': 'pest_termite', 'name': 'Termite'},
            {'id': 'pest_cockroach', 'name': 'Cockroach'},
          ],
        };
      } else {
        _categories = categories;
        
        // Fetch subcategories
        final subcategoriesSnapshot = await FirebaseFirestore.instance
            .collection('technician_subcategories')
            .get();
        
        for (var doc in subcategoriesSnapshot.docs) {
          final categoryId = doc.data()['categoryId'] as String?;
          if (categoryId != null) {
            _subcategories[categoryId] ??= [];
            _subcategories[categoryId]!.add({
              'id': doc.id,
              'name': doc.data()['name'] ?? '',
            });
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[Categories] Error loading: $e');
      // Use defaults on error
      _categories = [
        {'id': 'plumbing', 'name': 'Plumbing', 'icon': 'plumbing'},
        {'id': 'electrical', 'name': 'Electrical', 'icon': 'electrical_services'},
        {'id': 'carpentry', 'name': 'Carpentry', 'icon': 'carpenter'},
        {'id': 'painting', 'name': 'Painting', 'icon': 'format_paint'},
        {'id': 'cleaning', 'name': 'Cleaning', 'icon': 'cleaning_services'},
      ];
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'plumbing': return Icons.plumbing;
      case 'electrical_services': return Icons.electrical_services;
      case 'carpenter': return Icons.carpenter;
      case 'format_paint': return Icons.format_paint;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'kitchen': return Icons.kitchen;
      case 'ac_unit': return Icons.ac_unit;
      case 'pest_control': return Icons.pest_control;
      default: return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PartnerOnboardingProvider>(
      builder: (context, provider, child) {
        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: SlideTransition(
            position: widget.slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.category_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Expertise',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select services you can provide',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Selection Summary
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: provider.categoryIds.isNotEmpty
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: provider.categoryIds.isNotEmpty
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            provider.categoryIds.isNotEmpty
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            color: provider.categoryIds.isNotEmpty
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            provider.categoryIds.isEmpty
                                ? 'Select at least 1 category and 1 subcategory'
                                : '${provider.categoryIds.length} categories, ${provider.subcategoryIds.length} subcategories selected',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: provider.categoryIds.isNotEmpty
                                  ? const Color(0xFF059669)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Categories List
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ..._categories.map((category) => _buildCategoryCard(
                        category: category,
                        provider: provider,
                      )),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required Map<String, dynamic> category,
    required PartnerOnboardingProvider provider,
  }) {
    final categoryId = category['id'] as String;
    final categoryName = category['name'] as String;
    final iconName = category['icon'] as String;
    final isSelected = provider.categoryIds.contains(categoryId);
    final isExpanded = _expandedCategoryId == categoryId;
    final subcats = _subcategories[categoryId] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Header
          InkWell(
            onTap: () {
              provider.toggleCategory(categoryId);
              setState(() {
                if (isSelected) {
                  // Deselecting - remove all subcategories
                  for (var sub in subcats) {
                    if (provider.subcategoryIds.contains(sub['id'])) {
                      provider.toggleSubcategory(sub['id']);
                    }
                  }
                  if (_expandedCategoryId == categoryId) {
                    _expandedCategoryId = null;
                  }
                } else {
                  // Selecting - expand to show subcategories
                  _expandedCategoryId = categoryId;
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForCategory(iconName),
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        if (isSelected && subcats.isNotEmpty)
                          Text(
                            '${provider.subcategoryIds.where((id) => subcats.any((s) => s['id'] == id)).length} of ${subcats.length} selected',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  if (subcats.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedCategoryId = isExpanded ? null : categoryId;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Subcategories (Expandable)
          if (isExpanded && subcats.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Select specializations:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subcats.map((sub) {
                      final subId = sub['id'] as String;
                      final subName = sub['name'] as String;
                      final isSubSelected = provider.subcategoryIds.contains(subId);
                      
                      return GestureDetector(
                        onTap: () {
                          provider.toggleSubcategory(subId);
                          // Auto-select parent category if not selected
                          if (!provider.categoryIds.contains(categoryId)) {
                            provider.toggleCategory(categoryId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSubSelected
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSubSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSubSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              Text(
                                subName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSubSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
