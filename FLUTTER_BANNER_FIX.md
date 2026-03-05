# 🔧 Flutter Banner Assets Fix - HomeFix Customer App

## ✅ Current Status

### Verified ✓
- **Folder location**: `apps/customer_app/assets/banners/` ✓
- **pubspec.yaml**: Correctly configured with `- assets/banners/` ✓
- **Code**: home_screen.dart uses correct paths ✓
- **Indentation**: pubspec.yaml has correct indentation ✓

### Issue ✗
- **Missing JPG files**: Folder has PNG files, but code expects JPG files

---

## 📁 Required Files

Location: `apps/customer_app/assets/banners/`

**Must create these 4 files:**
```
ac_repair.jpg
cooler_fan.jpg
referral.jpg
deep_cleaning.jpg
```

**Size**: 1080 x 480 pixels each
**Format**: JPEG (quality 95%)

---

## 🛠️ Solution

### Step 1: Create Banner Images

**Option A: Python Script (Automated)**
```bash
cd c:\Users\yash\projects\homefix
python3 gen_banners.py
```

This creates all 4 JPG files automatically with gradients.

**Option B: Online Tool (Easiest)**
1. Go to https://www.canva.com/
2. Create new design: 1080 x 480 pixels
3. Add gradient background
4. Download as JPEG
5. Save to `apps/customer_app/assets/banners/`

**Option C: Manual**
- Use Photoshop, GIMP, or Paint
- Create 1080x480 image
- Add gradient
- Export as JPEG
- Save to folder

---

### Step 2: Verify Files

Check that these files exist:
```
apps/customer_app/assets/banners/ac_repair.jpg
apps/customer_app/assets/banners/cooler_fan.jpg
apps/customer_app/assets/banners/referral.jpg
apps/customer_app/assets/banners/deep_cleaning.jpg
```

---

### Step 3: Full Rebuild

```bash
cd apps/customer_app
flutter clean
flutter pub get
flutter run
```

**Important**: Hot reload won't work for assets. Must do full rebuild.

---

## ✅ Verification Checklist

- [ ] 4 JPG files created in `apps/customer_app/assets/banners/`
- [ ] File names are exact (lowercase, no spaces)
- [ ] Each file is 1080x480 pixels
- [ ] Files are JPEG format (not PNG)
- [ ] pubspec.yaml has `- assets/banners/`
- [ ] Ran `flutter clean && flutter pub get`
- [ ] Ran `flutter run` (not hot reload)

---

## 📊 Code Verification

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

### Banners still show grey placeholder
**Check**:
1. Files exist in `apps/customer_app/assets/banners/`
2. File names are exact (lowercase)
3. Files are JPEG format
4. Ran `flutter clean && flutter pub get`

### "Asset not found" error
**Check**:
1. pubspec.yaml has `- assets/banners/`
2. Indentation is correct (2 spaces)
3. Ran `flutter clean`

### Banners don't update after adding files
**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎯 Quick Summary

1. **Create 4 JPG files** (use Python script or Canva)
2. **Place in**: `apps/customer_app/assets/banners/`
3. **Run**: `flutter clean && flutter pub get && flutter run`
4. **Done**: Banners should display

---

**Status**: Ready to add banner images ✅
**Time**: 5-10 minutes
**Difficulty**: Easy
