import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedInitialData() async {
    await _seedCategories();
    await _seedServices();
    await _seedBanners();
  }

  static Future<void> _seedCategories() async {
    try {
      final snapshot = await _db.collection('categories').limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Already seeded

      final categories = [
        {'name': 'Cleaning', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'Electrician', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'Plumbing', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'AC Repair', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'Carpenter', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'Painting', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'Appliance Repair', 'createdAt': FieldValue.serverTimestamp()},
        {'name': 'Salon', 'createdAt': FieldValue.serverTimestamp()},
      ];

      for (var category in categories) {
        await _db.collection('categories').add(category);
      }
      print('✅ Seeded categories');
    } catch (e) {
      print('❌ Error seeding categories: $e');
    }
  }

  static Future<void> _seedServices() async {
    try {
      final snapshot = await _db.collection('services').get();
      
      // Known services to update with UNIQUE, high-quality images
      final updates = {
        'ac_service': {
          'imageUrl': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
          'isTopService': true,
          'order': 1,
          'category': 'Appliance',
          'isActive': true,
        },
        'cleaning': {
          'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80',
          'isTopService': true,
          'order': 2,
          'category': 'Cleaning',
          'isActive': true,
        },
        'electrician': {
          'imageUrl': 'https://images.unsplash.com/photo-1621905252507-b354bcadc0d9?w=800&q=80',
          'isTopService': true,
          'order': 3,
          'category': 'Electrical',
          'isActive': true,
        },
        'plumbing': {
           'imageUrl': 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=800&q=80',
           'isTopService': true,
           'order': 4,
           'category': 'Plumbing',
           'isActive': true,
        },
         'carpenter': {
           'imageUrl': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=800&q=80',
           'isTopService': false,
           'order': 5,
           'category': 'Carpentry',
           'isActive': true,
        },
        'painting': {
           'imageUrl': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800&q=80',
           'isTopService': false,
           'order': 6,
           'category': 'Painting',
           'isActive': true,
        },
        'appliance_repair': {
           'imageUrl': 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=800&q=80',
           'isTopService': false,
           'order': 7,
           'category': 'Appliance',
           'isActive': true,
        },
        'pest_control': {
           'imageUrl': 'https://images.unsplash.com/photo-1563207153-f403bf289096?w=800&q=80',
           'isTopService': false,
           'order': 8,
           'category': 'Pest Control',
           'isActive': true,
        },
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title']?.toString().toLowerCase() ?? '';
        final name = data['name']?.toString().toLowerCase() ?? '';
        final serviceId = data['serviceId']?.toString().toLowerCase() ?? '';
        
        // Match service by title, name, or serviceId
        String titleKey = 'other';
        if (title.contains('ac') || name.contains('ac') || serviceId.contains('ac')) {
          titleKey = 'ac_service';
        } else if (title.contains('clean') || name.contains('clean') || serviceId.contains('clean')) {
          titleKey = 'cleaning';
        } else if (title.contains('electr') || name.contains('electr') || serviceId.contains('electr')) {
          titleKey = 'electrician';
        } else if (title.contains('plumb') || name.contains('plumb') || serviceId.contains('plumb')) {
          titleKey = 'plumbing';
        } else if (title.contains('carp') || name.contains('carp') || serviceId.contains('carp')) {
          titleKey = 'carpenter';
        } else if (title.contains('paint') || name.contains('paint') || serviceId.contains('paint')) {
          titleKey = 'painting';
        } else if (title.contains('appliance') || name.contains('appliance') || serviceId.contains('appliance')) {
          titleKey = 'appliance_repair';
        } else if (title.contains('pest') || name.contains('pest') || serviceId.contains('pest')) {
          titleKey = 'pest_control';
        }


        Map<String, dynamic> changes = {};
        
        // Always ensure these fields exist and update with unique images
        if (data['imageUrl'] == null || data['imageUrl'].toString().isEmpty || data['imageUrl'].toString().startsWith('assets/')) {
           // Use matched service image or unique fallback based on doc ID
           changes['imageUrl'] = updates[titleKey]?['imageUrl'] ?? 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80&sig=${doc.id}';
        }
        
        if (data['isTopService'] == null) {
          changes['isTopService'] = updates[titleKey]?['isTopService'] ?? false;
        }
        
        if (data['isActive'] == null) {
          changes['isActive'] = true;
        }

        if (data['order'] == null) {
           changes['order'] = updates[titleKey]?['order'] ?? 99;
        }
        
        if (data['category'] == null) {
           changes['category'] = updates[titleKey]?['category'] ?? 'General';
        }

        if (changes.isNotEmpty) {
          await doc.reference.update(changes);
          print('Updated service: ${doc.id}');
        }
      }
    } catch (e) {
      print("Error seeding services: $e");
    }
  }

  static Future<void> _seedBanners() async {
    try {
      final snapshot = await _db.collection('home_banners').limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Already seeded

      final banners = [
        {
          'imageUrl': 'https://picsum.photos/seed/banner1/1200/600',
          'title': 'AC Repair',
          'subtitle': 'Expert Air Conditioner servicing at your doorstep.',
          'ctaText': 'Book Now',
          'serviceId': 'ac_service',
          'order': 1,
          'isActive': true,
        },
        {
          'imageUrl': 'https://picsum.photos/seed/banner2/1200/600',
          'title': 'Home Cleaning',
          'subtitle': 'Deep cleaning for a sparkling home.',
          'ctaText': 'View Plans',
          'serviceId': 'cleaning',
          'order': 2,
          'isActive': true,
        },
        {
           'imageUrl': 'https://picsum.photos/seed/banner3/1200/600',
           'title': 'Painting Services',
           'subtitle': 'Give your walls a fresh look.',
           'ctaText': 'Explore',
           'serviceId': 'painting',
           'order': 3,
           'isActive': true,
        },
        {
           'imageUrl': 'https://picsum.photos/seed/banner4/1200/600',
           'title': 'Plumbing Express',
           'subtitle': 'Fix leaks fast with expert plumbers.',
           'ctaText': 'Fix Now',
           'serviceId': 'plumbing',
           'order': 4,
           'isActive': true,
        }
      ];

      for (var banner in banners) {
        await _db.collection('home_banners').add(banner);
      }
      print('Seeded home_banners');
    } catch (e) {
      print("Error seeding banners: $e");
    }
  }
}
