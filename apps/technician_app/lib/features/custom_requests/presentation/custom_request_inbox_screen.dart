import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/providers/technician_provider.dart';
import '../../core/models/custom_request.dart';
import '../../core/services/functions_service.dart';
import 'custom_request_detail_screen.dart';

class CustomRequestInboxScreen extends StatefulWidget {
  const CustomRequestInboxScreen({super.key});

  @override
  State<CustomRequestInboxScreen> createState() => _CustomRequestInboxScreenState();
}

class _CustomRequestInboxScreenState extends State<CustomRequestInboxScreen> {
  List<CustomRequest> _requests = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _lastDocumentId;
  final ScrollController _scrollController = ScrollController();
  final FunctionsService _functionsService = FunctionsService();

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && mounted) {
        _fetchMoreRequests();
      }
    }
  }

  Future<void> _fetchRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _requests = [];
      _lastDocumentId = null;
    });

    try {
      final result = await _functionsService.getTechnicianInbox(limit: 20);
      
      if (mounted) {
        setState(() {
          _requests = (result['requests'] as List)
              .map((e) => CustomRequest.fromMap(e, documentId: e['id']))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching requests: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreRequests() async {
    if (_requests.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
      _lastDocumentId = _requests.last.id;
    });

    try {
      final result = await _functionsService.getTechnicianInbox(
        limit: 20,
        startAfter: _lastDocumentId,
      );

      if (mounted) {
        final newRequests = (result['requests'] as List)
            .map((e) => CustomRequest.fromMap(e, documentId: e['id']))
            .toList();

        setState(() {
          _requests.addAll(newRequests);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching more requests: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Custom Requests',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : _buildRequestList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Requests Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New service requests will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _requests.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final request = _requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(CustomRequest request) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeAgo = _getTimeAgo(request.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomRequestDetailScreen(requestId: request.id),
            ),
          );
          if (result == true) {
            _fetchRequests();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: request.urgency.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: request.urgency.color,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      request.urgency.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: request.urgency.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                request.categoryName ?? 'General Service',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.address.city ?? request.address.address,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${request.preferredDate} • ${request.preferredTime}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (request.budgetMin != null || request.budgetMax != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatBudget(request.budgetMin, request.budgetMax),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  String _formatBudget(double? min, double? max) {
    if (min == null && max == null) return 'Budget not specified';
    if (min != null && max == null) return '₹${min.round()} onwards';
    if (min == null && max != null) return 'Up to ₹${max.round()}';
    return '₹${min.round()} - ₹${max.round()}';
  }
}
