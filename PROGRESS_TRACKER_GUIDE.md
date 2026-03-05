# Booking Progress Tracker - Implementation Guide

## 📍 Quick Start

### Add to Booking Detail Screen

**File:** `apps/customer_app/lib/features/bookings/presentation/booking_detail_screen.dart`

**Import:**
```dart
import '../widgets/booking_progress_tracker.dart';
```

**Usage:**
```dart
// Inside your build method, add after booking header:
BookingProgressTracker(
  currentStatus: booking.status,
),
const SizedBox(height: 16),
```

---

## 🎨 Visual Example

### Progress States:

**1. Pending Admin (pending_admin):**
```
[●]━━━[○]━━━[○]━━━[○]━━━[○]
 ⏳    ⏳    ⏳    ⏳    ⏳
Pending Assigned Payment Confirmed Done
```

**2. Technician Pending (technician_pending):**
```
[✓]━━━[●]━━━[○]━━━[○]━━━[○]
 ✓     👤    ⏳    ⏳    ⏳
Pending Assigned Payment Confirmed Done
```

**3. Awaiting Payment (awaiting_payment):**
```
[✓]━━━[✓]━━━[●]━━━[○]━━━[○]
 ✓     ✓     💳    ⏳    ⏳
Pending Assigned Payment Confirmed Done
```

**4. Confirmed (confirmed):**
```
[✓]━━━[✓]━━━[✓]━━━[●]━━━[○]
 ✓     ✓     ✓     ✓     ⏳
Pending Assigned Payment Confirmed Done
```

**5. Completed (completed):**
```
[✓]━━━[✓]━━━[✓]━━━[✓]━━━[●]
 ✓     ✓     ✓     ✓     ✓
Pending Assigned Payment Confirmed Done
```

---

## 🔧 Customization

### Change Colors:

Edit `booking_progress_tracker.dart`:

```dart
// Active step color
color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade200,

// Active text color
color: isActive ? const Color(0xFF6366F1) : Colors.grey.shade500,
```

### Change Step Labels:

```dart
_ProgressStep(
  status: 'pending_admin',
  label: 'Your Label', // Change this
  icon: Icons.your_icon, // Change this
),
```

### Add More Steps:

```dart
List<_ProgressStep> _getSteps() {
  return [
    // ... existing steps
    _ProgressStep(
      status: 'your_new_status',
      label: 'New Step',
      icon: Icons.new_icon,
    ),
  ];
}
```

---

## 📱 Responsive Design

The tracker automatically adjusts to screen width:
- ✅ Works on small screens (320px+)
- ✅ Scales with screen size
- ✅ Text wraps if needed
- ✅ Icons remain visible

---

## 🎯 Status Mapping

| Booking Status | Progress Step | Index |
|----------------|---------------|-------|
| `pending_admin` | Pending | 0 |
| `technician_pending` | Assigned | 1 |
| `awaiting_payment` | Payment | 2 |
| `confirmed` | Confirmed | 3 |
| `in_progress` | Confirmed | 3 |
| `completed` | Done | 4 |
| `cancelled` | Special | -1 |

---

## 💡 Tips

1. **Add to Detail Screen:** Best placed at the top of booking details
2. **Add Padding:** Use 16px padding around the widget
3. **Add Margin:** Use 16px bottom margin for spacing
4. **Responsive:** Test on different screen sizes
5. **Accessibility:** Icons help users understand progress

---

## 🐛 Troubleshooting

### Progress not showing correctly?
- Check booking status is lowercase
- Verify status is in the mapping
- Check console for debug logs

### Layout overflow?
- Ensure parent has bounded width
- Add padding to prevent edge overflow
- Test on small screens (320px)

### Colors not matching?
- Update color constants in widget
- Ensure theme colors are consistent
- Check Material 3 color scheme

---

## ✅ Testing Checklist

- [ ] Shows correct step for each status
- [ ] Completed steps show checkmark
- [ ] Active step is highlighted
- [ ] Lines connect steps properly
- [ ] Works on small screens
- [ ] Text is readable
- [ ] Icons are visible
- [ ] Colors match design

---

**Implementation Time:** ~5 minutes  
**Difficulty:** Easy  
**Impact:** High (Better UX)

---

**END OF GUIDE**
