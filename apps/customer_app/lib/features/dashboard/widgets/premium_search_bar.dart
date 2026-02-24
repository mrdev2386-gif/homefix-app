import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/theme/app_theme.dart';

/// Premium pill-shaped search bar with shadow and debounce support
class PremiumSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final Duration debounceDuration;
  final bool autofocus;
  final bool showFilterIcon;

  const PremiumSearchBar({
    super.key,
    this.hintText = 'Search services...',
    required this.onChanged,
    this.onClear,
    this.onTap,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.autofocus = false,
    this.showFilterIcon = true,
  });

  @override
  State<PremiumSearchBar> createState() => _PremiumSearchBarState();
}

class _PremiumSearchBarState extends State<PremiumSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _onClear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_hasFocus ? 0.12 : 0.06),
            blurRadius: _hasFocus ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _hasFocus ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Search Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search_rounded,
                    color: _hasFocus ? AppTheme.primaryColor : Colors.grey[500],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Text Field
                Expanded(
                  child: widget.onTap != null
                      ? AbsorbPointer(
                          child: Text(
                            _controller.text.isEmpty ? widget.hintText : _controller.text,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: _controller.text.isEmpty ? Colors.grey[400] : AppTheme.textColor,
                              fontWeight: _controller.text.isEmpty ? FontWeight.w400 : FontWeight.w500,
                            ),
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: widget.autofocus,
                          onChanged: _onTextChanged,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AppTheme.textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: GoogleFonts.outfit(
                              fontSize: 15,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                ),
                
                // Clear Button
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                
                // Filter Icon
                if (widget.showFilterIcon && _controller.text.isEmpty) ...[
                  if (_controller.text.isEmpty) const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Debounced search wrapper
class DebouncedSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final String hintText;
  final Duration debounceDuration;

  const DebouncedSearchBar({
    super.key,
    required this.onSearch,
    this.hintText = 'Search services...',
    this.debounceDuration = const Duration(milliseconds: 400),
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumSearchBar(
      hintText: widget.hintText,
      onChanged: _onChanged,
      onClear: () {
        _debounceTimer?.cancel();
        widget.onSearch('');
      },
    );
  }
}
