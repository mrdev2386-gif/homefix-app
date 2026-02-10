# Settings Feature - Quick Reference Card

## 🚀 Quick Start

```bash
# 1. Install dependencies
cd apps/customer_app
flutter pub get

# 2. Run app
flutter run

# 3. Navigate to Settings
Profile → PREFERENCES → Settings
```

---

## 📁 Files Overview

| File | Purpose | Lines |
|------|---------|-------|
| `user_settings.dart` | Data models | ~200 |
| `user_settings_service.dart` | Firestore service | ~150 |
| `settings_screen.dart` | UI implementation | ~700 |
| `profile_screen.dart` | Entry point (modified) | +10 |

---

## 🎯 Key Features

### Notifications (5 toggles)
- Push Notifications (master)
- Booking Updates
- Promotions & Offers
- Payments & Wallet
- Technician Status

### Account (4 options)
- Edit Profile ✅
- Change Phone 🔜
- Email Preferences 🔜
- Language 🔜

### Privacy & Security (3 options)
- App Lock 🔜
- Logout ✅
- Delete Account ✅

### Support & Info (4 options)
- Help & Support ✅
- Terms & Conditions ✅
- Privacy Policy ✅
- About HomeFix ✅

---

## 🔧 Common Tasks

### Add New Toggle
```dart
_buildSwitchTile(
  icon: Icons.new_feature,
  title: 'New Feature',
  subtitle: 'Description',
  value: settings.newFeature,
  onChanged: (value) {
    _updateNotificationSetting(
      (n) => n.copyWith(newFeature: value),
    );
  },
),
```

### Add New Navigation
```dart
_buildNavigationTile(
  icon: Icons.new_screen,
  title: 'New Screen',
  subtitle: 'Description',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewScreen()),
    );
  },
),
```

### Update Model
```dart
// 1. Add field to NotificationSettings
final bool newFeature;

// 2. Update constructor
NotificationSettings({
  // ... existing fields
  required this.newFeature,
});

// 3. Update defaults
factory NotificationSettings.defaults() {
  return NotificationSettings(
    // ... existing defaults
    newFeature: true,
  );
}

// 4. Update fromMap
factory NotificationSettings.fromMap(Map<String, dynamic> map) {
  return NotificationSettings(
    // ... existing fields
    newFeature: map['newFeature'] ?? true,
  );
}

// 5. Update toMap
Map<String, dynamic> toMap() {
  return {
    // ... existing fields
    'newFeature': newFeature,
  };
}

// 6. Update copyWith
NotificationSettings copyWith({
  // ... existing parameters
  bool? newFeature,
}) {
  return NotificationSettings(
    // ... existing fields
    newFeature: newFeature ?? this.newFeature,
  );
}
```

---

## 🔒 Security Rules

```javascript
// Add to firestore.rules
match /customers/{userId}/settings/{document=**} {
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId;
}
```

---

## 🎨 Color Reference

```dart
// Primary
AppTheme.primaryColor        // #6366F1 (Indigo)
AppTheme.accentColor          // Light variant

// Text
AppTheme.textColor            // #0F172A (Dark)
AppTheme.subtitleColor        // #64748B (Gray)

// Actions
Colors.orange                 // Warning (Logout)
Colors.redAccent              // Destructive (Delete)

// Backgrounds
Color(0xFFFAFAFA)            // Screen background
Colors.white                  // Card background
Colors.grey.shade100          // Border
```

---

## 📊 Data Structure

```json
{
  "notifications": {
    "enabled": true,
    "bookingUpdates": true,
    "promotions": true,
    "payments": true,
    "technicianStatus": true
  },
  "privacy": {
    "appLock": false
  },
  "preferences": {
    "language": "en"
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Settings don't save | Check Firestore rules, verify auth |
| Toggles revert | Check console for errors |
| Version not showing | Run `flutter pub get`, rebuild |
| Navigation fails | Check imports, verify routes |
| UI overflow | Check padding, use SafeArea |

---

## 📱 Testing Commands

```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Run tests
flutter test

# Build release
flutter build apk --release
```

---

## 🎯 Quick Checks

### Before Commit
- [ ] No compilation errors
- [ ] No diagnostic warnings
- [ ] Code formatted
- [ ] Imports organized

### Before Deploy
- [ ] All tests passing
- [ ] Firestore rules configured
- [ ] Version updated
- [ ] Documentation updated

---

## 📞 Quick Links

- **Full Docs**: `SETTINGS_FEATURE_DOCUMENTATION.md`
- **Visual Guide**: `SETTINGS_VISUAL_GUIDE.md`
- **Deployment**: `SETTINGS_DEPLOYMENT_CHECKLIST.md`
- **Summary**: `SETTINGS_COMPLETE_SUMMARY.md`

---

## 🎓 Key Concepts

### Optimistic Updates
```
1. Update UI immediately
2. Sync to Firestore
3. Revert on error
```

### Master Toggle
```
1. Master ON → Show sub-options
2. Master OFF → Hide sub-options
3. Sub-options retain state
```

### Error Handling
```
1. Try Firestore update
2. Catch error
3. Revert local state
4. Show SnackBar
```

---

## ⚡ Performance Tips

- Use StreamBuilder for real-time updates
- Implement optimistic updates
- Debounce rapid changes
- Cache settings locally
- Minimize Firestore reads

---

## 🔮 Future Features

- [ ] Change Phone Number
- [ ] Email Preferences
- [ ] Language Selection
- [ ] App Lock
- [ ] Theme Selection
- [ ] Backup & Restore

---

**Quick Reference Version**: 1.0.0
**Last Updated**: Current
**Status**: Ready to Use
