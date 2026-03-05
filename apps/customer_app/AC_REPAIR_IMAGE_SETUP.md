# AC Repair Image Asset - Setup Instructions

## 📍 Required File Location

```
apps/customer_app/assets/images/ac_repair.png
```

## 🎨 Image Specifications

### Recommended Specs:
- **Format:** PNG with transparency
- **Size:** 200x200px minimum (300x300px ideal)
- **Background:** Transparent
- **Colors:** White or light colors (displays on orange gradient)
- **Content:** AC unit, technician, or AC repair tools

### Design Guidelines:
1. **Simple & Clean:** Avoid complex details
2. **High Contrast:** Should be visible on orange background
3. **Professional:** Represents home service quality
4. **Optimized:** Keep file size under 100KB

## 🔍 Where to Find Images

### Option 1: Free Stock Images
- **Unsplash:** https://unsplash.com/s/photos/air-conditioner-repair
- **Pexels:** https://www.pexels.com/search/ac-repair/
- **Pixabay:** https://pixabay.com/images/search/air-conditioner/

### Option 2: Icon Libraries
- **Flaticon:** https://www.flaticon.com/search?word=air%20conditioner
- **Icons8:** https://icons8.com/icons/set/air-conditioner
- **Noun Project:** https://thenounproject.com/search/?q=ac+repair

### Option 3: AI Generation
Use AI tools like:
- DALL-E
- Midjourney
- Stable Diffusion

**Prompt:** "Professional AC repair technician icon, white silhouette, transparent background, simple design"

## 🛠️ Image Processing Steps

### 1. Download/Create Image
Choose an appropriate AC repair image

### 2. Remove Background (if needed)
Use tools like:
- **remove.bg** - https://www.remove.bg/
- **Photoshop** - Magic Wand tool
- **GIMP** - Free alternative

### 3. Resize & Optimize
```bash
# Using ImageMagick (if installed)
magick convert input.png -resize 300x300 -background none ac_repair.png

# Or use online tools:
# - TinyPNG: https://tinypng.com/
# - Squoosh: https://squoosh.app/
```

### 4. Place in Project
```
Copy to: apps/customer_app/assets/images/ac_repair.png
```

## 📦 Quick Setup (Placeholder)

If you don't have an image yet, the app will show a fallback icon automatically.

**Fallback behavior:**
```dart
errorBuilder: (context, error, stackTrace) {
  return Icon(
    Icons.local_offer,
    size: 60,
    color: Colors.white.withOpacity(0.15),
  );
}
```

## ✅ Verification

After adding the image:

1. **Hot Reload:** Press `r` in terminal
2. **Check Banner:** Scroll to "Get 20% Off" banner
3. **Verify Image:** AC repair image should appear on right side
4. **Test Fallback:** Rename image temporarily to test error handling

## 🎨 Example Image Ideas

### Style 1: AC Unit Icon
- Simple AC unit illustration
- White outline on transparent background
- Minimalist design

### Style 2: Technician Silhouette
- Person with tools
- Working on AC unit
- Professional appearance

### Style 3: Tools & Equipment
- Wrench, screwdriver icons
- AC-related tools
- Service-oriented

## 📝 Alternative: Use Network Image

If you prefer not to use local assets, you can modify the code to use a network image:

```dart
Image.network(
  'https://your-cdn.com/ac_repair.png',
  height: 90,
  fit: BoxFit.contain,
  errorBuilder: (context, error, stackTrace) {
    return Icon(
      Icons.local_offer,
      size: 60,
      color: Colors.white.withOpacity(0.15),
    );
  },
)
```

## 🚨 Important Notes

1. **No Crash:** App won't crash if image is missing (fallback icon shows)
2. **Performance:** Optimize image size for faster loading
3. **Licensing:** Ensure you have rights to use the image
4. **Testing:** Test on multiple devices for visibility

---

**Status:** Image asset configured, ready to add file
**Path:** `apps/customer_app/assets/images/ac_repair.png`
**Fallback:** Automatic icon fallback if image missing
