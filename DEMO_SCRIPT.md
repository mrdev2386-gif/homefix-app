# DEMO SCRIPT - PRODUCTION V4

Follow this updated script to verify the Production V4 status. All core features (Ranking, Booking Rules, Admin Analytics) are now active.

## Phase 1: Preparation
1.  **Backend Deploy**:
    ```bash
    firebase deploy --only functions,firestore:rules
    ```
2.  **Admin Seed**:
    - Open Admin Panel (`apps/admin_panel` -> `npm run dev`).
    - Login as Admin.
    - If you haven't seeded services yet, find the "Seed DB" button or call the function manually. (Or trust the existing data if present).

## Phase 2: Technician Setup ("Expert Supply")
1.  **Technician Signup**:
    - Run `flutter run` in `apps/technician_app`.
    - Login.
    - Complete KYC (Upload dummy photos).
2.  **Admin Verify**:
    - Go to Admin Panel -> **Technicians**.
    - Find the new technician.
    - Click **"Approve"**.
    - Verify status changes to "Verified".
3.  **Technician Online**:
    - In App, go to Dashboard.
    - **Generate Weekly Slots** (Availability).
    - Toggle **"Online"** switch.
    - Keep app open (background) to allow location updates (every 2 mins) or manually trigger one update.

## Phase 3: Customer Booking ("The Demand")
1.  **Customer Launch**:
    - Run `flutter run` in `apps/customer_app`.
2.  **Service Discovery (Ranking Test)**:
    - Click on "AC Service".
    - You should see the **Technicians List**.
    - **Verify Ranking**:
        - Does your verified technician appear?
        - If multiple, are they sorted by score?
        - Check tags like "Fast Arrival" (if location is close) or "Top Rated".
3.  **Booking Flow**:
    - Select the Verified Technician.
    - Choose Date & Time.
    - **Apply Coupon**: Try "NEW50" (if seeded) -> Check discount.
    - **Pay**: Click "Proceed to Payment" -> "Confirm".
    - **Razorpay**: Complete test payment.
4.  **Confirmation**:
    - Verify redirection to Success screen.
    - Verify Booking Status is `confirmed` in Firestore.

## Phase 4: Fulfillment & Analytics
1.  **Technician Action**:
    - Check "My Active Jobs" in Tech App.
    - Update Status: `Accepted` -> `On The Way` -> `Started`.
2.  **Admin Dashboard**:
    - Refresh Admin Dashboard.
    - **Verify Analytics**:
        - "Bookings Today" should increment.
        - "Revenue Today" should increase.
3.  **Completion**:
    - Technician marks `Completed`.
4.  **Customer Review**:
    - Customer checks "Bookings" -> Details.
    - Verify **Invoice Download** button works (returns mock URL currently).

## Phase 5: Activity Logs
1.  **Check Firestore**:
    - Open Firebase Console.
    - Collection: `activity_logs`.
    - Verify diverse logs:
        - `customer` -> `booking_created`
        - `technician` -> `status_update`
        - `technician` -> `job_completed`

## Production V4 Checklist
- [x] Ranking Algorithm (Server-side)
- [x] Secured Transactional Booking
- [x] Admin Analytics Dashboard
- [x] Activity Logging
- [x] Full End-to-End Flow
