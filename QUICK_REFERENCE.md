# Quick Reference - Service Features Implementation

## 🎯 For Technician App (Service Creation)

### Validation Rules
```dart
// Urgent Booking
if (_urgentBookingEnabled) {
  if (_urgentArrivalTime == null || _urgentFee == null) {
    showError('Please select urgent arrival time and urgent fee');
    return;
  }
}

// Night Service
if (_nightServiceEnabled && _nightCharge == null) {
  showError('Please select night service charge');
  return;
}
```

### Save Service
```dart
await _functionsService.addService(
  name: name,
  price: price,
  imageUrl: imageUrl,
  category: category,
  urgentBooking: _urgentBookingEnabled ? {
    'enabled': true,
    'arrivalTime': _urgentArrivalTime,
    'urgentFee': _urgentFee,
  } : null,
  nightService: _nightServiceEnabled ? {
    'enabled': true,
    'nightCharge': _nightCharge,
  } : null,
);
```

### Allowed Values
- **urgentFee**: [50, 100, 150, 200, 250, 300]
- **arrivalTime**: ["30-60min", "1-2hours", "2-3hours"]
- **nightCharge**: [0, 50, 100, 150, 200]

---

## 🎯 For Customer App (Booking)

### Check Feature Availability
```dart
final urgentEnabled = service['urgentBooking']?['enabled'] == true;
final nightEnabled = service['nightService']?['enabled'] == true;
```

### Display Options
```dart
// Normal booking (always available)
_buildBookingOption(
  title: 'Normal Booking',
  price: service['price'],
)

// Urgent booking (if enabled)
if (urgentEnabled)
  _buildBookingOption(
    title: 'Urgent Booking',
    price: service['price'] + service['urgentBooking']['urgentFee'],
  )

// Night service (if enabled)
if (nightEnabled)
  _buildNightServiceOption(
    nightCharge: service['nightService']['nightCharge'],
  )
```

### Calculate Price (Server-Side)
```dart
final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
  .httpsCallable('calculateBookingPrice')
  .call({
    'serviceId': serviceId,
    'technicianId': technicianId,
    'isUrgentBooking': isUrgentSelected,
    'isNightBooking': isNightSelected,
  });

final finalPrice = result.data['finalPrice'];
final breakdown = result.data['breakdown'];
```

### Validate Before Booking
```dart
if (isUrgentSelected && !service['urgentBooking']['enabled']) {
  showError('Urgent booking not available');
  return;
}

if (isNightSelected && !service['nightService']['enabled']) {
  showError('Night service not available');
  return;
}
```

### Create Booking
```dart
final booking = {
  'customerId': customerId,
  'technicianId': technicianId,
  'serviceId': serviceId,
  'basePrice': service['price'],
  'isUrgentBooking': isUrgentSelected,
  'urgentArrivalTime': isUrgentSelected ? service['urgentBooking']['arrivalTime'] : null,
  'urgentFee': isUrgentSelected ? service['urgentBooking']['urgentFee'] : null,
  'isNightBooking': isNightSelected,
  'nightCharge': isNightSelected ? service['nightService']['nightCharge'] : null,
  'finalPrice': finalPrice,
  'priceBreakdown': breakdown,
};
```

---

## 🔒 Firestore Rules

### Validation Functions
```firestore
// Urgent Booking
function isValidUrgentBooking(data) {
  return data.urgentBooking == null || (
    data.urgentBooking.enabled == false ||
    (data.urgentBooking.enabled == true &&
     data.urgentBooking.arrivalTime in ['30-60min', '1-2hours', '2-3hours'] &&
     data.urgentBooking.urgentFee in [50, 100, 150, 200, 250, 300])
  );
}

// Night Service
function isValidNightService(data) {
  return data.nightService == null || (
    data.nightService.enabled == false ||
    (data.nightService.enabled == true &&
     data.nightService.nightCharge in [0, 50, 100, 150, 200])
  );
}
```

### Apply to Collections
```firestore
match /technicians/{technicianId}/services/{serviceId} {
  allow create, update: if 
    isValidUrgentBooking(request.resource.data) &&
    isValidNightService(request.resource.data);
}
```

---

## ☁️ Cloud Function

### Function Signature
```typescript
calculateBookingPrice({
  serviceId: string,
  technicianId: string,
  isUrgentBooking?: boolean,
  isNightBooking?: boolean,
})
```

### Returns
```typescript
{
  success: true,
  finalPrice: number,
  breakdown: {
    basePrice: number,
    urgentFee?: number,
    nightCharge?: number,
    finalPrice: number,
  }
}
```

### Error Cases
- Service not found → 404
- Urgent booking not enabled → 400
- Night service not enabled → 400
- Invalid fee configuration → 500

---

## 📊 Data Flow

### Technician Creates Service
```
1. Fill form (name, price, category)
2. Enable urgent booking → select arrivalTime + urgentFee
3. Enable night service → select nightCharge
4. Validate (no nulls, valid values)
5. Send to Cloud Function
6. Cloud Function validates and saves to Firestore
7. Firestore rules validate structure
8. Service saved with features
```

### Customer Books Service
```
1. View service details
2. Check if urgent booking enabled
3. Check if night service enabled
4. Select booking options
5. Call calculateBookingPrice Cloud Function
6. Receive finalPrice + breakdown
7. Create booking with finalPrice
8. Firestore rules validate booking
9. Booking created
```

---

## ✅ Testing Checklist

### Technician App
- [ ] Create service with urgent booking only
- [ ] Create service with night service only
- [ ] Create service with both features
- [ ] Edit service to add features
- [ ] Edit service to remove features
- [ ] Verify Firestore documents have correct structure
- [ ] Verify no null values in Firestore

### Customer App
- [ ] View service with urgent booking enabled
- [ ] View service with night service enabled
- [ ] Select urgent booking option
- [ ] Select night service option
- [ ] Calculate price with urgent booking
- [ ] Calculate price with night service
- [ ] Calculate price with both
- [ ] Verify price breakdown is correct
- [ ] Create booking with features
- [ ] Verify booking document has correct structure

### Firestore Rules
- [ ] Accept valid urgent booking configuration
- [ ] Reject invalid urgentFee
- [ ] Reject invalid arrivalTime
- [ ] Accept valid night service configuration
- [ ] Reject invalid nightCharge
- [ ] Reject partial configurations
- [ ] Accept null features (disabled)

---

## 🐛 Common Issues

### Issue: Null values in Firestore
**Solution**: Check validation in `_saveService()` - ensure features are only sent when enabled

### Issue: Invalid fee rejected by Firestore
**Solution**: Verify fee is in [50, 100, 150, 200, 250, 300]

### Issue: Cloud Function returns error
**Solution**: Check service exists, features are enabled, fees are valid

### Issue: Customer can't select urgent booking
**Solution**: Verify `service.urgentBooking.enabled == true`

---

## 📞 Support

For issues or questions:
1. Check SECURITY_AUDIT_COMPLETE.md for detailed documentation
2. Check IMPLEMENTATION_SUMMARY.md for overview
3. Review template files for implementation examples
4. Check Firestore rules for validation logic

---

**Last Updated**: 2024
**Version**: 1.0
**Status**: Production Ready ✅
