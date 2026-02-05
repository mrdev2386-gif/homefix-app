# HomeFix - Quick Start Guide

## 🚀 IMMEDIATE ACTIONS REQUIRED

### 1. Fix Phone Auth & Google Login (5 minutes)

#### Register SHA Keys in Firebase Console

```bash
# Navigate to customer app android folder
cd apps/customer_app/android

# Generate SHA keys
./gradlew signingReport

# Look for output like:
# SHA1: DF:9A:BB:F2:06:71:77:DE:95:BC:75:8D:85:AC:1F:28:60:7F:C8:CF
# SHA-256: ...
```

**Copy both SHA-1 and SHA-256**, then:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **homefix-aa42d** project
3. Click **Project Settings** (gear icon)
4. Scroll to **Your apps** → Select Android app
5. Click **Add fingerprint**
6. Paste **SHA-1**
7. Click **Add fingerprint** again
8. Paste **SHA-256**
9. Click **Download google-services.json**
10. Replace `apps/customer_app/android/app/google-services.json`

**This fixes:**
- ✅ Phone OTP verification
- ✅ Google Sign-In

---

### 2. Deploy Cloud Functions (5 minutes)

```bash
# Install dependencies
cd functions
npm install

# Build TypeScript
npm run build

# Deploy to Firebase
firebase deploy --only functions

# Expected output:
# ✔ functions[createBooking] Successful update operation.
# ✔ functions[verifyPayment] Successful update operation.
# ✔ functions[admin_getDashboardStats] Successful update operation.
# ... etc
```

---

### 3. Deploy Firestore Rules (1 minute)

```bash
# From project root
firebase deploy --only firestore:rules

# Expected output:
# ✔ firestore: rules file firestore.rules compiled successfully
```

---

### 4. Configure Razorpay (2 minutes)

```bash
# Set Razorpay test keys
firebase functions:config:set razorpay.key_id="rzp_test_YOUR_KEY_ID"
firebase functions:config:set razorpay.key_secret="YOUR_KEY_SECRET"

# Redeploy functions to apply config
firebase deploy --only functions
```

**Get test keys from:** https://dashboard.razorpay.com/app/keys

---

### 5. Test Customer App (10 minutes)

```bash
cd apps/customer_app

# Get dependencies
flutter pub get

# Run on emulator/device
flutter run --debug

# Test checklist:
# □ Phone login with OTP
# □ Google Sign-In
# □ Browse services
# □ Create booking
# □ Make payment
```

---

### 6. Setup Admin Panel (5 minutes)

```bash
cd apps/admin_panel

# Install dependencies
npm install

# Create .env.local file
cat > .env.local << EOF
NEXT_PUBLIC_FIREBASE_API_KEY=AIzaSyADfM4cMfTlz3Cth0QwalYntQv3AoU9daI
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=homefix-aa42d.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=homefix-aa42d
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=homefix-aa42d.firebasestorage.app
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=663243229047
NEXT_PUBLIC_FIREBASE_APP_ID=1:663243229047:web:generic_web_id
EOF

# Run development server
npm run dev

# Open http://localhost:3000
```

**Create Admin User in Firestore:**
1. Go to Firebase Console → Firestore
2. Create collection: `admins`
3. Add document with your user UID as document ID
4. Add field: `email: "your@email.com"`
5. Add field: `role: "super_admin"`

---

## 🧪 TESTING SEQUENCE

### Test 1: Phone Authentication

1. Open customer app
2. Enter phone number: `+91 9876543210`
3. Click "Continue"
4. **Expected:** OTP screen appears
5. Enter OTP from SMS
6. **Expected:** Dashboard loads

**If OTP fails:**
- ✅ Check SHA keys are registered
- ✅ Check App Check is enabled in Firebase Console
- ✅ Try on real device (not emulator)

---

### Test 2: Google Sign-In

1. Open customer app
2. Click "Continue with Google"
3. Select Google account
4. **Expected:** Dashboard loads immediately

**If Google login fails:**
- ✅ Check SHA keys are registered
- ✅ Check OAuth client ID in google-services.json
- ✅ Check Google Sign-In is enabled in Firebase Console

---

### Test 3: Booking Flow

1. Login to customer app
2. Browse services
3. Select a service
4. Choose date & time
5. Click "Book Now"
6. **Expected:** Payment screen appears
7. Complete Razorpay payment
8. **Expected:** Booking confirmed

**Check in Firestore:**
- Collection: `bookings`
- Status should be: `confirmed`
- Payment status: `paid`

---

### Test 4: Admin Dashboard

1. Open admin panel: http://localhost:3000
2. Login with admin email
3. **Expected:** Dashboard with stats
4. Navigate to "Customers"
5. **Expected:** List of customers
6. Try blocking a user
7. **Expected:** User status changes to "Blocked"

---

## 🐛 TROUBLESHOOTING

### Phone OTP Not Working

**Symptom:** "Invalid OTP" error

**Solutions:**
1. Check SHA keys registered in Firebase Console
2. Enable App Check in Firebase Console
3. For emulator: Use debug provider
4. For real device: Use Play Integrity
5. Check phone number format: `+91XXXXXXXXXX`

---

### Google Sign-In Crashes

**Symptom:** App crashes after selecting Google account

**Solutions:**
1. Register SHA-1 and SHA-256 in Firebase Console
2. Download new `google-services.json`
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

### Cloud Functions Not Working

**Symptom:** "Function not found" error

**Solutions:**
1. Check functions are deployed:
   ```bash
   firebase functions:list
   ```
2. Check function logs:
   ```bash
   firebase functions:log
   ```
3. Redeploy:
   ```bash
   firebase deploy --only functions
   ```

---

### Admin Dashboard Not Loading Data

**Symptom:** Dashboard shows "Loading..." forever

**Solutions:**
1. Check admin user exists in Firestore `admins` collection
2. Check Cloud Function `admin_getDashboardStats` is deployed
3. Check browser console for errors
4. Verify Firebase config in `.env.local`

---

## 📞 SUPPORT COMMANDS

### View Firebase Logs
```bash
# Cloud Functions logs
firebase functions:log --limit 50

# Firestore operations
firebase firestore:indexes
```

### Check Deployment Status
```bash
# List deployed functions
firebase functions:list

# Check Firestore rules
firebase firestore:rules get
```

### Debug Flutter App
```bash
# Run with verbose logging
flutter run --verbose

# Check for issues
flutter doctor -v
```

---

## ✅ SUCCESS INDICATORS

You'll know everything is working when:

1. **Phone OTP:** ✅ OTP received and verified successfully
2. **Google Login:** ✅ Seamless login without crashes
3. **Booking:** ✅ Payment completes and booking shows in Firestore
4. **Admin Dashboard:** ✅ Real-time stats display correctly
5. **User Management:** ✅ Block/unblock actions work
6. **Refunds:** ✅ Admin can refund bookings

---

## 🎯 NEXT STEPS AFTER TESTING

1. **Setup Technician App**
   - Copy `google-services.json` to technician app
   - Implement auth flow
   - Test technician login

2. **Production Deployment**
   - Build release APKs
   - Deploy admin panel to Vercel/Netlify
   - Configure production Razorpay keys
   - Enable production App Check

3. **Monitoring**
   - Setup Firebase Analytics
   - Configure Crashlytics
   - Setup alerting for errors

---

**Total Setup Time:** ~30 minutes  
**Testing Time:** ~30 minutes  
**Total:** ~1 hour to fully working system

Good luck! 🚀
