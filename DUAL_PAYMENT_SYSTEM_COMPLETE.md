# DUAL PAYMENT SYSTEM IMPLEMENTATION - COMPLETE GUIDE

## 🎯 OVERVIEW

HomeFix now supports **TWO payment methods**:
1. **Online Payment (Razorpay)** - Customer pays BEFORE service starts
2. **After-Service Payment** - Customer pays AFTER service completion (manual confirmation)

---

## 📊 SYSTEM ARCHITECTURE

### Payment Flow Decision Tree

```
Customer Creates Booking
         |
         v
    Select Payment Method
         |
    +----+----+
    |         |
    v         v
 ONLINE   AFTER-SERVICE
    |         |
    v         v
Pay Now   Service First
    |         |
    v         v
Confirmed  Pending Admin
    |         |
    v         v
Service    Admin Approves
Starts         |
    |         v
    |    Technician Accepts
    |         |
    v         v
Service   Service Starts
Complete      |
    |         v
    |    Service Complete
    |         |
    v         v
 Review   Customer Pays
           (Manual/Cash/UPI)
              |
              v
         Technician Confirms
              |
              v
           Completed
```

---

## 🔧 BACKEND IMPLEMENTATION

### 1. Booking Schema Updates

**New Fields Added:**
```typescript
{
  paymentMethod: 'online' | 'after_service',  // NEW
  payment: {
    paymentMethod: 'online' | 'after_service', // NEW
    status: 'pending' | 'processing' | 'paid' | 'failed',
    razorpayOrderId?: string,
    razorpayPaymentId?: string,
    // ... existing fields
  }
}
```

**Status Flow by Payment Method:**

**Online Payment:**
```
awaiting_payment → (payment) → confirmed → approved_by_admin → 
technician_accepted → service_in_progress → service_completed → completed
```

**After-Service Payment:**
```
pending → approved_by_admin → technician_accepted → 
service_in_progress → service_completed → (payment) → completed
```

---

### 2. Cloud Functions Modified

#### A. `createBookingRequest` (unified_booking_lifecycle.ts)

**Changes:**
- Accepts `paymentMethod` parameter ('online' | 'after_service')
- Sets initial status based on payment method:
  - `online` → `awaiting_payment`
  - `after_service` → `pending`
- Stores `paymentMethod` in booking document

**Usage:**
```javascript
const result = await createBookingRequest({
  serviceId: 'xxx',
  technicianId: 'yyy',
  paymentMethod: 'online', // or 'after_service'
  // ... other fields
});
```

---

#### B. `createPaymentOrder` (razorpay.ts)

**Changes:**
- Supports BOTH payment flows
- Validates booking status based on payment method:
  - `online`: Must be in `awaiting_payment`, `pending`, or `approved_by_admin`
  - `after_service`: Must be in `service_completed` or `completed`
- Stores `paymentMethod` in Razorpay order notes

**Usage:**
```javascript
const order = await createPaymentOrder({
  bookingId: 'xxx'
});
// Returns: { orderId, amount, paymentMethod, ... }
```

---

#### C. `razorpayWebhookV2` (razorpayWebhookV2.ts)

**Changes:**
- Reads `paymentMethod` from booking
- Sets booking status based on payment method:
  - `online` → `confirmed` (ready for service)
  - `after_service` → `completed` (service already done)

**Webhook Flow:**
```
1. Razorpay sends payment.captured event
2. Verify signature
3. Check payment method
4. Update booking status accordingly
5. Send notifications
```

---

#### D. `confirmAfterServicePayment` (NEW - after_service_payment.ts)

**Purpose:** Technician confirms payment received manually

**Security:**
- Only technician or admin can confirm
- Validates booking is `service_completed`
- Validates payment method is `after_service`
- Prevents duplicate confirmations

**Usage:**
```javascript
const result = await confirmAfterServicePayment({
  bookingId: 'xxx'
});
```

**What it does:**
1. Validates technician/admin authorization
2. Checks service is completed
3. Marks payment as `paid`
4. Updates booking status to `completed`
5. Logs payment confirmation
6. Sends notification to customer

---

#### E. `startService` (unified_booking_lifecycle.ts)

**Changes:**
- **NEW VALIDATION**: For `online` payment bookings, checks if payment is completed
- Prevents service start if payment is pending for online bookings
- No payment check for `after_service` bookings

**Logic:**
```javascript
if (paymentMethod === 'online') {
  if (paymentStatus !== 'paid') {
    throw Error('Payment must be completed before starting service');
  }
}
// Allow service start
```

---

### 3. Firestore Security Rules

**Updated:**
```javascript
match /bookings/{bookingId} {
  allow create: if isSignedIn()
    && request.resource.data.customerId == request.auth.uid
    && request.resource.data.status in ['pending', 'pending_admin_review', 'awaiting_payment'];
  
  // Payment fields are read-only (Cloud Functions only)
  allow update: if false;
}
```

---

## 📱 FLUTTER CUSTOMER APP INTEGRATION

### 1. Booking Creation Screen

**Add Payment Method Selection:**

