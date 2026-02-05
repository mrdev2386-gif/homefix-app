# HomeFix Technician Onboarding System - Complete Architecture

**Version:** 1.0  
**Date:** 2026-02-09  
**Classification:** Production-Grade, Security-First Design

---

## 🎯 CORE PRINCIPLES

1. **Platform-Controlled Services**: Technicians CANNOT create services
2. **Backend-First Security**: All mutations via Cloud Functions
3. **Zero Trust Architecture**: Client apps are untrusted
4. **Admin-Gated Approval**: Multi-stage verification required
5. **Scalable to 1M+ Technicians**: Designed for massive scale

---

## 📊 1. MASTER SERVICE CATALOG (Admin-Only)

### 1.1 Service Hierarchy

```
Platform Services (20-25 Main Categories)
├── AC Services
│   ├── Split AC Repair
│   ├── Window AC Repair
│   ├── AC Installation
│   ├── AC Uninstallation
│   ├── AC Gas Refilling
│   └── AC Deep Cleaning
├── Electrical Services
│   ├── Fan Repair
│   │   ├── Ceiling Fan
│   │   ├── Exhaust Fan
│   │   └── Table Fan
│   ├── Switch & Socket Repair
│   ├── MCB & DB Box
│   ├── Wiring & Rewiring
│   └── Light Fixture Installation
├── Plumbing
│   ├── Tap & Mixer Repair
│   ├── Toilet & Flush Repair
│   ├── Pipe Leak Fixing
│   ├── Drainage Cleaning
│   └── Water Tank Installation
├── Carpentry
│   ├── Door Repair
│   ├── Window Repair
│   ├── Furniture Assembly
│   ├── Cabinet Installation
│   └── Wood Polishing
├── Cleaning Services
│   ├── Deep Home Cleaning
│   ├── Bathroom Cleaning
│   ├── Kitchen Cleaning
│   ├── Sofa Cleaning
│   └── Carpet Cleaning
├── Appliance Repair
│   ├── Washing Machine
│   ├── Refrigerator
│   ├── Microwave
│   ├── Geyser
│   └── Chimney
├── Painting
│   ├── Interior Painting
│   ├── Exterior Painting
│   ├── Waterproofing
│   └── Texture Painting
├── Pest Control
│   ├── Cockroach Treatment
│   ├── Termite Control
│   ├── Bed Bug Treatment
│   └── Rodent Control
├── RO & Water Purifier
│   ├── RO Installation
│   ├── RO Repair
│   ├── Filter Replacement
│   └── AMC Services
├── CCTV & Security
│   ├── CCTV Installation
│   ├── CCTV Repair
│   ├── Intercom Setup
│   └── Smart Lock Installation
├── Salon & Beauty (Home Service)
│   ├── Haircut (Men)
│   ├── Haircut (Women)
│   ├── Facial
│   ├── Pedicure/Manicure
│   └── Waxing
├── Massage & Spa
│   ├── Full Body Massage
│   ├── Foot Massage
│   └── Head Massage
├── Fitness & Yoga
│   ├── Personal Trainer
│   ├── Yoga Instructor
│   └── Zumba Instructor
├── Tutoring
│   ├── Math Tutor
│   ├── Science Tutor
│   ├── Language Tutor
│   └── Music Lessons
├── Packers & Movers
│   ├── Local Shifting
│   ├── Intercity Moving
│   └── Packing Services
├── Interior Design
│   ├── Consultation
│   ├── Modular Kitchen
│   └── False Ceiling
├── Gardening
│   ├── Lawn Maintenance
│   ├── Plant Care
│   └── Landscaping
├── Car Services
│   ├── Car Wash
│   ├── Car Detailing
│   └── Denting & Painting
├── Mobile & Laptop Repair
│   ├── Screen Replacement
│   ├── Battery Replacement
│   └── Software Issues
└── Event Services
    ├── Photography
    ├── Catering
    └── Decoration
```

### 1.2 Firestore Structure

