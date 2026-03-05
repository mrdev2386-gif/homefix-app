# Banner Images Setup Guide - HomeFix Customer App

## ✅ Current Status

- **pubspec.yaml**: ✓ Already configured with `assets/banners/`
- **home_screen.dart**: ✓ Banner code is correct
- **Banner paths**: ✓ Correctly set to `assets/banners/ac_repair.jpg` etc.
- **Error handling**: ✓ Fallback UI shows grey placeholder if images missing

---

## 📁 Required Banner Images

Create these 4 files in: `apps/customer_app/assets/banners/`

```
apps/customer_app/assets/banners/
├── ac_repair.jpg          (1080x480px, Cyan gradient)
├── cooler_fan.jpg         (1080x480px, Amber gradient)
├── referral.jpg           (1080x480px, Green gradient)
└── deep_cleaning.jpg      (1080x480px, Pink gradient)
```

---

## 🎨 Banner Specifications

### 1. AC Repair
- **Filename**: `ac_repair.jpg`
- **Dimensions**: 1080 x 480 pixels
- **Gradient**: Cyan (#06B6D4) → Dark Cyan (#009AB4)
- **Text**: "AC Repair" (title) + "30% OFF" (subtitle)
- **Format**: JPEG, Quality 95%

### 2. Cooler & Fan
- **Filename**: `cooler_fan.jpg`
- **Dimensions**: 1080 x 480 pixels
- **Gradient**: Amber (#F59E0B) → Dark Amber (#D97706)
- **Text**: "Cooler & Fan" (title) + "Starting ₹199" (subtitle)
- **Format**: JPEG, Quality 95%

### 3. Referral & Earn
- **Filename**: `referral.jpg`
- **Dimensions**: 1080 x 480 pixels
- **Gradient**: Green (#22C55E) → Dark Green (#16A34A)
- **Text**: "Referral & Earn" (title) + "Get ₹100" (subtitle)
- **Format**: JPEG, Quality 95%

### 4. Deep Cleaning
- **Filename**: `deep_cleaning.jpg`
- **Dimensions**: 1080 x 480 pixels
- **Gradient**: Pink (#EC4899) → Dark Pink (#DB2777)
- **Text**: "Deep Cleaning" (title) + "Flat 25% OFF" (subtitle)
- **Format**: JPEG, Quality 95%

---

## 🛠️ How to Create Banner Images

### Option 1: Using Online Tools
1. Go to https://www.canva.com/
2. Create new design: 1080 x 480 pixels
3. Add gradient background
4. Add text overlays
5. Download as JPEG
6. Save to `apps/customer_app/assets/banners/`

### Option 2: Using Python (PIL)
```python
from PIL import Image, ImageDraw, ImageFont

# Create image with gradient
img = Image.new('RGB', (1080, 480), (6, 182, 212))
draw = ImageDraw.Draw(img)

# Draw gradient
for y in range(480):
    r = int(6 + (0 - 6) * y / 480)
    g = int(182 + (150 - 182) * y / 480)
    b = int(212 + (180 - 212) * y / 480)
    draw.line([(0, y), (1080, y)], fill=(r, g, b))

# Add text
font = ImageFont.truetype("arial.ttf", 60)
draw.text((60, 120), "AC Repair", fill=(255, 255, 255), font=font)
draw.text((60, 200), "30% OFF", fill=(255, 255, 255), font=font)

# Save
img.save('apps/customer_app/assets/banners/ac_repair.jpg', 'JPEG', quality=95)
```

### Option 3: Using Photoshop/GIMP
1. Create new image: 1080 x 480 pixels
2. Add gradient layer
3. Add text layer
4. Export as JPEG
5. Save to `apps/customer_app/assets/banners/`

---

## ✅ Verification Checklist

After creating banner images:

- [ ] All 4 JPG files exist in `apps/customer_app/assets/banners/`
- [ ] Each file is 1080 x 480 pixels
- [ ] File names match exactly (lowercase, no spaces)
- [ ] pubspec.yaml has `- assets/banners/` entry
- [ ] Run `flutter clean && flutter pub get`
- [ ] Run `flutter run`
- [ ] Banners display correctly on Home Screen

---

## 🔧 Troubleshooting

### Banners show grey placeholder with "image not supported" icon
**Solution**: Banner image files are missing or in wrong location
- Check: `apps/customer_app/assets/banners/` folder exists
- Check: All 4 JPG files are present
- Check: File names are exactly: `ac_repair.jpg`, `cooler_fan.jpg`, `referral.jpg`, `deep_cleaning.jpg`

### "Asset not found" error in console
**Solution**: pubspec.yaml not updated
- Open: `apps/customer_app/pubspec.yaml`
- Verify: `- assets/banners/` is under `flutter: assets:`
- Run: `flutter clean && flutter pub get`

### Banners don't update after adding images
**Solution**: Flutter cache not cleared
- Run: `flutter clean`
- Run: `flutter pub get`
- Run: `flutter run`

---

## 📊 Current Code Status

### home_screen.dart - Banner Configuration ✓
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

---

## 🎯 Next Steps

1. **Create banner images** using one of the methods above
2. **Place in folder**: `apps/customer_app/assets/banners/`
3. **Run commands**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
4. **Verify**: Banners display on Home Screen

---

## 📞 Support

If banners still don't load:
1. Check file paths are correct
2. Verify pubspec.yaml is saved
3. Run `flutter clean` and `flutter pub get`
4. Restart the app with `flutter run`

---

**Status**: Ready for banner images ✅
**Code**: Complete and tested ✅
**Fallback**: Grey placeholder with icon ✅
