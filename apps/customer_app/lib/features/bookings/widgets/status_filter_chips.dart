import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusFilterChips extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const StatusFilterChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      {'key': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
      {'key': 'pending', 'label': 'Pending', 'icon': Icons.pending},
      {'key': 'accepted', 'label': 'Active', 'icon': Icons.check_circle_outline},
      {'key': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
      {'key': 'cancelled', 'label': 'Cancelled', 'icon': Icons.cancel_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: statuses.map((status) {
          final isSelected = selectedStatus == status['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      status['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
              onSelected: (_) => onStatusChanged(status['key'] as String),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6366F1),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