```typescript
// Collection: services
services/{serviceId}
{
  id: string,
  name: string,
  category: string, // 'home_services' | 'beauty' | 'education' | 'moving'
  icon: string, // URL or icon name
  description: string,
  isActive: boolean,
  order: number, // Display order
  createdAt: Timestamp,
  updatedAt: Timestamp,
  metadata: {
    totalSubServices: number,
    activeTechnicians: number,
    avgRating: number
  }
}

// Collection: subServices
subServices/{subServiceId}
{
  id: string,
  serviceId: string, // Parent service reference
  name: string,
  description: string,
  isActive: boolean,
  basePrice: number, // Admin-controlled pricing
  estimatedDuration: number, // in minutes
  requiredTools: string[], // ['screwdriver', 'multimeter']
  requiredCertifications: string[], // ['electrical_license']
  order: number,
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// Collection: servicePricing (Admin-controlled)
servicePricing/{pricingId}
{
  subServiceId: string,
  city: string,
  basePrice: number,
  urgentCharge: number,
  platformFee: number, // %
  technicianShare: number, // %
  taxes: number, // %
  validFrom: Timestamp,
  validUntil: Timestamp
}
```

---

## 🚀 2. TECHNICIAN ONBOARDING FLOW (10-Step Process)

### STEP 1: Phone OTP Verification

**UI Flow:**
1. Enter phone number (+91 format)
2. Send OTP via Firebase Auth
3. Verify OTP (6 digits)
4. Rate limiting: Max 3 attempts per hour

**Security:**
- Firebase App Check enabled
- reCAPTCHA v3 for web
- Device fingerprinting
- Block VoIP numbers

**Cloud Function:**
```typescript
// functions/src/technician/auth.ts
export const initiatePhoneVerification = functions.https.onCall(async (data, context) => {
  // Rate limiting check
  const attempts = await checkRateLimit(data.phoneNumber);
  if (attempts > 3) throw new functions.https.HttpsError('resource-exhausted', 'Too many attempts');
  
  // Check if phone already registered
  const existing = await db.collection('technicians').where('phone', '==', data.phoneNumber).get();
  if (!existing.empty) throw new functions.https.HttpsError('already-exists', 'Phone already registered');
  
  // Log attempt
  await logAuthAttempt(data.phoneNumber, context);
  
  return { success: true };
});
```

**Firestore:**
```typescript
// Collection: technicianApplications
technicianApplications/{applicationId}
{
  phone: string,
  status: 'phone_verified' | 'draft' | 'submitted' | 'approved',
  createdAt: Timestamp,
  currentStep: number,
  deviceInfo: {
    deviceId: string,
    platform: string,
    appVersion: string
  }
}
```

---

### STEP 2: Personal Details

**UI Fields:**
- Full Name (min 3 chars, no special chars)
- Profile Photo (Camera only, no gallery)
- Date of Birth (18+ validation)
- Gender (Male/Female/Other)
- Current Address (GPS + Manual)
- City Selection (Dropdown)
- Service Radius (5km - 50km slider)

**Validation Rules:**
```typescript
{
  name: {
    minLength: 3,
    maxLength: 50,
    pattern: /^[a-zA-Z\s]+$/,
    required: true
  },
  dob: {
    minAge: 18,
    maxAge: 70,
    required: true
  },
  photo: {
    maxSize: 5MB,
    format: ['jpg', 'png'],
    liveCapture: true, // Must be from camera
    required: true
  },
  address: {
    gpsRequired: true,
    manualVerification: true
  }
}
```

**Cloud Function:**
```typescript
export const savePersonalDetails = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  // Validate age
  const age = calculateAge(data.dob);
  if (age < 18) throw new functions.https.HttpsError('invalid-argument', 'Must be 18+');
  
  // Upload photo to Storage with security rules
  const photoUrl = await uploadProfilePhoto(data.photoBase64, context.auth.uid);
  
  // Geocode address
  const coordinates = await geocodeAddress(data.address);
  
  await db.collection('technicianApplications').doc(context.auth.uid).update({
    personalDetails: {
      name: sanitize(data.name),
      dob: admin.firestore.Timestamp.fromDate(new Date(data.dob)),
      gender: data.gender,
      photoUrl,
      address: data.address,
      coordinates,
      city: data.city,
      serviceRadius: data.serviceRadius
    },
    currentStep: 2,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 3 };
});
```

---

### STEP 3: Identity Verification (KYC)

