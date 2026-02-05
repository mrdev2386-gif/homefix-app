# FINAL PRODUCTION CHECKLIST & RUN GUIDE

## 1. Environment Setup
Run these commands once to configure the backend:
```bash
# Set Razorpay Keys (Get these from Razorpay Dashboard)
firebase functions:config:set razorpay.key_id="rzp_test_YOUR_ID" razorpay.key_secret="YOUR_SECRET"

# Deploy Security Rules & Functions
firebase deploy --only functions,firestore:rules
```

## 2. Seed Database (One-time)
Since we have strict Admin rules, you must:
1.  Manually create an Admin document in Firestore for your UID if not exists: `admins/{YOUR_UID}` with `{role: 'super_admin'}`.
2.  Use the Admin Panel or a quick script to call `seedDatabase`.
    *   *Quick Method*: Open Postman/Curl or a temporary Function call loop if you know how.
    *   *Easier*: Just run the Admin Panel, look for a "Seed DB" button (if implemented) or manually create 1 service to test.
    *   *Note*: The `seedDatabase` cloud function is deployed. You can call it from the app if you temporarily add a button for it in `AdminPanel`.

## 3. Technician Flow (Demo)
1.  **Launch**: `cd apps/technician_app && flutter run`
2.  **Signup**: Login with Phone.
3.  **KYC**: Upload dummy images. You will be stuck at "Verification Pending".
4.  **Admin Approval**:
    *   Go to Firestore Console > `technician_kyc` > `{uid}`.
    *   Change status to `approved`.
    *   Or use Admin Panel (`cd apps/admin_panel && npm run dev`).
5.  **Availability**:
    *   In App, "Generate Weekly Slots".
    *   Toggle "Online".

## 4. Customer Flow (Demo)
1.  **Launch**: `cd apps/customer_app && flutter run`
2.  **Home**: Verify Services (AC, Cleaning, etc.) are visible (loaded from Firestore).
3.  **Booking**:
    *   Select "AC Service".
    *   Select a Technician (ensure Tech is Online & has Slots).
    *   Select Date/Time.
    *   **Coupon**: Enter "NEW50".
    *   **Pay**: Click "Pay & Confirm".
    *   (Razorpay Test Mode should open).
4.  **Success**:
    *   Verify "Booking Confirmed" toast.
    *   Check Firestore: `bookings/{id}` status is `confirmed`.

## 5. End-to-End
1.  **Technician Notification**: Tech should see "New Job Assigned" notification (if running).
2.  **Tech Dashboard**: Refresh. See "My Active Jobs".
3.  **Job Flow**:
    *   Change status: `Accepted` -> `On The Way` -> `Started` -> `Completed`.
4.  **Invoice**:
    *   Customer App > Bookings > Details > "Download Invoice".
    *   Verify PDF URL is generated.

## Troubleshooting
*   **Permissions Error**: Check `firestore.rules`.
*   **Razorpay Error**: Check cloud function logs for `api.razorpay.com` errors (usually bad keys).
*   **No Technicians**: Ensure Tech is `isOnline: true`, `isVerified: true`, has the right `skill` (e.g., 'ac_service'), and has `slots` for the selected date.

## Production Readiness
*   [x] Transactional Booking (No double booking)
*   [x] Server-side Payment Verification
*   [x] Secure Firestore Rules (No client writes to sensitive paths)
*   [x] Real-time Location Tracking
*   [x] Notifications (FCM)
