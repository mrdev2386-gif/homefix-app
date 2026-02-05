# IMPLEMENTATION_V3_CHECKLIST

## Pre-Requisites
1.  **Environment**: Ensure Firebase CLI is installed and logged in.
2.  **Flutter**: Ensure Flutter SDK 3.x is active.
3.  **Deploy**:
    ```bash
    firebase deploy --only functions,firestore:rules
    ```
4.  **Config**:
    Set Razorpay secrets (mandatory for functions to work):
    ```bash
    firebase functions:config:set razorpay.key_id="rzp_test_..." razorpay.key_secret="secret_..."
    ```

## 1. Technician Flow (Verification)
1.  **Signup/Login**: Open Technician App. Sign in with Phone/Google.
2.  **KYC Lock**: Verify Dashboard is blocked by `KycStatusScreen`.
3.  **Submission**: Upload dummy Aadhar/Selfie images.
4.  **Admin Approval**:
    *   Open Admin Panel (`npm run dev`).
    *   Navigate to `/technicians`.
    *   Approved the request.
5.  **Dashboard Access**: Verify Technician App now shows Dashboard.
6.  **Availability**:
    *   Go to Calendar (Availability).
    *   Click "Generate Weekly Slots".
    *   Verify slots created in Firestore `availability/{uid}/slots`.
7.  **Online Status**: Toggle "Online". Verify `technicians/{uid}` updates `isOnline: true` and `geo`.

## 2. Customer Flow (Booking)
1.  **Login**: Customer App. Login.
2.  **Discovery**: Select Service (e.g., "Plumbing").
3.  **Slot Selection**:
    *   Verify logic filters ONLY technicians who are verified + online + have skill + have slot.
    *   Select a time.
4.  **Booking**:
    *   Click "Confirm".
    *   **CRITICAL**: Verify `createBooking` Cloud Function is called.
    *   Verify Razorpay UI opens.
5.  **Payment**:
    *   Complete dummy payment.
    *   **CRITICAL**: Verify `verifyRazorpayPayment` is called.
    *   Verify Booking status becomes `confirmed` (Firestore).
    *   Verify Slot `isAvailable` remains `false` (locked).

## 3. Operations & Completion
1.  **Technician Dashboard**:
    *   Refresh. See "New Opportunities".
    *   Accept Booking. Status -> `accepted`.
2.  **Status Flow**:
    *   Change to `on_the_way` -> `started` -> `completed`.
    *   Verify Firestore updates.
3.  **Invoicing**:
    *   On `completed`, check Firestore `invoices` collection.
    *   Customer App: Go to "My Bookings" -> Details.
    *   Click "Download Invoice". Verify PDF link.
4.  **Rewards**:
    *   Check `customers/{uid}/wallet_transactions` for referral credit (if applicable).

## 4. Security Audit
1.  **Client Write Test**:
    *   Try to manually edit `walletBalance` in Firestore Console as a user (Simulator).
    *   MUST FAIL.
2.  **Booking Hack**:
    *   Try to update booking status directly from client code (if possible to test).
    *   MUST FAIL (Rules block it, Logic in Function).

## 5. Admin Panel
1.  **Access**: Login with non-admin email. Verify "Permission Denied".
2.  **Disputes**: Raise dispute in Customer App. Admin Panel -> Disputes -> Verify visibility.

## Final Sign-off
[] All Cloud Functions Deployed & Healthy
[] Firestore Rules Active
[] Apps Build without Errors