**UI Flow:**
1. Select ID Type (Aadhaar/PAN/Driving License)
2. Upload Front Image (Camera)
3. Upload Back Image (Camera)
4. Capture Live Selfie
5. Submit for Verification

**Security:**
- Images encrypted at rest
- Face matching via ML (optional)
- Manual admin review required
- OCR for data extraction

**Cloud Function:**
```typescript
export const submitKYC = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const techId = context.auth!.uid;
  
  // Upload documents to secure storage
  const frontUrl = await uploadKYCDocument(data.frontImage, techId, 'front');
  const backUrl = await uploadKYCDocument(data.backImage, techId, 'back');
  const selfieUrl = await uploadKYCDocument(data.selfie, techId, 'selfie');
  
  // Extract text via OCR (Google Vision API)
  const extractedData = await extractKYCData(frontUrl, data.idType);
  
  // Create verification task for admin
  await db.collection('kycVerificationQueue').add({
    technicianId: techId,
    idType: data.idType,
    frontUrl,
    backUrl,
    selfieUrl,
    extractedData,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  await db.collection('technicianApplications').doc(techId).update({
    kyc: {
      idType: data.idType,
      status: 'pending_verification',
      submittedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    currentStep: 3,
    status: 'kyc_submitted'
  });
  
  return { success: true, message: 'KYC submitted for verification' };
});
```

**Firestore:**
```typescript
kycVerificationQueue/{queueId}
{
  technicianId: string,
  idType: 'aadhaar' | 'pan' | 'driving_license',
  frontUrl: string, // Secure Storage URL
  backUrl: string,
  selfieUrl: string,
  extractedData: {
    name: string,
    idNumber: string,
    dob: string
  },
  status: 'pending' | 'approved' | 'rejected',
  reviewedBy: string, // Admin UID
  reviewedAt: Timestamp,
  rejectionReason: string
}
```

---

### STEP 4: Skill Selection (CORE FEATURE)

**UI Behavior:**

```
┌─────────────────────────────────────┐
│  Select Your Skills                 │
├─────────────────────────────────────┤
│                                     │
│  🔧 AC Services              [+]    │
│  ⚡ Electrical Services      [+]    │
│  🚰 Plumbing                 [+]    │
│  🪚 Carpentry                [+]    │
│  🧹 Cleaning Services        [+]    │
│  🔌 Appliance Repair         [+]    │
│  🎨 Painting                 [+]    │
│  🐛 Pest Control             [+]    │
│  💧 RO & Water Purifier      [+]    │
│  📹 CCTV & Security          [+]    │
│                                     │
└─────────────────────────────────────┘
```

**On Expanding AC Services:**

```
┌─────────────────────────────────────┐
│  🔧 AC Services              [-]    │
│  ┌───────────────────────────────┐  │
│  │ Select Sub-Services:          │  │
│  │ ☑ Split AC Repair             │  │
│  │ ☑ Window AC Repair            │  │
│  │ ☐ AC Installation             │  │
│  │ ☐ AC Uninstallation           │  │
│  │ ☑ AC Gas Refilling            │  │
│  │ ☐ AC Deep Cleaning            │  │
│  └───────────────────────────────┘  │
│                                     │
│  ⚡ Electrical Services      [+]    │
└─────────────────────────────────────┘
```

**Validation Rules:**
- Minimum: 1 main service
- Maximum: 5 main services
- Each selected main service MUST have ≥1 sub-service
- Cannot proceed without meeting criteria

**Data Structure:**
```typescript
selectedSkills: {
  'ac-services': {
    serviceId: 'ac-services',
    serviceName: 'AC Services',
    subServices: [
      { id: 'split-ac-repair', name: 'Split AC Repair' },
      { id: 'window-ac-repair', name: 'Window AC Repair' },
      { id: 'ac-gas-refilling', name: 'AC Gas Refilling' }
    ]
  },
  'electrical': {
    serviceId: 'electrical',
    serviceName: 'Electrical Services',
    subServices: [
      { id: 'fan-repair-ceiling', name: 'Ceiling Fan Repair' },
      { id: 'switch-socket', name: 'Switch & Socket Repair' }
    ]
  }
}
```

