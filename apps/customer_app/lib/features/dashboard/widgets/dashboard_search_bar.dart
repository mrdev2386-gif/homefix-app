import 'package:flutter/material.dart';

class DashboardSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String currentQuery;

  const DashboardSearchBar({
    super.key,
    this.hintText = 'Search a device',
    required this.onChanged,
    this.onClear,
    this.currentQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
          suffixIcon: currentQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
