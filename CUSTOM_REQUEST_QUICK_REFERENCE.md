# Custom Request Feature - Quick Reference Guide

## 🚀 Quick Start (5 Steps)

### Step 1: Update pubspec.yaml
```yaml
dependencies:
  firebase_app_check: ^0.2.1
  image_picker: ^1.0.0
  intl: ^0.19.0
```

### Step 2: Initialize Firebase App Check
In `main.dart`:
```dart
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const MyApp());
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  print('✅ Firebase App Check Debug activated');
}
```

### Step 3: Add Custom Request Route
In navigation:
```dart
GoRoute(
  path: '/custom-request',
  builder: (context, state) => const CustomRequestScreen(),
),
```

### Step 4: Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Step 5: Create Firestore Indexes
Firebase Console → Firestore → Indexes → Create 3 indexes:
1. custom_requests: status ASC + createdAt DESC
2. custom_requests: customerId ASC + createdAt DESC
3. custom_requests: technicianId ASC + status ASC

---

## 📋 File Structure

```
lib/
├── core/
│   └── firebase/
│       └── firebase_init.dart
└── features/
    └── custom_request/
        └── presentation/
            ├── custom_request_screen.dart
            ├── status_card.dart
            ├── request_form.dart
            ├── category_selector.dart
            └── image_picker_widget.dart
```

---

## 🔑 Key Code Snippets

### Image Upload with Auth
```dart
// Refresh auth token
await FirebaseAuth.instance.currentUser?.getIdToken(true);

// Upload to Storage
final path = 'custom_requests/$requestId/image_1.jpg';
await FirebaseStorage.instance.ref(path).putFile(file);

// Get download URL
final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
```

### Create Firestore Document
```dart
await FirebaseFirestore.instance.collection('custom_requests').doc(requestId).set({
  'type': 'custom_request',
  'customerId': user.uid,
  'title': formData['title'],
  'description': formData['description'],
  'category': formData['category'],
  'preferredDate': formData['preferredDate'],
  'preferredTime': formData['preferredTime'],
  'budget': formData['budget'],
  'address': formData['address']['fullAddress'],
  'state': '',
  'district': formData['address']['city'],
  'pincode': formData['address']['pincode'],
  'images': imageUrls,
  'technicianId': null,
  'status': 'pending_admin_review',
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

### Real-Time Status Tracking
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('custom_requests')
      .doc(requestId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }
    final data = snapshot.data!.data() as Map<String, dynamic>;
    return StatusCard(requestId: requestId, data: data);
  },
)
```

### Status Badge Colors
```dart
Color _getStatusColor(String status) {
  switch (status) {
    case 'pending_admin_review': return Colors.orange;
    case 'approved': return Colors.blue;
    case 'technician_assigned': return Colors.indigo;
    case 'accepted': return Colors.purple;
    case 'in_progress': return Colors.teal;
    case 'completed': return Colors.green;
    case 'rejected': return Colors.red;
    default: return Colors.grey;
  }
}
```

---

## 🔐 Firestore Rules

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /custom_requests/{requestId} {
      allow read: if request.auth.uid == resource.data.customerId
                  || request.auth.uid == resource.data.technicianId
                  || request.auth.token.admin == true;
      allow write: if false;
    }
  }
}
```

---

## ✅ Testing Checklist

### Form & Validation
- [ ] Title field required
- [ ] Description field required
- [ ] Category selection works
- [ ] Date picker shows next 7 days
- [ ] Time picker works
- [ ] Address selector works
- [ ] Budget field optional
- [ ] Form validation shows errors

### Image Upload
- [ ] Camera picker works
- [ ] Gallery picker works
- [ ] Max 3 images enforced
- [ ] Image preview displays
- [ ] Delete button removes image
- [ ] Upload shows progress
- [ ] Upload failure shows error

### Firestore Integration
- [ ] Document created in Firestore
- [ ] All fields populated correctly
- [ ] Images array contains URLs
- [ ] Status set to pending_admin_review
- [ ] Timestamps set correctly

### Status Display
- [ ] Status card displays
- [ ] Status badge shows correct color
- [ ] Request details displayed
- [ ] Images preview shown
- [ ] Submission date/time shown
- [ ] Real-time updates work

### Error Handling
- [ ] Upload failure handled
- [ ] Network error handled
- [ ] Auth error handled
- [ ] Clear error messages shown
- [ ] Retry capability works

---

## 🐛 Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Images not uploading | Auth token expired | Call `getIdToken(true)` before upload |
| Firestore document not created | Rules blocking write | Verify rules allow Cloud Functions |
| Status not updating | StreamBuilder not listening | Check document path and permissions |
| App Check errors | Not initialized | Call `FirebaseAppCheck.instance.activate()` |
| Images not displaying | Wrong URL format | Verify download URL from Storage |

---

## 📊 Data Flow Diagram

```
Customer App
    ↓
Fill Form + Select Images
    ↓
Refresh Auth Token
    ↓
Upload Images to Storage
    ↓
Get Download URLs
    ↓
Create Firestore Document
    ↓
Show Status Card
    ↓
StreamBuilder Listens
    ↓
Real-Time Status Updates
    ↓
Admin Assigns Technician
    ↓
Technician Accepts
    ↓
Booking Created
    ↓
Customer Sees Booking
```

---

## 🎯 Status Transitions

```
pending_admin_review → approved → technician_assigned → accepted → in_progress → completed
                    ↓                                ↓
                  rejected                        rejected
```

---

## 📱 UI Components

### Custom Request Screen
- Form with validation
- Image picker (max 3)
- Category selector
- Date/time picker
- Address selector
- Budget field (optional)
- Submit button

### Status Card
- Status badge (colored)
- Request title
- Category chip
- Images preview
- Submission date/time
- View Booking button (if applicable)

---

## 🔔 Notification Events

### Event 1: Technician Assigned
```
To: Technician
Title: "New Custom Service Request"
Body: "You have been assigned a new custom service request"
```

### Event 2: Request Accepted
```
To: Customer
Title: "Technician Assigned"
Body: "A technician has accepted your custom service request"
```

### Event 3: Request Rejected
```
To: Customer
Title: "Request Rejected"
Body: "Your custom service request has been rejected"
```

---

## 📈 Performance Tips

1. **Image Optimization**
   - Compress before upload
   - Max size: 5MB
   - Quality: 70%
   - Max width: 1200px

2. **Firestore Queries**
   - Use indexes for common queries
   - Limit results to 100 documents
   - Enable real-time updates only when needed

3. **Cloud Functions**
   - Keep timeout at 60 seconds
   - Use 256MB memory
   - Handle errors gracefully

---

## 🚀 Deployment Checklist

- [ ] All files copied to correct locations
- [ ] pubspec.yaml updated with dependencies
- [ ] Firebase App Check initialized
- [ ] Firestore rules deployed
- [ ] Firestore indexes created
- [ ] Custom request route added
- [ ] Tested in development
- [ ] No console errors
- [ ] Images upload successfully
- [ ] Firestore documents created
- [ ] Status updates in real-time
- [ ] Ready for production

---

**Version**: 1.0
**Status**: Production Ready
**Last Updated**: 2024
