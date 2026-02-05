import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<Map<String, dynamic>> _services = [
    {
      'id': 'ac_service',
      'title': 'AC Repair & Service',
      'basePrice': 499.0,
      'durationMins': 45,
      'image': 'https://images.unsplash.com/photo-1581094288338-2314dddb7ecb?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Appliance',
    },
    {
      'id': 'cleaning',
      'title': 'Home Cleaning',
      'basePrice': 599.0,
      'durationMins': 120,
      'image': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Cleaning',
    },
    {
      'id': 'electrician',
      'title': 'Electrician',
      'basePrice': 199.0,
      'durationMins': 30,
      'image': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Repair',
    },
    {
      'id': 'plumbing',
      'title': 'Plumbing',
      'basePrice': 199.0,
      'durationMins': 30,
      'image': 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Repair',
    },
    {
      'id': 'pest_control',
      'title': 'Pest Control',
      'basePrice': 899.0,
      'durationMins': 60,
      'image': 'https://images.unsplash.com/photo-1590682222445-56260f855def?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Cleaning',
    },
    {
      'id': 'ro_service',
      'title': 'RO Water Purifier',
      'basePrice': 399.0,
      'durationMins': 45,
      'image': 'https://images.unsplash.com/photo-1588661661391-7f897f1f96f0?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Appliance',
    },
    {
      'id': 'tv_repair',
      'title': 'TV Repair',
      'basePrice': 299.0,
      'durationMins': 60,
      'image': 'https://images.unsplash.com/photo-1593784991095-a2266613388a?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Appliance',
    },
    {
      'id': 'washing_machine',
      'title': 'Washing Machine',
      'basePrice': 499.0,
      'durationMins': 60,
      'image': 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Appliance',
    },
    {
      'id': 'fridge_repair',
      'title': 'Refrigerator Repair',
      'basePrice': 449.0,
      'durationMins': 60,
      'image': 'https://images.unsplash.com/photo-1571175432230-01c24844d022?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Appliance',
    },
    {
      'id': 'microwave_repair',
      'title': 'Microwave Repair',
      'basePrice': 349.0,
      'durationMins': 45,
      'image': 'https://images.unsplash.com/photo-1585250495346-646f8498f26a?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Appliance',
    },
    {
      'id': 'painting',
      'title': 'Home Painting',
      'basePrice': 2500.0,
      'durationMins': 480,
      'image': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Renovation',
    },
    {
      'id': 'carpenter',
      'title': 'Carpenter',
      'basePrice': 249.0,
      'durationMins': 60,
      'image': 'https://images.unsplash.com/photo-1533090161767-e6ffed986c88?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Repair',
    },
    {
      'id': 'salon_men',
      'title': 'Salon for Men',
      'basePrice': 299.0,
      'durationMins': 45,
      'image': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Personal Care',
    },
    {
      'id': 'salon_women',
      'title': 'Salon for Women',
      'basePrice': 499.0,
      'durationMins': 90,
      'image': 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Personal Care',
    },
    {
      'id': 'massage',
      'title': 'Massage Therapy',
      'basePrice': 999.0,
      'durationMins': 60,
      'image': 'https://images.unsplash.com/photo-1544161515-4af6b1d81209?auto=format&fit=crop&q=80&w=800',
      'isActive': true,
      'category': 'Personal Care',
    },
  ];

  static Future<void> seedServicesIfEmpty() async {
    try {
      debugPrint("Synchronizing services catalog...");
      final batch = _db.batch();
      
      for (var service in _services) {
        final docRef = _db.collection('services').doc(service['id']);
        batch.set(docRef, {
          ...service,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      await batch.commit();
      debugPrint("Catalog synchronization complete!");
    } catch (e) {
      debugPrint("Error synchronizing services: $e");
    }
  }
}