**Cloud Function:**
```typescript
export const saveSkillSelection = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const { selectedSkills } = data;
  
  // Validation
  const mainServiceCount = Object.keys(selectedSkills).length;
  if (mainServiceCount < 1 || mainServiceCount > 5) {
    throw new functions.https.HttpsError('invalid-argument', 'Select 1-5 main services');
  }
  
  // Verify each main service has sub-services
  for (const [serviceId, skillData] of Object.entries(selectedSkills)) {
    if (!skillData.subServices || skillData.subServices.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', `${skillData.serviceName} needs sub-services`);
    }
    
    // Verify sub-services exist in master catalog
    for (const subService of skillData.subServices) {
      const exists = await db.collection('subServices').doc(subService.id).get();
      if (!exists.exists) {
        throw new functions.https.HttpsError('not-found', `Invalid sub-service: ${subService.id}`);
      }
    }
  }
  
  // Save to application
  await db.collection('technicianApplications').doc(context.auth!.uid).update({
    skills: selectedSkills,
    currentStep: 4,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 5 };
});
```

**Firestore Storage:**
```typescript
technicianApplications/{techId}/skills
{
  'ac-services': {
    serviceId: 'ac-services',
    serviceName: 'AC Services',
    subServiceIds: ['split-ac-repair', 'window-ac-repair', 'ac-gas-refilling'],
    addedAt: Timestamp
  },
  'electrical': {
    serviceId: 'electrical',
    serviceName: 'Electrical Services',
    subServiceIds: ['fan-repair-ceiling', 'switch-socket'],
    addedAt: Timestamp
  }
}
```

---

### STEP 5: Experience & Tools

**UI Fields:**
- Years of Experience (Per Service)
- Tools Owned (Checkboxes)
- Brand Familiarity (Optional)
- Certifications (Upload)

**Example:**
```
AC Services
├── Experience: [5] years
├── Tools Owned:
│   ☑ Vacuum Pump
│   ☑ Pressure Gauge
│   ☑ Leak Detector
│   ☐ Welding Kit
└── Brands Worked On:
    ☑ Voltas
    ☑ Daikin
    ☐ LG
```

**Cloud Function:**
```typescript
export const saveExperienceDetails = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const experienceData = {};
  
  for (const [serviceId, details] of Object.entries(data.experience)) {
    if (details.years < 0 || details.years > 50) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid experience years');
    }
    
    experienceData[serviceId] = {
      years: details.years,
      tools: details.tools || [],
      brands: details.brands || [],
      certifications: details.certifications || []
    };
  }
  
  await db.collection('technicianApplications').doc(context.auth!.uid).update({
    experience: experienceData,
    currentStep: 5,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 6 };
});
```

---

### STEP 6: Availability Setup

**UI:**
```
Working Days:
☑ Monday    ☑ Tuesday   ☑ Wednesday
☑ Thursday  ☑ Friday    ☐ Saturday
☐ Sunday

Working Hours:
Start: [09:00 AM]  End: [06:00 PM]

☑ Available for Emergency Calls
☐ Night Shift Available (8PM - 6AM)
```

**Cloud Function:**
```typescript
export const saveAvailability = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const { workingDays, startTime, endTime, emergencyAvailable, nightShift } = data;
  
  if (workingDays.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Select at least 1 working day');
  }
  
  await db.collection('technicianApplications').doc(context.auth!.uid).update({
    availability: {
      workingDays,
      startTime,
      endTime,
      emergencyAvailable,
      nightShift
    },
    currentStep: 6,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 7 };
});
```

---

### STEP 7: Service Area Mapping

**UI:**
- Pin Code Selection (Multi-select)
- Service Radius (Slider: 5km - 50km)
- Map Preview

**Cloud Function:**
```typescript
export const saveServiceArea = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const { pinCodes, radius } = data;
  
  if (pinCodes.length === 0 || pinCodes.length > 10) {
    throw new functions.https.HttpsError('invalid-argument', 'Select 1-10 pin codes');
  }
  
  if (radius < 5 || radius > 50) {
    throw new functions.https.HttpsError('invalid-argument', 'Radius must be 5-50 km');
  }
  
  await db.collection('technicianApplications').doc(context.auth!.uid).update({
    serviceArea: {
      pinCodes,
      radius,
      coordinates: data.coordinates
    },
    currentStep: 7,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 8 };
});
```

