# Smart Technician Matching V2 - Deployment & Rollout Guide

## 1. Overview
The Smart Technician Matching V2 system replaces the legacy assignment logic with a scoring-based, deterministic algorithm. It runs on Firebase Cloud Functions and uses Firestore transactions for data integrity.

## 2. Configuration & Feature Flags

### Environment Variables
Ensure the following Firebase config variables are set:
```bash
firebase functions:config:set matching.radius_km="15"
firebase functions:config:set matching.max_candidates="10"
firebase functions:config:set matching.assignment_timeout_sec="60"
firebase functions:config:set matching.heartbeat_expiry_min="10"
```

### Feature Flag
We use a logical feature flag to control the rollout. Currently, the code directly calls `matchAndAssignBooking` in the unified `index.ts`. To enable a soft rollout or A/B testing, you can modify `index.ts` to check a remote config or database flag before deciding which logic to use (V1 vs V2).
*Currently, V2 is the default implementation in this deployment.*

## 3. Deployment Steps

1.  **Deploy Cloud Functions**
    ```bash
    firebase deploy --only functions
    ```
    *Note: This will deploy the new `assignTechnicianToBooking` and `respondToAssignment` callables, and update `updateBookingStatus` and `verifyRazorpayPayment`.*

2.  **Verify Indexes**
    Check the Firestore Console for any missing index warnings. The queries used are:
    - `technicians`: `status == 'approved'`, `isAvailable == true`, `currentLocation` (GeoHash)
    - `bookings`: `status`, `createdAt`

3.  **Admin Panel Update**
    Ensure the Admin Panel is updated to use the new `assignTechnicianToBooking` callable for manual overrides instead of direct DB updates if applicable.

## 4. Monitoring & Observability

### Logs
The system emits structured JSON logs. Filter logs in Google Cloud Console / Firebase Console with:
`jsonPayload.event_type = "assignment_attempt"`

Key fields to monitor:
- `bookingId`
- `candidates_found` (Count of eligible techs)
- `top_candidate_score`
- `status` (`success`, `no_candidates`, `error`)

### Metrics (KPIs)
Track these metrics via Log Analytics or custom dashboard:
- **Assignment Success Rate:** `assignment_success_count / total_booking_count`
- **Rejection Rate:** `assignment_rejected_count / assignment_attempt_count`
- **Time to Assign:** Time from `pending_payment` -> `assigned`

## 5. Rollback Procedure

If critical issues arise (e.g., no technicians matching, widespread errors):

1.  **Immediate Revert:**
    Redeploy the previous version of `functions/src/index.ts` from git history.
    ```bash
    git checkout <previous-commit-hash> functions/src/index.ts
    firebase deploy --only functions
    ```

2.  **Emergency Manual Assignment:**
    Admins can manually update the `assignedTechnicianId` and `status: 'assigned'` in the Firestore `bookings` collection via the Firebase Console or Admin Panel as a fallback.

## 6. Testing Strategy

- **Unit Tests:** Run `npm test` in the functions directory to verify scoring logic.
- **Integration Test:** Use `functions/src/testing.ts` tools (e.g., `test_generateBooking`) to simulate a booking flow and observe the matching logs.
