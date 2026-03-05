# ✅ FINAL BANNER ASSETS FIX - HomeFix Flutter Monorepo

## Current Status

### ✓ Verified Correct
- **Folder**: `apps/customer_app/assets/banners/` exists ✓
- **pubspec.yaml**: Has `- assets/banners/` ✓
- **Code**: home_screen.dart configured correctly ✓
- **Paths**: Using `assets/banners/ac_repair.jpg` etc. ✓

### ✗ Issue
- **Missing JPG files**: Folder has PNG files, needs JPG files

---

## 📋 Required Action

### Create These 4 Files

**Location**: `apps/customer_app/assets/banners/`

**Files needed**:
```
ac_repair.jpg          (1080x480px, JPEG)
cooler_fan.jpg         (1080x480px, JPEG)
referral.jpg           (1080x480px, JPEG)
deep_cleaning.jpg      (1080x480px, JPEG)
```

---

## 🛠️ How to Create Banner Images

### Method 1: Python Script (Fastest)
```bash
cd c:\Users\yash\projects\homefix
python3 gen_banners.py
```

This creates all 4 JPG files with gradients automatically.

### Method 2: Canva (Easiest)
1. Go to https://www.canva.com/
2. Create new design: 1080 x 480 pixels
3. Add gradient background
4. Add text (optional)
5. Download as JPEG
6. Save to `apps/customer_app/assets/banners/`

### Method 3: Manual (Photoshop/GIMP)
1. Create 1080x480 image
2. Add gradient
3. Export as JPEG
4. Save to folder

---

## ✅ Verification Checklist

Before running the app:

- [ ] Folder exists: `apps/customer_app/assets/banners/`
- [ ] File 1: `ac_repair.jpg` (1080x480)
- [ ] File 2: `cooler_fan.jpg` (1080x480)
- [ ] File 3: `referral.jpg` (1080x480)
- [ ] File 4: `deep_cleaning.jpg` (1080x480)
- [ ] All files are JPEG format (not PNG)
- [ ] File names are lowercase, no spaces
- [ ] pubspec.yaml has `- assets/banners/`

---

## 🚀 Rebuild App

After creating banner files:

```bash
cd apps/customer_app
flutter clean
flutter pub get
flutter run
```

**IMPORTANT**: Hot reload will NOT load new assets. Must do full rebuild.

---

## 📊 Code Configuration

### pubspec.yaml ✓
```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/
    - assets/banners/
    - assets/icons/
    - assets/images/
    - assets/categories/
    - assets/services/
    - lib/l10n/
```

### home_screen.dart ✓
```dart
final banners = [
  {'title': 'AC Repair', 'subtitle': '30% OFF', 'image': 'assets/banners/ac_repair.jpg'},
  {'title': 'Cooler & Fan', 'subtitle': 'Starting ₹199', 'image': 'assets/banners/cooler_fan.jpg'},
  {'title': 'Referral & Earn', 'subtitle': 'Get ₹100', 'image': 'assets/banners/referral.jpg'},
  {'title': 'Deep Cleaning', 'subtitle': 'Flat 25% OFF', 'image': 'assets/banners/deep_cleaning.jpg'},
];

Image.asset(
  banner['image']!,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
  },
)
```

---

## 🔍 Troubleshooting

### Banners show grey placeholder with "image not supported" icon
**Cause**: Banner JPG files missing
**Fix**:
1. Create 4 JPG files using Python script or Canva
2. Place in `apps/customer_app/assets/banners/`
3. Run `flutter clean && flutter pub get && flutter run`

### "Asset not found" error in console
**Cause**: pubspec.yaml not configured
**Fix**:
1. Open `apps/customer_app/pubspec.yaml`
2. Verify `- assets/banners/` exists under `flutter: assets:`
3. Run `flutter clean && flutter pub get`

### Banners don't update after adding files
**Cause**: Flutter cache not cleared
**Fix**:
```bash
flutter clean
flutter pub get
flutter run
```

### Files in wrong location
**Wrong**:
- `homefix/assets/banners/`
- `assets/banners/`
- `apps/assets/banners/`

**Correct**:
- `apps/customer_app/assets/banners/`

---

## 📁 Monorepo Structure

```
homefix/
├── apps/
│   └── customer_app/
│       ├── assets/
│       │   └── banners/          ← Banner images go HERE
│       │       ├── ac_repair.jpg
│       │       ├── cooler_fan.jpg
│       │       ├── referral.jpg
│       │       └── deep_cleaning.jpg
│       ├── lib/
│       │   └── features/
│       │       └── home/
│       │           └── home_screen.dart
│       └── pubspec.yaml
└── ...
```

---

## 🎯 Quick Summary

1. **Create 4 JPG files** (1080x480px each)
2. **Place in**: `apps/customer_app/assets/banners/`
3. **Run**: `flutter clean && flutter pub get && flutter run`
4. **Result**: Banners display on Home Screen

---

## ✨ Expected Result

Home screen banner carousel should display:
- AC Repair (30% OFF)
- Cooler & Fan (Starting ₹199)
- Referral & Earn (Get ₹100)
- Deep Cleaning (Flat 25% OFF)

With smooth horizontal scrolling and page indicator dots.

---

**Status**: Ready for banner images ✅
**Time to fix**: 5-10 minutes
**Difficulty**: Easy
**Next step**: Create 4 JPG files