---

### STEP 8: Bank & Payout Setup

**UI:**
- Bank Account Number
- IFSC Code
- Account Holder Name
- UPI ID (Optional)

**Security:**
- Name matching with KYC
- Bank verification via Razorpay
- Encrypted storage

**Cloud Function:**
```typescript
export const saveBankDetails = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const { accountNumber, ifsc, holderName, upiId } = data;
  
  // Verify name matches KYC
  const application = await db.collection('technicianApplications').doc(context.auth!.uid).get();
  const kycName = application.data()?.personalDetails?.name;
  
  if (!nameMatches(holderName, kycName)) {
    throw new functions.https.HttpsError('invalid-argument', 'Name must match KYC');
  }
  
  // Verify bank account via Razorpay (optional)
  // const verified = await verifyBankAccount(accountNumber, ifsc);
  
  // Encrypt sensitive data
  const encryptedAccount = encrypt(accountNumber);
  
  await db.collection('technicianApplications').doc(context.auth!.uid).update({
    bankDetails: {
      accountNumber: encryptedAccount,
      ifsc,
      holderName,
      upiId,
      verified: false // Admin will verify
    },
    currentStep: 8,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 9 };
});
```

---

### STEP 9: Training & Rules

**UI:**
- Mandatory Training Video (Cannot skip)
- Platform Rules PDF
- Penalties & Rating System
- Acceptance Checkbox

**Cloud Function:**
```typescript
export const completeTraining = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const { videoWatched, rulesAccepted, timestamp } = data;
  
  if (!videoWatched || !rulesAccepted) {
    throw new functions.https.HttpsError('failed-precondition', 'Must complete training');
  }
  
  // Verify video watch time (minimum duration)
  const minDuration = 300; // 5 minutes
  if (timestamp < minDuration) {
    throw new functions.https.HttpsError('invalid-argument', 'Must watch full video');
  }
  
  await db.collection('technicianApplications').doc(context.auth!.uid).update({
    training: {
      videoWatched: true,
      rulesAccepted: true,
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    currentStep: 9,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, nextStep: 10 };
});
```

---

### STEP 10: Final Review & Submit

**UI:**
- Show complete summary
- Edit buttons for each section
- Final Submit button

**Cloud Function:**
```typescript
export const submitApplication = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const techId = context.auth!.uid;
  const application = await db.collection('technicianApplications').doc(techId).get();
  
  if (!application.exists) {
    throw new functions.https.HttpsError('not-found', 'Application not found');
  }
  
  const appData = application.data()!;
  
  // Validate all steps completed
  if (appData.currentStep < 9) {
    throw new functions.https.HttpsError('failed-precondition', 'Complete all steps');
  }
  
  // Create technician profile (inactive)
  await db.collection('technicians').doc(techId).set({
    ...appData.personalDetails,
    ...appData.skills,
    ...appData.experience,
    ...appData.availability,
    ...appData.serviceArea,
    phone: appData.phone,
    status: 'pending_verification',
    isActive: false,
    isOnline: false,
    rating: 0,
    totalJobs: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // Update application status
  await db.collection('technicianApplications').doc(techId).update({
    status: 'submitted',
    submittedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // Notify admin
  await notifyAdminNewApplication(techId);
  
  return { success: true, message: 'Application submitted successfully' };
});
```

---

## 📋 3. POST-ONBOARDING STATUS FLOW

### Status Lifecycle

```
draft
  ↓
phone_verified
  ↓
kyc_submitted
  ↓
kyc_verified (Admin Action)
  ↓
skills_verified (Admin Action)
  ↓
approved (Admin Action)
  ↓
active (Technician can toggle)
  ↓
suspended (Admin/System Action)
```

### Firestore Structure

