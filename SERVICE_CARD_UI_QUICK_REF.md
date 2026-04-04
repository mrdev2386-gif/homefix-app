# 🎨 Service Card Modern UI - Quick Reference

## ✅ CHANGES SUMMARY

### Files Updated:
1. ✅ `unified_service_card.dart` - Used in Home Screen sections
2. ✅ `service_card.dart` - Used in other service listings

---

## 🎯 NEW PRICING DISPLAY

### WITH DISCOUNT:
```
Service Title
₹299  ₹499        [40% OFF]
👤 Verified Pro
```

### WITHOUT DISCOUNT:
```
Service Title
₹499
👤 Verified Pro
```

---

## 🎨 COLOR SCHEME

| Element | Color | Font Size | Weight |
|---------|-------|-----------|--------|
| **Offer Price** | `Colors.green` | 16px | 800 (Extra Bold) |
| **Original Price** | `Colors.grey` (strikethrough) | 12px | 400 (Regular) |
| **Discount Badge** | `Colors.red` on `Colors.red.shade50` | 11px | 800 (Extra Bold) |

---

## 📐 LAYOUT STRUCTURE

```
┌─────────────────────────────────┐
│  ┌─────────────────────────┐   │
│  │   SERVICE IMAGE         │   │
│  │                         │   │
│  │  ⭐ 4.5        ❤️       │   │
│  │                         │   │
│  │              [40% OFF]  │   │ ← Red badge
│  └─────────────────────────┘   │
│                                 │
│  AC Repair Service              │
│                                 │
│  ₹299  ₹499                    │ ← Green + Grey strikethrough
│                                 │
│  👤 Verified Pro                │
│  [MUMBAI]                       │
│                                 │
│  ┌─────────────────────────┐   │
│  │    Get Service          │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
```

---

## 🔧 TECHNICAL IMPLEMENTATION

### Discount Calculation:
```dart
final hasOffer = service.offerPrice != null && 
                 service.offerPrice! > 0 && 
                 service.offerPrice! < service.basePrice;

final discount = hasOffer 
    ? ((service.basePrice - service.offerPrice!) / service.basePrice * 100).round()
    : 0;
```

### Price Display:
```dart
// Offer Price (Green)
Text(
  '₹${finalPrice.toStringAsFixed(0)}',
  style: GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: Colors.green,
  ),
),

// Original Price (Strikethrough)
if (hasOffer)
  Text(
    '₹${service.basePrice.toStringAsFixed(0)}',
    style: GoogleFonts.outfit(
      fontSize: 12,
      color: Colors.grey,
      decoration: TextDecoration.lineThrough,
    ),
  ),
```

### Discount Badge:
```dart
if (discount > 0)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$discount% OFF',
      style: GoogleFonts.outfit(
        color: Colors.red,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  ),
```

---

## 🧪 TESTING STEPS

1. **Clean Build:**
   ```powershell
   cd C:\Users\yash\projects\homefix\apps\customer_app
   flutter clean
   flutter pub get
   ```

2. **Run App:**
   ```powershell
   flutter run
   ```

3. **Verify Home Screen:**
   - Check "Recommended For You" section
   - Check "Top Rated Services" section
   - Check "Recently Added Services" section

4. **Test Cases:**
   - ✅ Services with offers show green price + strikethrough + badge
   - ✅ Services without offers show regular price only
   - ✅ Discount percentage calculates correctly
   - ✅ UI is responsive and clean

---

## 📊 EXPECTED BEHAVIOR

### Scenario 1: Service with 40% discount
- **Base Price:** ₹500
- **Offer Price:** ₹300
- **Display:** `₹300` (green) + `₹500` (strikethrough) + `40% OFF` (red badge)

### Scenario 2: Service with no discount
- **Base Price:** ₹500
- **Offer Price:** null or 0
- **Display:** `₹500` (green) only

---

## 🎯 KEY FEATURES

✅ **Modern Design** - Matches industry standards  
✅ **Clear Hierarchy** - Green price draws attention  
✅ **Savings Visible** - Discount badge prominent  
✅ **Minimal Code** - Uses existing data model  
✅ **Backward Compatible** - No breaking changes  

---

## 📱 WHERE TO SEE CHANGES

### Home Screen:
1. Scroll to "Recommended For You"
2. Scroll to "Top Rated Services"
3. Scroll to "Recently Added Services"

### Service List Screen:
1. Tap any category
2. View service cards in list

### Search Results:
1. Use search bar
2. View matching services

---

## 🔄 ROLLBACK (If Needed)

```bash
git checkout HEAD -- apps/customer_app/lib/features/dashboard/widgets/unified_service_card.dart
git checkout HEAD -- apps/customer_app/lib/features/dashboard/widgets/service_card.dart
```

---

**Status**: ✅ READY  
**Testing**: Required  
**Time**: 5 minutes