```dart
enum PaymentMethod { online, afterService }

class BookingScreen extends StatefulWidget {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.afterService;
  
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Service details...
        
        // Payment Method Selection
        RadioListTile<PaymentMethod>(
          title: Text('Pay Now (Online)'),
          subtitle: Text('Pay before service starts'),
          value: PaymentMethod.online,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() => _selectedPaymentMethod = value!);
          },
        ),
        RadioListTile<PaymentMethod>(
          title: Text('Pay After Service'),
          subtitle: Text('Pay after work is completed'),
          value: PaymentMethod.afterService,
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() => _selectedPaymentMethod = value!);
          },
        ),
        
        ElevatedButton(
          onPressed: _createBooking,
          child: Text(_selectedPaymentMethod == PaymentMethod.online 
            ? 'Proceed to Payment' 
            : 'Create Booking'),
        ),
      ],
    );
  }
  
  Future<void> _createBooking() async {
    final result = await FirebaseFunctions.instance
      .httpsCallable('createBookingRequest')
      .call({
        'serviceId': serviceId,
        'technicianId': technicianId,
        'paymentMethod': _selectedPaymentMethod == PaymentMethod.online 
          ? 'online' 
          : 'after_service',
        // ... other fields
      });
    
    if (_selectedPaymentMethod == PaymentMethod.online) {
      // Proceed to payment
      await _initiatePayment(result.data['bookingId']);
    } else {
      // Show success message
      _showSuccessDialog();
    }
  }
}
```

---

### 2. Payment Flow (Online)

```dart
Future<void> _initiatePayment(String bookingId) async {
  // Step 1: Create Razorpay order
  final orderResult = await FirebaseFunctions.instance
    .httpsCallable('createPaymentOrder')
    .call({'bookingId': bookingId});
  
  final orderId = orderResult.data['orderId'];
  final amount = orderResult.data['amount'];
  
  // Step 2: Open Razorpay checkout
  var options = {
    'key': 'YOUR_RAZORPAY_KEY',
    'amount': (amount * 100).toInt(),
    'order_id': orderId,
    'name': 'HomeFix',
    'description': 'Service Payment',
    'prefill': {
      'contact': userPhone,
      'email': userEmail,
    },
  };
  
  try {
    _razorpay.open(options);
  } catch (e) {
    print('Error: $e');
  }
}

void _handlePaymentSuccess(PaymentSuccessResponse response) {
  // DO NOT mark as success locally
  // Wait for Firestore update from webhook
  _showPaymentProcessingDialog();
  _listenForPaymentConfirmation();
}

void _listenForPaymentConfirmation() {
  FirebaseFirestore.instance
    .collection('bookings')
    .doc(bookingId)
    .snapshots()
    .listen((snapshot) {
      if (snapshot.data()?['paymentStatus'] == 'paid') {
        _showPaymentSuccessDialog();
      }
    });
}
```

---

### 3. Booking Details Screen

**Show Payment Status:**

```dart
Widget _buildPaymentStatus(Booking booking) {
  final paymentMethod = booking.paymentMethod;
  final paymentStatus = booking.payment?.status ?? 'pending';
  
  if (paymentMethod == 'online') {
    if (paymentStatus == 'paid') {
      return StatusChip(
        label: 'Payment Completed',
        color: Colors.green,
      );
    } else if (paymentStatus == 'pending') {
      return Column(
        children: [
          StatusChip(
            label: 'Payment Pending',
            color: Colors.orange,
          ),
          ElevatedButton(
            onPressed: () => _initiatePayment(booking.id),
            child: Text('Pay Now'),
          ),
        ],
      );
    }
  } else {
    // After-service payment
    if (booking.status == 'service_completed') {
      return Column(
        children: [
          Text('Service completed. Please make payment to technician.'),
          Text('Payment Method: Cash/UPI/Card'),
        ],
      );
    } else if (paymentStatus == 'paid') {
      return StatusChip(
        label: 'Payment Confirmed',
        color: Colors.green,
      );
    }
  }
  
  return SizedBox.shrink();
}
```

---

## 📱 FLUTTER TECHNICIAN APP INTEGRATION

### 1. Job Details Screen

**Payment Status Check:**

