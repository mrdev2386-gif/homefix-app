# Custom Request Feature - Code Reference

## 🔧 Essential Code Snippets

### 1. Update Home Screen (home_screen.dart)

Add this before `_buildNeedAssistance()`:

```dart
// Custom Request Card
Container(
  margin: const EdgeInsets.fromLTRB(16, 28, 16, 16),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Can't find your service?",
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomRequestScreen()),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Request Custom Service'),
      ),
    ],
  ),
),
```

---

### 2. Cloud Function: createCustomRequest

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

exports.createCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { title, description, category, preferredDate, preferredTime, budget, address, state, district, pincode, images } = data;

  if (!title || !description || !category || !preferredDate || !preferredTime || !address) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const requestId = db.collection('custom_requests').doc().id;
    
    const requestData = {
      type: 'custom_request',
      customerId: userId,
      title: title.trim(),
      description: description.trim(),
      category,
      preferredDate,
      preferredTime,
      budget: budget ? parseFloat(budget) : null,
      address,
      state: state || '',
      district: district || '',
      pincode: pincode || '',
      images: images || [],
      technicianId: null,
      status: 'pending_admin_review',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('custom_requests').doc(requestId).set(requestData);

    return {
      success: true,
      requestId,
      message: 'Request created successfully',
    };
  } catch (error) {
    console.error('Error creating custom request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create request');
  }
});
```

---

### 3. Cloud Function: acceptCustomRequest

```javascript
exports.acceptCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const technicianId = context.auth.uid;
  const { requestId } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId');
  }

  try {
    const requestDoc = await db.collection('custom_requests').doc(requestId).get();
    
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Request not found');
    }

    const requestData = requestDoc.data();
    
    if (requestData.technicianId !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Not assigned to this request');
    }

    // Update request status
    await db.collection('custom_requests').doc(requestId).update({
      status: 'accepted',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create booking
    const bookingId = db.collection('bookings').doc().id;
    const bookingData = {
      type: 'custom_request',
      customRequestId: requestId,
      customerId: requestData.customerId,
      technicianId,
      status: 'approved',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('bookings').doc(bookingId).set(bookingData);

    return {
      success: true,
      bookingId,
      message: 'Request accepted and booking created',
    };
  } catch (error) {
    console.error('Error accepting request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to accept request');
  }
});
```

---

### 4. Firestore Rules

```javascript
match /custom_requests/{requestId} {
  // Customer can read their own requests
  allow read: if request.auth.uid == resource.data.customerId;
  
  // Technician can read assigned requests
  allow read: if request.auth.uid == resource.data.technicianId;
  
  // Admin can read all requests
  allow read: if request.auth.token.admin == true;
  
  // Only Cloud Functions can write
  allow create: if false;
  allow update: if false;
  allow delete: if false;
}
```

---

### 5. Technician App: Accept Request

```dart
Future<void> _acceptRequest(String requestId) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('acceptCustomRequest');
    await callable.call({'requestId': requestId});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted! Booking created.')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
```

---

### 6. Customer App: Upload Images

```dart
Future<List<String>> _uploadImages(String requestId) async {
  final imageUrls = <String>[];
  for (int i = 0; i < _images.length; i++) {
    try {
      final file = _images[i];
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance.ref('custom_requests/$requestId/$fileName');
      
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      imageUrls.add(url);
      
      setState(() => _uploadProgress = (i + 1) / _images.length * 0.7);
    } catch (e) {
      debugPrint('Image upload error: $e');
    }
  }
  return imageUrls;
}
```

---

### 7. Customer App: Submit Request

```dart
Future<void> _submitRequest() async {
  if (!_formKey.currentState!.validate()) return;
  if (_preferredDate == null || _preferredTime == null || _selectedAddress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields')),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.uid;

    if (userId == null) throw Exception('User not authenticated');

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    
    setState(() => _uploadProgress = 0.1);
    final imageUrls = await _uploadImages(requestId);
    setState(() => _uploadProgress = 0.8);

    final dateStr = DateFormat('yyyy-MM-dd').format(_preferredDate!);
    final timeStr = '${_preferredTime!.hour.toString().padLeft(2, '0')}:${_preferredTime!.minute.toString().padLeft(2, '0')}';

    final requestData = {
      'type': 'custom_request',
      'customerId': userId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'preferredDate': dateStr,
      'preferredTime': timeStr,
      'budget': _budgetController.text.isEmpty ? null : double.tryParse(_budgetController.text),
      'address': _selectedAddress!.fullAddress,
      'state': _selectedAddress!.state ?? '',
      'district': _selectedAddress!.city ?? '',
      'pincode': _selectedAddress!.pincode ?? '',
      'images': imageUrls,
      'technicianId': null,
      'status': 'pending_admin_review',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    setState(() => _uploadProgress = 0.9);
    await FirestoreService().createCustomRequest(requestData);
    setState(() => _uploadProgress = 1.0);

    if (mounted) {
      _showSuccessDialog();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

---

### 8. Admin Panel: Assign Technician

```typescript
const handleAssignTechnician = async (requestId: string, technicianId: string) => {
  try {
    const assignTechnician = httpsCallable(functions, 'assignTechnicianToRequest');
    await assignTechnician({ requestId, technicianId });
    
    // Refresh data
    setRequests(requests.map(r => 
      r.id === requestId ? { ...r, status: 'technician_assigned', technicianId } : r
    ));
  } catch (error) {
    console.error('Error assigning technician:', error);
  }
};
```

---

## 📦 Dependencies

### Customer App (pubspec.yaml)
```yaml
firebase_storage: ^11.0.0
cloud_functions: ^4.0.0
image_picker: ^1.0.0
intl: ^0.19.0
```

### Technician App (pubspec.yaml)
```yaml
cloud_firestore: ^4.0.0
cloud_functions: ^4.0.0
```

### Admin Panel (package.json)
```json
{
  "dependencies": {
    "firebase": "^10.0.0",
    "next": "^14.0.0",
    "react": "^18.0.0"
  }
}
```

---

## 🚀 Deployment Commands

```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore Rules
firebase deploy --only firestore:rules

# Deploy Storage Rules
firebase deploy --only storage

# Deploy all
firebase deploy
```

---

## ✅ Verification Steps

1. **Create Request**
   - Fill form and submit
   - Check Firestore for document
   - Check Storage for images

2. **Admin Assignment**
   - Assign technician in admin panel
   - Check Firestore status update
   - Verify technician notification

3. **Technician Acceptance**
   - Accept request in technician app
   - Check booking created in Firestore
   - Verify customer notification

4. **Customer Tracking**
   - Check booking in customer app
   - Verify status updates
   - Check booking history
