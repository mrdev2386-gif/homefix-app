import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/service.dart';
import '../../dashboard/widgets/premium_service_card.dart';

class FavoriteServicesScreen extends StatelessWidget {
  const FavoriteServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Login required')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Favorite Services', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<HomeService>>(
        stream: firestore.streamFavoriteServices(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Services you favorite will appear here.',
                    style: GoogleFonts.outfit(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return PremiumServiceCard(service: services[index]);
            },
          );
        },
      ),
    );
  }
}
