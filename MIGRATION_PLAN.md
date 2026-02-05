# 🔥 HomeFix: Firestore-First Migration & Security Hardening Plan 🔥

## 1. ARCHITECTURE DECISION (FINAL)
- **Single Source of Truth**: Firestore.
- **Backend Architecture**: 100% Serverless (Cloud Functions).
- **Removal**: All Express, Prisma, and Neon PostgreSQL components will be purged.

## 2. SAFE CLEANUP
| Component | Action | Reason |
| :--- | :--- | :--- |
| `backend/` | ❌ **DELETE** | Contains compromised service account key and redundant Express logic. |
| `homefix-backend/` | ❌ **DELETE** | Redundant legacy archive. |
| `functions/` | ✅ **KEEP** | This is the new main backend. |
| `apps/` | ✅ **KEEP** | Update to use Firebase SDK and Callables. |

## 3. FIRESTORE DATA MODEL
### Collections & Fields
- **/customers/{uid}**
  - `displayName`, `email`, `phone`, `fcmToken`, `address[]`, `createdAt`
- **/technicians/{uid}**
  - `displayName`, `email`, `phone`, `fcmToken`, `isOnline`, `isVerified`, `kycStatus`, `skills[]`, `ratingAvg`, `jobsDone`, `lastLocation` (GeoPoint), `walletBalance`
- **/bookings/{bookingId}**
  - `customerId`, `technicianId`, `serviceId`, `scheduledAt`, `status` (pending/confirmed/started/completed/cancelled), `price`, `paymentId`, `address`
- **/services/{serviceId}**
  - `title`, `description`, `price`, `category`, `imageUrl`
- **/payments/{paymentId}**
  - `amount`, `status`, `provider` (Razorpay), `bookingId`, `customerId`, `metadata`
- **/reviews/{reviewId}**
  - `bookingId`, `technicianId`, `customerId`, `rating`, `comment`
- **/wallets/{uid}** (Private)
  - `balance`, `lastTransactionId`, `updatedAt`
- **/notifications/{id}**
  - `targetUid`, `title`, `body`, `read`, `createdAt`
- **/admins/{uid}**
  - `role` (superadmin, support, finance), `permissions[]`

## 4. CLOUD FUNCTIONS DESIGN
### Callable Functions (Client Side)
- `createBooking`: Validates slot, creates booking doc, returns Razorpay order.
- `assignTechnician`: (Admin only) Assigns a technician to a pending booking.
- `cancelBooking`: Handles refund logic and status update.
- `verifyPayment`: Validates Razorpay signature and updates booking.
- `submitReview`: Updates technician's `ratingAvg` and `jobsDone`.
- `updateTechnicianAvailability`: Updates online status and location.
- `getNearbyTechnicians`: Uses GeoQuery to find available techs.

### Triggers (Server Side)
- `onBookingCreated`: Sends FCM to admins.
- `onBookingStatusChange`: Sends FCM to customer/technician.
- `onPaymentSuccess`: Updates wallet if applicable and confirms booking.
- `onBookingCompleted`: Triggers invoice generation.
- `scheduledDailyReports`: CRON job for daily revenue summaries.

## 5. SECURITY HARDENING
1. **Rotate Service Account**: **DANGEROUS** key in `.env` must be revoked in Google Cloud Console.
2. **Environment Config**: Use `firebase functions:config:set` or `.env.local` for local emulators.
3. **App Check**: Mandatory for all production calls to prevent API abuse.
4. **Rate Limiting**: Implementation of a `rate-limiter` within Cloud Functions using a collection or Redis (Upstash).
5. **Private Data**: Wallets and Admin-only data protected via Rules.

## 6. FIRESTORE RULES (Preview)
- `match /wallets/{uid} { allow read: if request.auth.uid == uid; allow write: if false; }`
- `match /bookings/{id} { allow read: if request.auth != null; allow write: if false; }` (Created via Functions Only)

## 7. FLUTTER APP CHANGES
- **Remove**: `http` / `dio` calls to `localhost:5000`.
- **Replace**: Use `cloud_functions` Flutter plugin for `httpsCallable`.
- **Inject**: Firebase App Check initialization.

## 8. ADMIN PANEL CHANGES
- **Replace**: Axios calls with `firebase-functions/callable`.
- **Verify**: `isAdmin` role check inside Functions via `context.auth.token.role`.

## 9. PRODUCTION CHECKLIST
- [ ] Enforce App Check.
- [ ] Set Cloud Function memory/timeout limits.
- [ ] Configure Firestore TTL for temporary logs.
- [ ] Enable Google Cloud Monitoring.
- [ ] Set up daily Firestore exports to Storage.
