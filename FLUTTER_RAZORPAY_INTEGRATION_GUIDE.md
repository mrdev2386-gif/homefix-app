# FLUTTER APPS - RAZORPAY INTEGRATION GUIDE

## 🎯 OVERVIEW

The Razorpay integration is now consolidated with:
- ✅ **Single source of truth** for each function
- ✅ **Firebase Functions config** for secrets (no frontend exposure)
- ✅ **Backward compatible** function names
- ✅ **Production-grade security**

---

## 📱 CUSTOMER APP INTEGRATION

### **FUNCTION NAMES (NO CHANGES)**
```dart
// These function names remain the same
initiateRazorpayPayment  // Create order
verifyRazorpayPayment    // Verify payment
```

### **FLOW: Create Booking → Pay → Verify**

#### **STEP 1: Create Order**
```dart
// Call Firebase function to create Razorpay order
final result = await FirebaseFunctions.instance
    .httpsCallable('initiateRazorpayPayment')
    .call({
      'bookingId': bookingId,
      // DO NOT send amount - backend calculates from Firestore
    });

// Response structure
final orderId = result.data['orderId'];
final amount = result.data['amount'];
final keyId = result.data['keyId'];  // ✅ Use this, NOT hardcoded key
```

#### **STEP 2: Open Razorpay Checkout**
```dart
// IMPORTANT: Use keyId from backend response
final options = {
  'key': keyId,  // ✅ From backend, NOT hardcoded
  'order_id': orderId,
  'amount': (amount * 100).toInt(),  // Convert to paise
  'currency': 'INR',
  'name': 'HomeFix',
  'description': 'Service Booking',
  'prefill': {
    'contact': userPhone,
    'email': userEmail,
  },
  'theme': {
    'color': '#3399cc',
  },
};

// Open Razorpay checkout
_razorpay.open(options);
```

#### **STEP 3: Handle Success**
```dart
void _handlePaymentSuccess(PaymentSuccessResponse response) {
  // DO NOT trust frontend success
  // Always verify on backend
  
  _verifyPaymentOnBackend(
    orderId: response.orderId,
    paymentId: response.paymentId,
    signature: response.signature,
  );
}

Future<void> _verifyPaymentOnBackend({
  required String orderId,
  required String paymentId,
  required String signature,
}) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('verifyRazorpayPayment')
        .call({
          'bookingId': bookingId,
          'razorpayOrderId': orderId,
          'razorpayPaymentId': paymentId,
          'razorpaySignature': signature,
        });

    if (result.data['success']) {
      // ✅ Payment verified by backend
      // Booking status updated in Firestore
      showSuccessMessage('Payment successful!');
      navigateToBookingDetails();
    }
  } catch (e) {
    // ❌ Payment verification failed
    showErrorMessage('Payment verification failed: $e');
  }
}
```

#### **STEP 4: Handle Failure**
```dart
void _handlePaymentError(PaymentFailureResponse response) {
  // Payment failed on Razorpay side
  // Booking remains unpaid
  
  showErrorMessage(
    'Payment failed: ${response.message}',
  );
  
  // User can retry by calling initiateRazorpayPayment again
}
```

---

## 👨‍🔧 TECHNICIAN APP INTEGRATION

### **FUNCTION NAME (NO CHANGES)**
```dart
createRazorpayOrder  // Create order for wallet credit
```

### **FLOW: Add Money to Wallet**

#### **STEP 1: Create Order**
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('createRazorpayOrder')
    .call({
      'amount': 500,  // ₹500
      'notes': 'Wallet credit',
    });

final orderId = result.data['orderId'];
final amount = result.data['amount'];
final keyId = result.data['keyId'];  // ✅ Use this
```

#### **STEP 2: Open Checkout**
```dart
final options = {
  'key': keyId,  // ✅ From backend
  'order_id': orderId,
  'amount': (amount * 100).toInt(),
  'currency': 'INR',
  'name': 'HomeFix',
  'description': 'Wallet Credit',
  'prefill': {
    'contact': technicianPhone,
    'email': technicianEmail,
  },
};

_razorpay.open(options);
```

#### **STEP 3: Webhook Handles Verification**
```dart
// ✅ NO NEED TO VERIFY ON CLIENT
// Webhook automatically processes payment
// Wallet is credited by backend