```dart
Widget _buildJobActions(Booking booking) {
  final paymentMethod = booking.paymentMethod;
  final paymentStatus = booking.payment?.status ?? 'pending';
  final bookingStatus = booking.status;
  
  // Check if can start service
  if (bookingStatus == 'technician_accepted') {
    if (paymentMethod == 'online' && paymentStatus != 'paid') {
      return Card(
        color: Colors.orange[50],
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.payment, size: 48, color: Colors.orange),
              SizedBox(height: 8),
              Text(
                'Waiting for Customer Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Customer must complete online payment before you can start service',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: _startService,
        child: Text('Start Service'),
      );
    }
  }
  
  // After service completion
  if (bookingStatus == 'service_completed') {
    if (paymentMethod == 'after_service' && paymentStatus != 'paid') {
      return Column(
        children: [
          Text(
            'Collect payment from customer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Accept payment via Cash/UPI/Card'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _confirmPaymentReceived,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(
              'Confirm Payment Received',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    } else if (paymentStatus == 'paid') {
      return StatusChip(
        label: 'Payment Confirmed',
        color: Colors.green,
      );
    }
  }
  
  return SizedBox.shrink();
}

Future<void> _confirmPaymentReceived() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Payment'),
      content: Text('Have you received the payment from the customer?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Yes, Confirm'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    try {
      await FirebaseFunctions.instance
        .httpsCallable('confirmAfterServicePayment')
        .call({'bookingId': booking.id});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment confirmed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

---

## 🔒 SECURITY CONSIDERATIONS

### 1. Payment Validation
- ✅ Amount comes ONLY from Firestore (never trust client)
- ✅ Webhook signature verification (prevents fraud)
- ✅ Idempotency protection (prevents duplicate payments)
- ✅ Status validation before payment

### 2. Authorization
- ✅ Only booking owner can create payment order
- ✅ Only assigned technician/admin can confirm after-service payment
- ✅ Cloud Functions enforce all payment updates
- ✅ Firestore rules prevent direct payment field updates

### 3. Status Transitions
- ✅ State machine validates all status changes
- ✅ Payment status checked before service start (online bookings)
- ✅ Service completion required before payment confirmation (after-service)

---

## 📋 TESTING CHECKLIST

### Online Payment Flow
- [ ] Create booking with `paymentMethod: 'online'`
- [ ] Verify booking status is `awaiting_payment`
- [ ] Call `createPaymentOrder` - should succeed
- [ ] Complete Razorpay payment
- [ ] Verify webhook updates booking to `confirmed`
- [ ] Admin approves booking
- [ ] Technician accepts booking
- [ ] Verify technician CAN start service (payment is paid)
- [ ] Complete service
- [ ] Verify booking status is `completed`

### After-Service Payment Flow
- [ ] Create booking with `paymentMethod: 'after_service'`
- [ ] Verify booking status is `pending`
- [ ] Admin approves booking
- [ ] Technician accepts booking
- [ ] Verify technician CAN start service (no payment check)
- [ ] Complete service
- [ ] Verify booking status is `service_completed`
- [ ] Technician calls `confirmAfterServicePayment`
- [ ] Verify booking status is `completed`
- [ ] Verify payment status is `paid`

### Edge Cases
- [ ] Try to start service with pending payment (online) - should FAIL
- [ ] Try to confirm payment before service completion - should FAIL
- [ ] Try to confirm payment for online booking - should FAIL
- [ ] Try duplicate payment confirmation - should FAIL
- [ ] Try unauthorized payment confirmation - should FAIL

---

## 🚀 DEPLOYMENT STEPS

### 1. Deploy Cloud Functions
```bash
cd functions
npm run build
firebase deploy --only functions:createBookingRequest
firebase deploy --only functions:createPaymentOrder
firebase deploy --only functions:confirmAfterServicePayment
firebase deploy --only functions:razorpayWebhookV2
firebase deploy --only functions:startService
```

### 2. Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 3. Set Environment Variables
```bash
firebase functions:config:set \
  razorpay.key_id="YOUR_KEY_ID" \
  razorpay.key_secret="YOUR_KEY_SECRET" \
  razorpay.webhook_secret="YOUR_WEBHOOK_SECRET"
```

### 4. Update Flutter Apps
- Update customer app with payment method selection
- Update technician app with payment confirmation UI
- Test on staging environment
- Deploy to production

---

## 📊 MONITORING & ANALYTICS

### Key Metrics to Track
1. **Payment Method Distribution**
   - % of bookings using online payment
   - % of bookings using after-service payment

2. **Payment Success Rate**
   - Online payment success rate
   - After-service payment confirmation rate

3. **Time to Payment**
   - Average time from booking to payment (online)
   - Average time from service completion to payment confirmation (after-service)

4. **Failed Payments**
   - Track failed online payments
   - Track unconfirmed after-service payments

### Firestore Queries
```javascript
// Get online payment bookings
db.collection('bookings')
  .where('paymentMethod', '==', 'online')
  .where('paymentStatus', '==', 'pending')
  .get();

// Get after-service bookings awaiting payment
db.collection('bookings')
  .where('paymentMethod', '==', 'after_service')
  .where('status', '==', 'service_completed')
  .where('paymentStatus', '==', 'pending')
  .get();
```

---

## 🐛 TROUBLESHOOTING

### Issue: Online payment not updating booking status
**Solution:** Check webhook logs, verify signature, ensure razorpayWebhookV2 is deployed

### Issue: Technician can't start service after payment
**Solution:** Verify payment status is 'paid' in Firestore, check startService function logs

### Issue: After-service payment confirmation fails
**Solution:** Verify service is completed, check technician authorization, review function logs

### Issue: Duplicate payment confirmations
**Solution:** Check idempotency logic, verify transaction handling in confirmAfterServicePayment

---

## 📞 SUPPORT

For issues or questions:
- Check Firebase Functions logs
- Review payment_logs collection
- Contact: 9508322397

---

## 📄 LICENSE

Proprietary - HomeFix © 2026
