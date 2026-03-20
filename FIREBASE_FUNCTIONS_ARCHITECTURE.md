# 🏗️ Firebase Functions Global Instance - Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Firebase Initialization                        │ │
│  │  (main.dart - runs FIRST)                                  │ │
│  │                                                             │ │
│  │  1. Firebase.initializeApp()                               │ │
│  │  2. FirebaseAuth initialized                               │ │
│  │  3. App starts                                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            │                                      │
│                            ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │       FirebaseFunctionsInstance (SINGLETON)                │ │
│  │       core/firebase/firebase_functions_instance.dart       │ │
│  │                                                             │ │
│  │  static FirebaseFunctions? _instance                       │ │
│  │  static bool _authReady = false                            │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ get instance                                          │ │ │
│  │  │   _instance ??= FirebaseFunctions.instanceFor(       │ │ │
│  │  │     region: 'us-central1'                            │ │ │
│  │  │   )                                                   │ │ │
│  │  │   return _instance!                                   │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │ ensureAuthReady()                                     │ │ │
│  │  │   if (_authReady) return                             │ │ │
│  │  │   await authStateChanges().first                     │ │ │
│  │  │   await delay(500ms)                                 │ │ │
│  │  │   _authReady = true                                  │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            │                                      │
│                            ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Service Layer                            │ │
│  │                                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │ Functions    │  │ Booking      │  │ Auth         │    │ │
│  │  │ Service      │  │ Service      │  │ Service      │    │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │ │
│  │         │                  │                  │            │ │
│  │         └──────────────────┴──────────────────┘            │ │
│  │                            │                                │ │
│  │                            ▼                                │ │
│  │         FirebaseFunctions get _functions =>                │ │
│  │           FirebaseFunctionsInstance.instance               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            │                                      │
│                            ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  Function Call Flow                         │ │
│  │                                                             │ │
│  │  1. await FirebaseFunctionsInstance.ensureAuthReady()     │ │
│  │     ├─ Wait for auth state                                │ │
│  │     └─ Add 500ms delay                                    │ │
│  │                                                             │ │
│  │  2. Check user logged in                                  │ │
│  │     └─ FirebaseAuth.instance.currentUser                  │ │
│  │                                                             │ │
│  │  3. Refresh auth token                                    │ │
│  │     └─ await user.getIdToken(true)                        │ │
│  │                                                             │ │
│  │  4. Call function                                         │ │
│  │     └─ _functions.httpsCallable('name').call(data)        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                            │                                      │
└────────────────────────────┼──────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Firebase Backend                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Cloud Functions (us-central1)                  │ │
│  │                                                             │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │ │
│  │  │ createBooking│  │ updateProfile│  │ cancelBooking│    │ │
│  │  │ Request      │  │              │  │              │    │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘    │ │
│  │                                                             │ │
│  │  Auth Token Verification ✅                                │ │
│  │  Request Processing                                        │ │
│  │  Response Generation                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Request Flow Diagram

```
User Action
    │
    ▼
┌─────────────────────────────────────────┐
│ UI Layer (Screen/Widget)                │
│ - Button pressed                        │
│ - Form submitted                        │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Service Layer                           │
│ - FunctionsService                      │
│ - BookingService                        │
│ - AuthService                           │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 1: Ensure Auth Ready               │
│ await FirebaseFunctionsInstance         │
│   .ensureAuthReady()                    │
│                                         │
│ ├─ Check if already ready               │
│ ├─ Wait for auth state                  │
│ └─ Add 500ms delay                      │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 2: Verify User                     │
│ final user = FirebaseAuth.instance      │
│   .currentUser                          │
│                                         │
│ if (user == null) throw Exception       │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 3: Refresh Token                   │
│ await user.getIdToken(true)             │
│                                         │
│ ├─ Force refresh                        │
│ └─ Get latest token                     │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 4: Debug Logging                   │
│ debugPrint('[AUTH] UID: ${user.uid}')   │
│ debugPrint('[AUTH] Token: $token')      │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 5: Get Global Instance             │
│ final functions =                       │
│   FirebaseFunctionsInstance.instance    │
│                                         │
│ ├─ Returns singleton                    │
│ └─ Region: us-central1                  │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 6: Create Callable                 │
│ final callable =                        │
│   functions.httpsCallable('name')       │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Step 7: Call Function                   │
│ final result = await callable.call(data)│
│                                         │
│ ├─ Auth token auto-attached             │
│ ├─ Request sent to backend              │
│ └─ Response received                    │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Firebase Cloud Functions                │
│ - Verify auth token ✅                  │
│ - Process request                       │
│ - Return response                       │
└─────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────┐
│ Response Handling                       │
│ - Success: Process data                 │
│ - Error: Show message                   │
└─────────────────────────────────────────┘
    │
    ▼
User sees result
```