void _handlePaymentSuccess(PaymentSuccessResponse response) {
  // Just show success message
  // Backend webhook will update wallet
  showSuccessMessage('Payment successful! Wallet will be credited shortly.');
  
  // Optionally refresh wallet balance after a delay
  Future.delayed(Duration(seconds: 2), () {
    refreshWalletBalance();
  });
}
```

---

## 🔒 SECURITY BEST PRACTICES

### **DO ✅**
- ✅ Always use `keyId` from backend response
- ✅ Always verify payment on backend
- ✅ Never hardcode Razorpay key in frontend
- ✅ Never trust frontend payment success
- ✅ Always handle payment failures gracefully
- ✅ Store booking ID before opening checkout

### **DON'T ❌**
- ❌ Never hardcode Razorpay key: `'key': 'rzp_test_xxx'`
- ❌ Never send amount from frontend
- ❌ Never trust Razorpay success callback alone
- ❌ Never skip backend verification
- ❌ Never expose secrets in frontend code
- ❌ Never calculate amount on frontend

---

## 📋 IMPLEMENTATION CHECKLIST

### **Customer App**
- [ ] Import Firebase Functions
- [ ] Initialize Razorpay SDK
- [ ] Call `initiateRazorpayPayment` to create order
- [ ] Use `keyId` from response (not hardcoded)
- [ ] Open Razorpay checkout with response data
- [ ] On success: Call `verifyRazorpayPayment`
- [ ] On failure: Show error and allow retry
- [ ] Listen to Firestore for booking status updates

### **Technician App**
- [ ] Import Firebase Functions
- [ ] Initialize Razorpay SDK
- [ ] Call `createRazorpayOrder` with amount
- [ ] Use `keyId` from response (not hardcoded)
- [ ] Open Razorpay checkout with response data
- [ ] On success: Show message and refresh wallet
- [ ] On failure: Show error and allow retry
- [ ] Listen to Firestore for wallet updates

---

## 🧪 TESTING FLOW

### **Test 1: Successful Payment (Customer)**
1. Create booking
2. Click "Pay Now"
3. Call `initiateRazorpayPayment`
4. Open Razorpay checkout
5. Use test card: `4111 1111 1111 1111`
6. Complete payment
7. Call `verifyRazorpayPayment`
8. Verify booking status changes to "confirmed"
9. Check Firestore: `bookings/{bookingId}.payment.status` = "paid"

### **Test 2: Failed Payment (Customer)**
1. Create booking
2. Click "Pay Now"
3. Call `initiateRazorpayPayment`
4. Open Razorpay checkout
5. Use test card: `4000 0000 0000 0002` (fails)
6. Payment fails
7. Show error message
8. Verify booking status remains "awaiting_payment"
9. User can retry

### **Test 3: Wallet Credit (Technician)**
1. Click "Add Money"
2. Enter amount (₹500)
3. Call `createRazorpayOrder`
4. Open Razorpay checkout
5. Complete payment
6. Webhook processes payment
7. Verify wallet balance increases in Firestore
8. Check `technician_wallets/{techId}.availableBalance`

### **Test 4: Duplicate Payment Prevention**
1. Create booking
2. Call `initiateRazorpayPayment` → Get orderId
3. Call again → Should return same orderId
4. Verify no duplicate orders created

---

## 🐛 TROUBLESHOOTING

### **Issue: "Razorpay configuration not found"**
**Solution:**
```bash
firebase functions:config:set razorpay.key_id="xxx"
firebase functions:config:set razorpay.key_secret="xxx"
firebase functions:config:set razorpay.webhook_secret="xxx"
firebase deploy --only functions
```

### **Issue: "keyId is undefined"**
**Solution:**
- Ensure backend response includes `keyId`
- Check Firebase Functions logs: `firebase functions:log`
- Verify configuration is set

### **Issue: "Payment verified but booking not updated"**
**Solution:**
- Check Firestore rules allow updates
- Verify booking exists
- Check Firebase Functions logs for errors
- Ensure user is booking owner

### **Issue: "Webhook not processing payment"**
**Solution:**
- Verify webhook URL in Razorpay dashboard
- Check webhook secret is correct
- Monitor Firebase Functions logs
- Test webhook manually from Razorpay dashboard

---

## 📊 FUNCTION REFERENCE

### **Customer App Functions**

#### `initiateRazorpayPayment`
```dart
// Input
{
  'bookingId': 'booking_123'
}

// Output
{
  'success': true,
  'orderId': 'order_xyz',
  'amount': 500,
  'currency': 'INR',
  'keyId': 'rzp_test_xxx',
  'bookingNumber': 'BK-2026-0001',
  'customerName': 'John Doe',
  'customerEmail': 'john@example.com',
  'customerPhone': '9876543210',
  'paymentMethod': 'online'
}
```

#### `verifyRazorpayPayment`
```dart
// Input
{
  'bookingId': 'booking_123',
  'razorpayOrderId': 'order_xyz',
  'razorpayPaymentId': 'pay_abc',
  'razorpaySignature': 'signature_hash'
}

// Output
{
  'success': true,
  'message': 'Payment verified successfully'
}
```

### **Technician App Functions**

#### `createRazorpayOrder`
```dart
// Input
{
  'amount': 500,
  'notes': 'Wallet credit'
}

// Output
{
  'success': true,
  'orderId': 'order_xyz',
  'amount': 500,
  'currency': 'INR'
}
```

---

## 🎉 RESULT

✅ **Secure, production-ready Razorpay integration**
- No secrets in frontend
- Backend verification required
- Webhook handles async payments
- Backward compatible with existing apps

**Ready for production deployment!**