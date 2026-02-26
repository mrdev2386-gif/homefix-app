# Customer App - District-Filtered Services Integration

## 🎯 Query Services by District

### Dart Code (Customer App)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerServicesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get services filtered by customer's district
  /// CRITICAL: Only shows services from same district
  Stream<List<ServiceModel>> getServicesByDistrict(String customerDistrict) {
    return _firestore
        .collectionGroup('services')
        .where('isActive', isEqualTo: true)
        .where('isDeleted', isEqualTo: false)
        .where('district', isEqualTo: customerDistrict)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ServiceModel.fromMap(data);
      }).toList();
    });
  }

  /// Get customer's district from profile
  Future<String?> getCustomerDistrict(String customerId) async {
    final doc = await _firestore.collection('customers').doc(customerId).get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    return data['district'] ?? data['districtNormalized'];
  }
}
```

### Service Model

```dart
class ServiceModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final String description;
  final String district;
  final double averageRating;
  final int totalReviews;
  final bool isActive;
  final String technicianId;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.district,
    required this.averageRating,
    required this.totalReviews,
    required this.isActive,
    required this.technicianId,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      district: map['district'] ?? '',
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isActive: map['isActive'] ?? false,
      technicianId: map['technicianId'] ?? '',
    );
  }
}
```

### Usage in UI

```dart
class ServicesScreen extends StatelessWidget {
  final String customerId;

  const ServicesScreen({required this.customerId});

  @override
  Widget build(BuildContext context) {
    final servicesService = CustomerServicesService();

    return FutureBuilder<String?>(
      future: servicesService.getCustomerDistrict(customerId),
      builder: (context, districtSnapshot) {
        if (!districtSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final customerDistrict = districtSnapshot.data!;

        return StreamBuilder<List<ServiceModel>>(
          stream: servicesService.getServicesByDistrict(customerDistrict),
          builder: (context, servicesSnapshot) {
            if (servicesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!servicesSnapshot.hasData || servicesSnapshot.data!.isEmpty) {
              return const Center(
                child: Text('No services available in your area'),
              );
            }

            final services = servicesSnapshot.data!;

            return ListView.builder(
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ServiceCard(service: service);
              },
            );
          },
        );
      },
    );
  }
}
```

### Service Card Widget

```dart
class ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            service.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
        title: Text(
          service.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹${service.price}'),
            if (service.totalReviews > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${service.averageRating.toStringAsFixed(1)} (${service.totalReviews})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        onTap: () {
          // Navigate to service details
        },
      ),
    );
  }
}
```

---

## 🔍 Firestore Index Required

Create composite index for efficient queries:

```
Collection: services (collection group)
Fields:
  - isActive (Ascending)
  - isDeleted (Ascending)
  - district (Ascending)
  - createdAt (Descending)
```

### Create Index via Firebase Console:
1. Go to Firestore → Indexes
2. Click "Create Index"
3. Collection ID: `services`
4. Query scope: `Collection group`
5. Add fields as listed above
6. Click "Create"

---

## ✅ Testing Checklist

### Technician Side
- [ ] Technician adds service
- [ ] District auto-injected from profile
- [ ] Service appears in technician's list
- [ ] Rating fields default to 0

### Customer Side
- [ ] Customer in same district sees service
- [ ] Customer in different district does NOT see service
- [ ] Service image displays correctly
- [ ] Rating displays if > 0 reviews
- [ ] Price formatted correctly

### Real-time Updates
- [ ] Technician toggles service OFF → disappears from customer list
- [ ] Technician toggles service ON → reappears in customer list
- [ ] Changes reflect within 1-2 seconds

---

## 🐛 Troubleshooting

### Issue: No services showing
**Check:**
1. Customer has district set in profile
2. Technician has district set in profile
3. Districts match exactly (case-sensitive)
4. Service isActive == true
5. Service isDeleted == false

### Issue: Services from other districts showing
**Check:**
1. Query includes district filter
2. District field exists in service documents
3. Firestore index created

### Issue: Slow queries
**Solution:** Create composite index (see above)

---

## 📊 Data Flow

```
Technician adds service
        ↓
Cloud Function validates
        ↓
Fetches technician profile
        ↓
Injects district from profile
        ↓
Saves to: technicians/{techId}/services/{serviceId}
        ↓
Customer queries collection group
        ↓
Filters by: isActive, isDeleted, district
        ↓
Only same-district services returned
```

---

## 🔐 Security

### Firestore Rules
```javascript
match /technicians/{techId}/services/{serviceId} {
  // Read: Active services OR owner OR admin
  allow read: if (resource.data.isActive == true && 
                  resource.data.isDeleted == false) || 
                 isAdmin() || 
                 (isAuthenticated() && techId == request.auth.uid);
  
  // Write: ONLY via Cloud Functions
  allow create: if false;
  allow update: if false;
  allow delete: if false;
}
```

### Why District-Safe?
- ✅ District comes from server (technician profile)
- ✅ Client cannot manipulate district
- ✅ Ensures local service delivery
- ✅ Prevents cross-district spam

---

## 📞 Support

For integration help: **9508322397**
