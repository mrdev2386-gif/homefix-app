# Custom Request Timeline - Quick Reference

## 🚀 What Was Done

Refactored "My Requests" screen with **dynamic timeline-based tracking**:

✅ **Single Source of Truth**: `CustomRequestStatusMapper`  
✅ **Reusable Timeline Widget**: `TimelineStepWidget`  
✅ **Expandable Cards**: `ExpandableRequestCard`  
✅ **Dynamic CTA Buttons**: Based on Firestore status  
✅ **No Hardcoded Logic**: All status mapping centralized  

---

## 📂 Files Created

```
lib/
├── core/
│   └── utils/
│       └── custom_request_status_mapper.dart  ← Single source of truth
└── features/
    └── custom_request/
        ├── presentation/
        │   └── custom_request_screen.dart      ← Updated
        └── widgets/
            ├── timeline_step_widget.dart       ← Reusable timeline step
            └── expandable_request_card.dart    ← Expandable card with timeline
```

---

## 🎯 Key Features

### 1. Timeline Steps (7 Steps)
```
1. Request Created
2. Sent to Admin
3. Admin Approved
4. Sent to Technician
5. Technician Accepted
6. Payment Pending
7. Service Completed
```

### 2. Status Mapping
```dart
// Firestore Status → Timeline Steps
'pending_admin'       → Steps 1-2 completed, Step 2 current
'technician_pending'  → Steps 1-4 completed, Step 4 current
'awaiting_payment'    → Steps 1-6 completed, Step 6 current
'confirmed'           → Steps 1-6 completed, Step 7 current
'completed'           → All steps completed
```

### 3. Dynamic CTA Buttons
```dart
'pending_admin'      → [Cancel Request]
'technician_pending' → [View Details]
'awaiting_payment'   → [Pay Now]
'confirmed'          → [Track Technician] [Call Technician]
'completed'          → [Rate Service]
```

---

## 💻 Usage Example

```dart
// In your screen
Widget _buildRequestCard(Map<String, dynamic> request) {
  return ExpandableRequestCard(
    request: request,
    onPayNow: () => _handlePayNow(request),
    onTrackTechnician: () => _handleTrackTechnician(request),
    onCallTechnician: () => _handleCallTechnician(request),
    onCancelRequest: () => _handleCancelRequest(request),
    onViewDetails: () => _handleViewDetails(request),
    onRateService: () => _handleRateService(request),
  );
}
```

---

## 🎨 UI States

### Collapsed
```
┌────────────────────────────┐
│ Fix Tap      [PENDING]     │
│ 🔧 Plumbing  📅 Jan 15     │
│     View Timeline ▼        │
└────────────────────────────┘
```

### Expanded
```
┌────────────────────────────┐
│ Fix Tap      [PENDING]     │
│ 🔧 Plumbing  📅 Jan 15     │
│     Hide Details ▲         │
├────────────────────────────┤
│ Request Timeline           │
│ ✅ Request Created         │
│ │  2h ago                  │
│ 🔵 Sent to Admin           │
│ │  [In Progress]           │
│ ⚪ Admin Approved          │
│ ⚪ Sent to Technician      │
│ ⚪ Technician Accepted     │
│ ⚪ Payment Pending         │
│ ⚪ Service Completed       │
│                            │
│ [Cancel Request]           │
└────────────────────────────┘
```

---

## 🔧 How to Customize

### Add New Status
Edit `custom_request_status_mapper.dart`:

```dart
case 'your_new_status':
  completedSteps.addAll(['created', 'sent_to_admin']);
  currentStep = 'your_step';
  break;
```

### Add New CTA
Edit `getCTAButtons()`:

```dart
case 'your_status':
  return [
    CTAButton(
      label: 'Your Action',
      icon: Icons.your_icon,
      action: CTAAction.yourAction,
      isPrimary: true,
    ),
  ];
```

### Change Colors
Edit `timeline_step_widget.dart`:

```dart
// Completed: Green
backgroundColor = Colors.green;

// Current: Blue
backgroundColor = Colors.blue;

// Pending: Grey
backgroundColor = Colors.grey[200];
```

---

## ✅ Testing

```bash
# Run app
flutter run

# Test scenarios:
1. Create request → Check timeline shows "Request Created"
2. Admin approves → Check "Admin Approved" turns green
3. Technician accepts → Check "Payment Pending" is current
4. Tap card → Check expand/collapse animation
5. Check CTA buttons appear for each status
```

---

## 📊 Status Flow

```
pending_admin
    ↓
technician_pending
    ↓
awaiting_payment
    ↓
confirmed
    ↓
completed
```

**Terminal States**: `cancelled`, `admin_rejected`, `technician_rejected`

---

## 🐛 Troubleshooting

### Timeline not updating?
- Check Firestore `status` field value
- Verify status mapping in `mapStatusToTimeline()`

### CTA buttons not showing?
- Check `getCTAButtons()` has case for your status
- Verify callback is passed to `ExpandableRequestCard`

### Animation not smooth?
- Check `AnimationController` duration (300ms)
- Verify `SingleTickerProviderStateMixin` is used

---

## 📚 Documentation

- **Full Guide**: `CUSTOM_REQUEST_TIMELINE_GUIDE.md`
- **Status Mapper**: `lib/core/utils/custom_request_status_mapper.dart`
- **Timeline Widget**: `lib/features/custom_request/widgets/timeline_step_widget.dart`
- **Card Widget**: `lib/features/custom_request/widgets/expandable_request_card.dart`

---

## 🎯 Benefits

✅ **No Hardcoded Logic**: All status mapping in one place  
✅ **Easy to Maintain**: Change status flow in one file  
✅ **Reusable**: Use timeline widget anywhere  
✅ **Dynamic**: UI updates automatically from Firestore  
✅ **Clean Code**: No duplicate logic  

---

**Status**: ✅ Production-Ready  
**Version**: 1.0  
**Contact**: 9508322397
