class RecentlyAddedServicesSection extends StatefulWidget {
  const RecentlyAddedServicesSection({super.key});

  @override
  State<RecentlyAddedServicesSection> createState() => _RecentlyAddedServicesState();
}

class _RecentlyAddedServicesState extends State<RecentlyAddedServicesSection> {
  bool _isLoading = true;
  List<HomeService> _services = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final result = await fs.fetchPaginatedServices(pageSize: 5);
      
      if (mounted) {
        setState(() {
          _services = result.services;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            ServicesHorizontalShimmer(totalColumns: 4),
          ],
        ),
      );
    }

    if (_error != null || _services.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildServicesList(_services, (_services.length / 2).ceil()),
        ],
      ),
    );
  }

  Widget _buildServicesList(List<HomeService> services, int totalColumns) {
    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemCount: totalColumns,
          itemBuilder: (context, columnIndex) {
            final startIndex = columnIndex * 2;
            final endIndex = (startIndex + 2).clamp(0, services.length);
            final columnServices = services.sublist(startIndex, endIndex);
            
            if (columnServices.isEmpty) {
              return SizedBox.shrink();
            }
            
            return Padding(
              padding: EdgeInsets.only(right: columnIndex < totalColumns - 1 ? 12 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 110,
                    child: UniversalServiceCard(
                      key: ValueKey(columnServices[0].id),
                      service: columnServices[0],
                      isGrid: true,
                    ),
                  ),
                  if (columnServices.length > 1) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      child: UniversalServiceCard(
                        key: ValueKey(columnServices[1].id),
                        service: columnServices[1],
                        isGrid: true,
                      ),
                    ),
                  ] else
                    const SizedBox(height: 122),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.new_releases_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          SizedBox(
            child: Text(
              'Recently Added',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ServiceListScreen(),
              ),
            ),
            child: Text(
              'View All',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