---

## Auth State Timeline

```
App Launch
    │
    ▼
Firebase.initializeApp()
    │
    ▼
FirebaseAuth initialized
    │
    ▼
User logs in
    │
    ▼
authStateChanges() emits User
    │
    ▼
_authReady = false (initial)
    │
    ▼
First function call triggered
    │
    ▼
ensureAuthReady() called
    │
    ├─ Wait for authStateChanges().first
    │   (returns immediately - user already logged in)
    │
    ├─ Delay 500ms
    │   (allows token to attach to instance)
    │
    └─ _authReady = true
    │
    ▼
getIdToken(true) - force refresh
    │
    ▼
Token attached to request
    │
    ▼
Function call succeeds ✅
    │
    ▼
Subsequent calls
    │
    ├─ ensureAuthReady() returns immediately (_authReady = true)
    ├─ getIdToken(true) refreshes token
    └─ Function calls succeed ✅
```

---

## Error Prevention

```
❌ BEFORE (Multiple Instances)
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Service A    │  │ Service B    │  │ Service C    │
│ Instance 1   │  │ Instance 2   │  │ Instance 3   │
└──────────────┘  └──────────────┘  └──────────────┘
       │                 │                 │
       └─────────────────┴─────────────────┘
                         │
                    Inconsistent
                    Auth State ❌

✅ AFTER (Single Instance)
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Service A    │  │ Service B    │  │ Service C    │
│   ↓          │  │   ↓          │  │   ↓          │
│ Global       │  │ Global       │  │ Global       │
│ Instance     │  │ Instance     │  │ Instance     │
└──────────────┘  └──────────────┘  └──────────────┘
       │                 │                 │
       └─────────────────┴─────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ Single Instance      │
              │ Consistent Auth ✅   │
              └──────────────────────┘
```

---

## Key Benefits

```
┌─────────────────────────────────────────────────────────────┐
│                    BEFORE                                    │
├─────────────────────────────────────────────────────────────┤
│ ❌ Multiple instances created                               │
│ ❌ Auth token not attached                                  │
│ ❌ UNAUTHENTICATED errors                                   │
│ ❌ Inconsistent state                                       │
│ ❌ Race conditions                                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     AFTER                                    │
├─────────────────────────────────────────────────────────────┤
│ ✅ Single global instance                                   │
│ ✅ Auth readiness ensured                                   │
│ ✅ No UNAUTHENTICATED errors                                │
│ ✅ Consistent state                                         │
│ ✅ Predictable behavior                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Checklist

```
┌─────────────────────────────────────────────────────────────┐
│ □ Create FirebaseFunctionsInstance class                    │
│ □ Add ensureAuthReady() method                              │
│ □ Replace all instance declarations                         │
│ □ Add auth readiness checks                                 │
│ □ Add 500ms delays                                          │
│ □ Add token refresh calls                                   │
│ □ Add debug logging                                         │
│ □ Test compilation                                          │
│ □ Test runtime                                              │
│ □ Verify no UNAUTHENTICATED errors                          │
└─────────────────────────────────────────────────────────────┘
```

---

**Visual Guide Complete** ✅
