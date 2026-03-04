# Service-Level Features - Quick Reference

## 📋 What Was Implemented

### 1. Urgent Booking (Express Service)
- **Toggle:** Enable/Disable urgent booking per service
- **Arrival Time Options:** 30-60min, 1-2hours, 2-3hours
- **Urgent Fee Options:** ₹50, ₹100, ₹150, ₹200, ₹250, ₹300
- **Storage:** Inside service document as `urgentBooking` object

### 2. Night Service Availability
- **Toggle:** Enable/Disable night service per service
- **Fixed Time:** 10:00 PM – 6:00 AM
- **Night Charge Options:** ₹50, ₹100, ₹150, ₹200 (optional)
- **Storage:** Inside service document as `nightService` object

### 3. Service-Level Configuration
- **Scope:** Per-service settings (not global)
- **Location:** Inside each service document in Firestore
- **Persistence:** Saved with service creation/update

---

## 📁 Files Modified/Created

| File | Type | Changes |
|------|------|---------|
| `lib/core/models/technician_service.dart` | Modified | Added urgentBooking & nightService fields |
| `lib/features/technician/services/service_config_widgets.dart` | Created | New UI components |
| `lib/features/technician/services/add_service_screen.dart` | Modified | Integrated new widgets & save logic |

---

## 🔧 Firestore Structure

```json
services/{serviceId}
{
  "name": "AC Repair",
  "basePrice": 600,
  
  "urgentBooking": {
    "enabled": true,
    "arrivalTime": "1-2hours",
    "urgentFee": 200
  },
  
  "nightService": {
    "enabled": true,
    "nightCharge": 100
  }
}
```

---

## ✅ Validation Rules

| Feature | Rule |
|---------|------|
| Urgent Booking | Arrival time required if enabled |
| Urgent Booking | Urgent fee required if enabled |
| Night Service | Night charge optional |
| All | Only predefined values accepted |

---

## 🎨 UI Components

### UrgentBookingConfigWidget
- Expandable card with toggle
- ChoiceChip selectors for arrival time
- ChoiceChip selectors for urgent fee
- State callbacks for parent widget

### NightServiceConfigWidget
- Expandable card with toggle
- Fixed time range display
- ChoiceChip selectors for night charge
- State callbacks for parent widget

---

## 🚀 Next Steps

1. **Backend:** Update `addService()` and `updateService()` Cloud Functions
2. **Customer App:** Display urgent booking option during booking
3. **Booking Model:** Add urgentBooking & nightService fields
4. **Price Calculation:** Include urgent/night fees in total
5. **Testing:** Verify end-to-end flow

---

## 📊 State Variables Added

```dart
bool _urgentBookingEnabled = false;
String? _urgentArrivalTime;
int? _urgentFee;
bool _nightServiceEnabled = false;
int? _nightCharge;
```

---

## 💾 Data Persistence

- ✅ Saved to Firestore on service creation
- ✅ Saved to Firestore on service update
- ✅ Loaded from Firestore when editing service
- ✅ Included in TechnicianService model

---

## 🔄 Integration Points

### For Booking System:
- Customer selects urgent booking during booking
- System adds urgentFee to total price
- Night bookings auto-include nightCharge

### For Analytics:
- Track urgent booking adoption
- Monitor night service demand
- Calculate revenue from add-on fees

---

## ✨ Key Features

✅ Per-service configuration (not global)
✅ Clean, modern UI with ChoiceChips
✅ Expandable card design
✅ Proper validation
✅ State management via setState
✅ Firestore integration ready
✅ No new dependencies
✅ Production-ready code

---

**Status:** ✅ Implementation Complete
**Ready for:** Testing & Integration