```typescript
technicians/{techId}
{
  // Personal
  name: string,
  phone: string,
  photoUrl: string,
  dob: Timestamp,
  gender: string,
  
  // Location
  address: string,
  coordinates: GeoPoint,
  city: string,
  serviceRadius: number,
  pinCodes: string[],
  
  // Skills (Immutable without re-verification)
  skills: {
    [serviceId]: {
      serviceId: string,
      serviceName: string,
      subServiceIds: string[],
      experience: number,
      tools: string[],
      verifiedAt: Timestamp
    }
  },
  
  // Status
  status: 'pending_verification' | 'kyc_verified' | 'approved' | 'active' | 'suspended',
  isActive: boolean,
  isOnline: boolean,
  
  // Availability
  availability: {
    workingDays: number[], // [1,2,3,4,5] = Mon-Fri
    startTime: string,
    endTime: string,
    emergencyAvailable: boolean
  },
  
  // Performance
  rating: number,
  totalJobs: number,
  completedJobs: number,
  cancelledJobs: number,
  
  // Security
  deviceId: string,
  lastLocation: GeoPoint,
  lastSeen: Timestamp,
  
  // Audit
  createdAt: Timestamp,
  updatedAt: Timestamp,
  approvedBy: string, // Admin UID
  approvedAt: Timestamp
}
```

---

## 🔔 4. BOOKING → ALERT FLOW

### Customer Books Service

```typescript
// Customer selects: AC Services → Split AC Repair
// Location: Pin Code 110001

// Cloud Function: createBooking
export const createBooking = functions.https.onCall(async (data, context) => {
  assertAuthenticated(context);
  
  const { subServiceId, location, scheduledTime } = data;
  
  // Create booking
  const bookingRef = await db.collection('bookings').add({
    customerId: context.auth!.uid,
    subServiceId,
    location,
    scheduledTime,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // Find matching technicians
  const matchingTechs = await findMatchingTechnicians(subServiceId, location);
  
  // Send alerts
  await sendBookingAlerts(bookingRef.id, matchingTechs);
  
  return { bookingId: bookingRef.id };
});
```

### Matching Algorithm

```typescript
async function findMatchingTechnicians(subServiceId: string, location: GeoPoint) {
  // Get sub-service details
  const subService = await db.collection('subServices').doc(subServiceId).get();
  const serviceId = subService.data()!.serviceId;
  
  // Query technicians
  const technicians = await db.collection('technicians')
    .where('status', '==', 'active')
    .where('isOnline', '==', true)
    .where(`skills.${serviceId}.subServiceIds`, 'array-contains', subServiceId)
    .get();
  
  // Filter by distance
  const nearby = technicians.docs.filter(doc => {
    const techData = doc.data();
    const distance = calculateDistance(location, techData.coordinates);
    return distance <= techData.serviceRadius;
  });
  
  // Sort by rating
  nearby.sort((a, b) => b.data().rating - a.data().rating);
  
  return nearby.slice(0, 10); // Top 10 technicians
}
```

### Alert Strategy

**Option 1: Broadcast (All at once)**
```typescript
async function sendBookingAlerts(bookingId: string, technicians: any[]) {
  const alerts = technicians.map(tech => ({
    technicianId: tech.id,
    bookingId,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'sent'
  }));
  
  // Send FCM notifications
  const tokens = technicians.map(t => t.data().fcmToken).filter(Boolean);
  await admin.messaging().sendMulticast({
    tokens,
    notification: {
      title: 'New Booking Alert',
      body: 'A customer needs your service nearby'
    },
    data: { bookingId }
  });
  
  // Log alerts
  await db.collection('bookingAlerts').add({ bookingId, alerts });
}
```

**Option 2: Priority-Based (Sequential)**
```typescript
async function sendPriorityAlerts(bookingId: string, technicians: any[]) {
  for (let i = 0; i < technicians.length; i++) {
    const tech = technicians[i];
    
    // Send to top technician
    await sendFCM(tech.data().fcmToken, bookingId);
    
    // Wait 2 minutes for response
    await sleep(120000);
    
    // Check if accepted
    const booking = await db.collection('bookings').doc(bookingId).get();
    if (booking.data()!.status === 'accepted') break;
    
    // Move to next technician
  }
}
```

### Technician Response

