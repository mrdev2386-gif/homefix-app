import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../services/category_data_service.dart';

/// Searchable Dropdown Item
class DropdownItem {
  final String id;
  final String label;
  final String? subtitle;
  final IconData? icon;

  const DropdownItem({
    required this.id,
    required this.label,
    this.subtitle,
    this.icon,
  });
}

/// Professional Searchable Dropdown Widget
/// Supports large lists (350+ items) with virtualized scrolling
/// Features:
/// - Real-time filtering with debounce
/// - Virtualized list for performance
/// - Smooth scrolling
/// - Keyboard safe
/// - No overflow
class SearchableDropdown<T extends DropdownItem> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T?> onChanged;
  final String hint;
  final String searchHint;
  final bool isLoading;
  final String? errorText;
  final bool enabled;
  final bool showSearchIcon;
  final IconData dropdownIcon;
  final double? maxHeight;
  final Color? backgroundColor;
  final Color? selectedColor;

  const SearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.hint,
    this.searchHint = 'Search...',
    this.isLoading = false,
    this.errorText,
    this.enabled = true,
    this.showSearchIcon = true,
    this.dropdownIcon = Icons.keyboard_arrow_down_rounded,
    this.maxHeight,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T extends DropdownItem> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<T> _filteredItems = [];
  Timer? _debounceTimer;
  bool _isOpen = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filterItems(_searchController.text);
    }
  }

  @override
  void dispose() {
    // Mark disposed first
    _isDisposed = true;

    // Clean up resources
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();

    // Remove overlay safely WITHOUT rebuild
    _removeOverlay(fromDispose: true);

    super.dispose();
  }

  void _filterItems(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _isDisposed) return;
      if (query.isEmpty) {
        setState(() {
          _filteredItems = widget.items;
          _overlayEntry?.markNeedsBuild();
        });
      } else {
        final lowercaseQuery = query.toLowerCase().trim();
        setState(() {
          _filteredItems = widget.items
              .where((item) =>
                  item.label.toLowerCase().contains(lowercaseQuery) ||
                  (item.subtitle?.toLowerCase().contains(lowercaseQuery) ?? false))
              .toList();
          _overlayEntry?.markNeedsBuild();
        });
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null || !mounted || _isDisposed) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    _overlayEntry = _createOverlayEntry(renderBox);

    if (!mounted || _isDisposed) return;
    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) {
      setState(() => _isOpen = true);
    }

    // Focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  OverlayEntry _createOverlayEntry(RenderBox renderBox) {
    final globalOffset = renderBox.localToGlobal(Offset.zero);

    // Calculate max height - prioritize showing more items
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - globalOffset.dy - renderBox.size.height - 20;
    final maxDropDownHeight = widget.maxHeight ?? (availableHeight > 450 ? 450 : availableHeight);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown
          Positioned(
            left: globalOffset.dx,
            top: globalOffset.dy + renderBox.size.height + 4,
            width: renderBox.size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, renderBox.size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: widget.backgroundColor ?? Colors.white,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxDropDownHeight,
                    minWidth: renderBox.size.width,
                  ),
                  child: _buildDropdownContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field - compact padding
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _filterItems,
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              prefixIcon: widget.showSearchIcon
                  ? Icon(Icons.search, color: Colors.grey.shade500, size: 20)
                  : null,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterItems('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              isDense: true,
            ),
          ),
        ),
        // Items list - appears immediately below search
        Flexible(
          child: widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : _buildItemsList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No results found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        if (index >= _filteredItems.length) return const SizedBox.shrink();
        final item = _filteredItems[index];
        final isSelected = widget.selectedItem?.id == item.id;

        return InkWell(
          onTap: () => _selectItem(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isSelected
                ? (widget.selectedColor ?? AppTheme.primaryColor).withOpacity(0.1)
                : Colors.transparent,
            child: Row(
              children: [
                if (item.icon != null) ...[
                  Icon(
                    item.icon,
                    size: 20,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                ],
                Flexible(
                  fit: FlexFit.loose,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFF1E293B),
                        ),
                      ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectItem(T item) {
    if (!mounted || _isDisposed) return;
    widget.onChanged(item);
    _removeOverlay();
    _searchController.clear();
    _filterItems('');
  }

  void _removeOverlay({bool fromDispose = false}) {
    // Safely remove overlay if present
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (_) {
        // ignore if already removed
      }
      _overlayEntry = null;
    }

    // Never trigger rebuild during dispose
    if (!fromDispose && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled && !widget.isLoading ? _showOverlay : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.errorText != null
                  ? Colors.red
                  : widget.selectedItem != null
                      ? AppTheme.primaryColor
                      : const Color(0xFFE2E8F0),
              width: widget.selectedItem != null ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.selectedItem?.label ?? widget.hint,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: widget.selectedItem != null
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade500,
                    fontWeight:
                        widget.selectedItem != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  widget.dropdownIcon,
                  color: Colors.grey.shade500,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to convert CategoryData to DropdownItem
extension CategoryDataToDropdown on CategoryData {
  DropdownItem toDropdownItem() {
    return DropdownItem(
      id: id,
      label: name,
      icon: _getIconForCategory(iconName),
    );
  }

  static IconData _getIconForCategory(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'ac':
        return Icons.ac_unit;
      case 'electrical':
        return Icons.electrical_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'appliance':
        return Icons.kitchen;
      case 'carpentry':
        return Icons.carpenter;
      case 'painting':
        return Icons.format_paint;
      case 'spa':
        return Icons.spa;
      case 'salon':
        return Icons.content_cut;
      default:
        return Icons.category;
    }
  }
}

/// Extension to convert SubCategoryData to DropdownItem
extension SubCategoryDataToDropdown on SubCategoryData {
  DropdownItem toDropdownItem() {
    return DropdownItem(
      id: id,
      label: name,
      subtitle: categoryId,
    );
  }
}
