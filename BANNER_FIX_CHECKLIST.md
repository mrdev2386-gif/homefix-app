# ✅ Banner Images Fix - HomeFix Customer App

## Current Status

### ✓ Already Configured
- **pubspec.yaml**: `- assets/banners/` registered ✓
- **home_screen.dart**: Banner code correct ✓
- **Banner paths**: `assets/banners/ac_repair.jpg` etc. ✓
- **Image loading**: `Image.asset()` with error handler ✓
- **Folder exists**: `apps/customer_app/assets/banners/` ✓

### ✗ Missing
- **4 JPG banner files** (need to be created)

---

## 📁 Required Files

Create these 4 files in: `apps/customer_app/assets/banners/`

```
ac_repair.jpg          (1080x480px)
cooler_fan.jpg         (1080x480px)
referral.jpg           (1080x480px)
deep_cleaning.jpg      (1080x480px)
```

---

## 🎨 Banner Specifications

| Banner | Filename | Gradient | Text |
|--------|----------|----------|------|
| 1 | `ac_repair.jpg` | Cyan → Dark Cyan | "AC Repair" + "30% OFF" |
| 2 | `cooler_fan.jpg` | Amber → Dark Amber | "Cooler & Fan" + "Starting ₹199" |
| 3 | `referral.jpg` | Green → Dark Green | "Referral & Earn" + "Get ₹100" |
| 4 | `deep_cleaning.jpg` | Pink → Dark Pink | "Deep Cleaning" + "Flat 25% OFF" |

**All banners:**
- Size: 1080 x 480 pixels
- Format: JPEG (quality 95%)
- Text: White color, positioned at bottom-left

---

## 🛠️ How to Create Banners

### Option 1: Online (Easiest)
1. Go to https://www.canva.com/
2. Create new design: 1080 x 480 pixels
3. Add gradient background
4. Add text overlays
5. Download as JPEG
6. Save to `apps/customer_app/assets/banners/`

### Option 2: Python Script
Run the provided script:
```bash
python3 create_banner_images.py
```

This will generate all 4 banners automatically.

### Option 3: Manual (Photoshop/GIMP)
1. Create 1080 x 480 image
2. Add gradient layer
3. Add text layer
4. Export as JPEG
5. Save to folder

---

## ✅ Verification Checklist

- [ ] Folder exists: `apps/customer_app/assets/banners/`
- [ ] File 1: `ac_repair.jpg` (1080x480)
- [ ] File 2: `cooler_fan.jpg` (1080x480)
- [ ] File 3: `referral.jpg` (1080x480)
- [ ] File 4: `deep_cleaning.jpg` (1080x480)
- [ ] pubspec.yaml has `- assets/banners/`
- [ ] All files are JPEG format
- [ ] All files have correct names (lowercase, no spaces)

---

## 🚀 Rebuild App

After creating banner files:

```bash
flutter clean
flutter pub get
flutter run
```

**Important**: Hot reload is NOT enough for assets. Must do full rebuild.

---

## 🔍 Troubleshooting

### Banners show grey placeholder
**Cause**: Banner files missing or wrong location
**Fix**: 
- Check folder: `apps/customer_app/assets/banners/`
- Verify all 4 JPG files exist
- Check file names are exact (lowercase)

### "Asset not found" error
**Cause**: pubspec.yaml not updated
**Fix**:
- Open `pubspec.yaml`
- Verify `- assets/banners/` exists
- Run `flutter clean && flutter pub get`

### Banners don't update
**Cause**: Flutter cache not cleared
**Fix**:
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📊 Code Verification

### Banner Configuration ✓
```dart
final banners = [
  {'title': 'AC Repair', 'subtitle': '30% OFF', 'image': 'assets/banners/ac_repair.jpg'},
  {'title': 'Cooler & Fan', 'subtitle': 'Starting ₹199', 'image': 'assets/banners/cooler_fan.jpg'},
  {'title': 'Referral & Earn', 'subtitle': 'Get ₹100', 'image': 'assets/banners/referral.jpg'},
  {'title': 'Deep Cleaning', 'subtitle': 'Flat 25% OFF', 'image': 'assets/banners/deep_cleaning.jpg'},
];
```

### Image Loading ✓
```dart
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

### pubspec.yaml ✓
```yaml
flutter:
  assets:
    - assets/banners/
```

---

## 🎯 Next Steps

1. **Create 4 banner JPG files** (use Canva or Python script)
2. **Place in folder**: `apps/customer_app/assets/banners/`
3. **Run rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
4. **Verify**: Banners display on Home Screen

---

**Status**: Code ready, waiting for banner images ✅
**Estimated time**: 5-10 minutes to create images
**Difficulty**: Easy (use Canva)