```typescript
export const respondToBooking = functions.https.onCall(async (data, context) => {
  assertTechnician(context);
  
  const { bookingId, action } = data; // 'accept' | 'reject'
  
  const bookingRef = db.collection('bookings').doc(bookingId);
  const booking = await bookingRef.get();
  
  if (!booking.exists) {
    throw new functions.https.HttpsError('not-found', 'Booking not found');
  }
  
  if (booking.data()!.status !== 'pending') {
    throw new functions.https.HttpsError('failed-precondition', 'Booking already assigned');
  }
  
  if (action === 'accept') {
    await bookingRef.update({
      technicianId: context.auth!.uid,
      status: 'accepted',
      acceptedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // Notify customer
    await notifyCustomer(booking.data()!.customerId, bookingId);
    
    return { success: true, message: 'Booking accepted' };
  } else {
    // Log rejection
    await db.collection('bookingRejections').add({
      bookingId,
      technicianId: context.auth!.uid,
      rejectedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true, message: 'Booking rejected' };
  }
});
```

---

## 🔒 5. SECURITY & ANTI-FRAUD

### 5.1 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Services: Read-only for all, write for admin only
    match /services/{serviceId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /subServices/{subServiceId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Technician Applications: Owner + Admin only
    match /technicianApplications/{techId} {
      allow read: if request.auth.uid == techId || isAdmin();
      allow create: if request.auth.uid == techId;
      allow update: if false; // Only via Cloud Functions
      allow delete: if false;
    }
    
    // Technicians: Read for customers, no direct write
    match /technicians/{techId} {
      allow read: if true;
      allow write: if false; // Only via Cloud Functions
    }
    
    // Bookings: Customer + Assigned Technician + Admin
    match /bookings/{bookingId} {
      allow read: if request.auth.uid == resource.data.customerId
                  || request.auth.uid == resource.data.technicianId
                  || isAdmin();
      allow create: if request.auth.uid == request.resource.data.customerId;
      allow update: if false; // Only via Cloud Functions
    }
    
    function isAdmin() {
      return request.auth != null && 
             request.auth.token.admin == true;
    }
  }
}
```

### 5.2 Anti-Fraud Measures

**Device Binding:**
```typescript
// On first login, bind device
export const bindDevice = functions.https.onCall(async (data, context) => {
  assertTechnician(context);
  
  const { deviceId, deviceInfo } = data;
  
  const tech = await db.collection('technicians').doc(context.auth!.uid).get();
  
  if (tech.data()!.deviceId && tech.data()!.deviceId !== deviceId) {
    // Device changed - require admin approval
    await db.collection('deviceChangeRequests').add({
      technicianId: context.auth!.uid,
      oldDeviceId: tech.data()!.deviceId,
      newDeviceId: deviceId,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    throw new functions.https.HttpsError('permission-denied', 'Device change requires approval');
  }
  
  await db.collection('technicians').doc(context.auth!.uid).update({
    deviceId,
    deviceInfo
  });
  
  return { success: true };
});
```

**Location Spoofing Protection:**
```typescript
export const updateLocation = functions.https.onCall(async (data, context) => {
  assertTechnician(context);
  
  const { location, timestamp } = data;
  
  // Check if location is realistic
  const lastLocation = await getLastLocation(context.auth!.uid);
  if (lastLocation) {
    const distance = calculateDistance(lastLocation.coordinates, location);
    const timeDiff = (timestamp - lastLocation.timestamp) / 1000; // seconds
    const speed = distance / timeDiff; // km/s
    
    if (speed > 0.05) { // > 180 km/h
      // Flag suspicious activity
      await flagSuspiciousActivity(context.auth!.uid, 'impossible_speed');
      throw new functions.https.HttpsError('invalid-argument', 'Invalid location');
    }
  }
  
  await db.collection('technicians').doc(context.auth!.uid).update({
    lastLocation: new admin.firestore.GeoPoint(location.lat, location.lng),
    lastSeen: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true };
});
```

**Skill Modification Lock:**
```typescript
export const requestSkillUpdate = functions.https.onCall(async (data, context) => {
  assertTechnician(context);
  
  const { newSkills } = data;
  
  // Cannot directly update skills
  // Must go through re-verification
  await db.collection('skillUpdateRequests').add({
    technicianId: context.auth!.uid,
    currentSkills: (await db.collection('technicians').doc(context.auth!.uid).get()).data()!.skills,
    requestedSkills: newSkills,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return { success: true, message: 'Skill update request submitted for verification' };
});
```

**Audit Logging:**
```typescript
// Log all critical actions
async function logAction(action: string, userId: string, data: any) {
  await db.collection('auditLogs').add({
    action,
    userId,
    data,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    ipAddress: data.ipAddress,
    userAgent: data.userAgent
  });
}
```

---

## 📊 6. ADMIN DASHBOARD FEATURES

### Verification Queue

```typescript
// Admin function to approve KYC
export const approveKYC = functions.https.onCall(async (data, context) => {
  assertAdmin(context);
  
  const { technicianId, approved, reason } = data;
  
  if (approved) {
    await db.collection('technicianApplications').doc(technicianId).update({
      'kyc.status': 'approved',
      'kyc.approvedBy': context.auth!.uid,
      'kyc.approvedAt': admin.firestore.FieldValue.serverTimestamp(),
      status: 'kyc_verified'
    });
  } else {
    await db.collection('technicianApplications').doc(technicianId).update({
      'kyc.status': 'rejected',
      'kyc.rejectedBy': context.auth!.uid,
      'kyc.rejectedAt': admin.firestore.FieldValue.serverTimestamp(),
      'kyc.rejectionReason': reason
    });
  }
  
  // Notify technician
  await notifyTechnician(technicianId, approved ? 'kyc_approved' : 'kyc_rejected');
  
  return { success: true };
});

// Admin function to approve full application
export const approveTechnician = functions.https.onCall(async (data, context) => {
  assertAdmin(context);
  
  const { technicianId } = data;
  
  const application = await db.collection('technicianApplications').doc(technicianId).get();
  
  if (application.data()!.status !== 'submitted') {
    throw new functions.https.HttpsError('failed-precondition', 'Application not ready');
  }
  
  // Update technician status
  await db.collection('technicians').doc(technicianId).update({
    status: 'approved',
    approvedBy: context.auth!.uid,
    approvedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // Update application
  await db.collection('technicianApplications').doc(technicianId).update({
    status: 'approved',
    approvedBy: context.auth!.uid,
    approvedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  // Send welcome notification
  await sendWelcomeNotification(technicianId);
  
  return { success: true };
});
```

---

## 🎯 7. SCALABILITY CONSIDERATIONS

### For 1M+ Technicians

**1. Geohashing for Location Queries:**
```typescript
import * as geohash from 'ngeohash';

// Store geohash with technician
await db.collection('technicians').doc(techId).update({
  geohash: geohash.encode(lat, lng, 7) // 7-char precision (~150m)
});

// Query nearby technicians
const hash = geohash.encode(customerLat, customerLng, 7);
const neighbors = geohash.neighbors(hash);

const queries = [hash, ...neighbors].map(h => 
  db.collection('technicians')
    .where('geohash', '>=', h)
    .where('geohash', '<=', h + '~')
    .get()
);

const results = await Promise.all(queries);
```

**2. Composite Indexes:**
```
technicians
  - status ASC, isOnline ASC, rating DESC
  - city ASC, status ASC, isOnline ASC
  - geohash ASC, status ASC
```

**3. Caching Layer:**
```typescript
// Use Redis for hot data
const redis = new Redis();

// Cache active technicians
await redis.setex(`techs:${city}:active`, 300, JSON.stringify(activeTechs));

// Cache service catalog
await redis.setex('services:catalog', 3600, JSON.stringify(services));
```

**4. Sharding Strategy:**
```
technicians_india_north/{techId}
technicians_india_south/{techId}
technicians_india_east/{techId}
technicians_india_west/{techId}
```

---

## ✅ FINAL CHECKLIST

- ✅ Platform-controlled service catalog
- ✅ 10-step onboarding (filters fake users)
- ✅ Multi-stage verification (Phone → KYC → Skills → Admin)
- ✅ Skill selection from predefined services only
- ✅ No technician pricing control
- ✅ Backend-first security (Cloud Functions only)
- ✅ Device binding & location verification
- ✅ Automated booking alerts
- ✅ Admin approval gates
- ✅ Audit logging
- ✅ Scalable to 1M+ technicians

---

**END OF SPECIFICATION**
