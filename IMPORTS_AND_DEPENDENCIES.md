# Custom Request Feature - Required Imports & Dependencies

## 📦 pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  firebase_storage: ^11.5.0
  cloud_firestore: ^4.14.0
  firebase_app_check: ^0.2.1
  
  # Image & File Handling
  image_picker: ^1.0.0
  
  # Date & Time
  intl: ^0.19.0
  
  # Existing dependencies
  go_router: ^latest
  provider: ^latest
  # ... other existing dependencies
```

---

## 📥 Required Imports

### firebase_init.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
```

### custom_request_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'request_form.dart';
import 'status_card.dart';
```

### status_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
```

### request_form.dart
```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'category_selector.dart';
import 'image_picker_widget.dart';
```

### category_selector.dart
```dart
import 'package:flutter/material.dart';
```

### image_picker_widget.dart
```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
```

---

## 🔧 Android Configuration

### android/app/build.gradle
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### android/app/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions for image picker -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- Permissions for location (if needed) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application>
        <!-- Your application configuration -->
    </application>
</manifest>
```

### android/app/src/main/AndroidManifest.xml
```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PICK" />
        <data android:mimeType="image/*" />
    </intent>
    <intent>
        <action android:name="android.media.action.IMAGE_CAPTURE" />
    </intent>
</queries>
```

---

## 🍎 iOS Configuration

### ios/Podfile
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

### ios/Runner/Info.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Camera permission -->
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos for service requests</string>
    
    <!-- Photo library permission -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to select images for service requests</string>
    
    <!-- Photo library add-only permission -->
    <key>NSPhotoLibraryAddOnlyUsageDescription</key>
    <string>This app needs permission to save photos</string>
    
    <!-- Location permission (if needed) -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs your location to find nearby technicians</string>
    
    <!-- Other existing keys -->
</dict>
</plist>
```

---

## 🔐 Firebase Configuration Files

### google-services.json (Android)
Place in: `apps/customer_app/android/app/google-services.json`

Get from Firebase Console:
1. Go to Firebase Console
2. Select your project
3. Go to Project Settings
4. Download `google-services.json`
5. Place in `android/app/` directory

### GoogleService-Info.plist (iOS)
Place in: `apps/customer_app/ios/Runner/GoogleService-Info.plist`

Get from Firebase Console:
1. Go to Firebase Console
2. Select your project
3. Go to Project Settings
4. Download `GoogleService-Info.plist`
5. Place in `ios/Runner/` directory

---

## 🚀 Environment Setup

### Windows
```powershell
# Navigate to customer app
cd C:\Users\yash\projects\homefix\apps\customer_app

# Get dependencies
flutter pub get

# Run app
flutter run
```

### macOS/Linux
```bash
# Navigate to customer app
cd ~/projects/homefix/apps/customer_app

# Get dependencies
flutter pub get

# Run app
flutter run
```

---

## 📋 Verification Commands

### Check Flutter Version
```bash
flutter --version
```

### Check Dependencies
```bash
flutter pub get
flutter pub outdated
```

### Check Firebase Setup
```bash
firebase --version
firebase login
firebase projects:list
```

### Run Tests
```bash
flutter test
```

### Build APK
```bash
flutter build apk --release
```

### Build iOS
```bash
flutter build ios --release
```

---

## 🔗 File Paths

### Customer App Structure
```
apps/customer_app/
├── lib/
│   ├── core/
│   │   └── firebase/
│   │       └── firebase_init.dart
│   ├── features/
│   │   └── custom_request/
│   │       └── presentation/
│   │           ├── custom_request_screen.dart
│   │           ├── status_card.dart
│   │           ├── request_form.dart
│   │           ├── category_selector.dart
│   │           └── image_picker_widget.dart
│   └── main.dart
├── android/
│   └── app/
│       ├── google-services.json
│       └── AndroidManifest.xml
├── ios/
│   └── Runner/
│       ├── GoogleService-Info.plist
│       └── Info.plist
└── pubspec.yaml
```

---

## 🔄 Import Order (Best Practice)

```dart
// 1. Dart imports
import 'dart:io';
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// 4. Third-party imports
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// 5. Local imports
import 'request_form.dart';
import 'status_card.dart';
```

---

## ✅ Pre-Deployment Checklist

- [ ] All dependencies added to pubspec.yaml
- [ ] `flutter pub get` executed
- [ ] google-services.json placed in android/app/
- [ ] GoogleService-Info.plist placed in ios/Runner/
- [ ] Android permissions added to AndroidManifest.xml
- [ ] iOS permissions added to Info.plist
- [ ] Firebase initialized in main.dart
- [ ] All code files copied to correct locations
- [ ] Navigation route added
- [ ] No import errors
- [ ] App runs without errors

---

## 🐛 Common Import Issues

### Issue: "firebase_app_check" not found
**Solution**: Add to pubspec.yaml and run `flutter pub get`

### Issue: "image_picker" not found
**Solution**: Add to pubspec.yaml and run `flutter pub get`

### Issue: "intl" not found
**Solution**: Add to pubspec.yaml and run `flutter pub get`

### Issue: "Cannot find 'request_form.dart'"
**Solution**: Verify file path and relative import

### Issue: "Cannot find 'status_card.dart'"
**Solution**: Verify file path and relative import

---

## 📞 Support

For import issues:
1. Run `flutter pub get`
2. Run `flutter clean`
3. Run `flutter pub get` again
4. Restart IDE
5. Check file paths
6. Verify pubspec.yaml syntax

---

**Version**: 1.0
**Status**: ✅ COMPLETE
**Last Updated**: 2024
