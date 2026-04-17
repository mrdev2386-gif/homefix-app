import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/core/services/user_location_service.dart';

class CategoryTechniciansScreen extends StatefulWidget {
  final String categoryName;
  final String categoryId;

  const CategoryTechniciansScreen({super.key, 
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<CategoryTechniciansScreen> createState() => _CategoryTechniciansScreenState();
}

class _CategoryTechniciansScreenState extends State<CategoryTechniciansScreen> {
  final UserLocationService _locationService = UserLocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // SCALABILITY: Pagination support
  static const int _pageSize = 20;
  final List<DocumentSnapshot> _allDocs = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, String>?>(
        future: _locationService.getLocation(),
        builder: (context, locationSnapshot) {
          if (!locationSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = locationSnapshot.data?['state'];
          final district = locationSnapshot.data?['district'];

          if (state == null || district == null) {
            return const Center(child: Text('Location not set'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('technician_services')
                .where('category', isEqualTo: widget.categoryId)
                .where('state', isEqualTo: state)
                .where('district', isEqualTo: district)
                .where('status', isEqualTo: 'approved')
                .where('isActive', isEqualTo: true)
                .where('isDeleted', isEqualTo: false)
                .limit(_pageSize)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'No technicians available in your district yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final technicians = snapshot.data!.docs;
              
              // Update pagination state
              if (technicians.isNotEmpty) {
                _allDocs.clear();
                _allDocs.addAll(technicians);
                _hasMore = technicians.length >= _pageSize;
              }
              _isLoadingMore = false;

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: technicians.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= technicians.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final tech = technicians[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(tech['name'] ?? 'Technician'),
                      subtitle: Text(tech['district'] ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
