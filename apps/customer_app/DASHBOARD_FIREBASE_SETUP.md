# Firebase Setup for Dashboard

## Firestore Collections

### Collection: `categories`

**Document Structure:**
```json
{
  "id": "auto-generated",
  "title": "Television Protection Plan",
  "iconUrl": "https://firebasestorage.googleapis.com/...",
  "order": 1,
  "enabled": true,
  "isNew": false,
  "description": "Comprehensive protection for your TV",
  "createdAt": "2026-02-05T10:00:00Z",
  "updatedAt": "2026-02-05T10:00:00Z"
}
```

**Sample Documents to Create:**

```javascript
// Document 1
{
  title: "Television Protection Plan",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/tv.png",
  order: 1,
  enabled: true,
  isNew: false,
  description: "Comprehensive protection for your TV"
}

// Document 2
{
  title: "AC Protection Plan",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/ac.png",
  order: 2,
  enabled: true,
  isNew: true,
  description: "Keep your AC running smoothly"
}

// Document 3
{
  title: "Mobile & Tablet Protection Plans",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/mobile.png",
  order: 3,
  enabled: true,
  isNew: false,
  description: "Protect your mobile devices"
}

// Document 4
{
  title: "Refrigerator Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/fridge.png",
  order: 4,
  enabled: true,
  isNew: false,
  description: "Refrigerator care and protection"
}

// Document 5
{
  title: "Washing Machine Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/washing_machine.png",
  order: 5,
  enabled: true,
  isNew: false,
  description: "Washing machine maintenance"
}

// Document 6
{
  title: "Microwave Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/microwave.png",
  order: 6,
  enabled: true,
  isNew: false,
  description: "Microwave care plans"
}

// Document 7
{
  title: "Printer Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/printer.png",
  order: 7,
  enabled: true,
  isNew: false,
  description: "Printer maintenance and repair"
}

// Document 8
{
  title: "Audio System Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/audio.png",
  order: 8,
  enabled: true,
  isNew: false,
  description: "Audio system care"
}

// Document 9
{
  title: "Laptop & Desktop Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/laptop.png",
  order: 9,
  enabled: true,
  isNew: true,
  description: "Computer protection plans"
}

// Document 10
{
  title: "Digital Camera Protection",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/camera.png",
  order: 10,
  enabled: true,
  isNew: false,
  description: "Camera care and maintenance"
}

// Document 11 (Special Card)
{
  title: "40+ More",
  iconUrl: "gs://homefix-aa42d.appspot.com/category_icons/more.png",
  order: 99,
  enabled: true,
  isNew: false,
  description: "Explore more categories"
}
```

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Categories - Read-only for users
    match /categories/{categoryId} {
      allow read: if true; // Public read
      allow write: if exists(/databases/$(database)/documents/admins/$(request.auth.uid)); // Admin only
    }
  }
}
```

## Firebase Storage Structure

```
homefix-aa42d.appspot.com/
└── category_icons/
    ├── tv.png
    ├── ac.png
    ├── mobile.png
    ├── fridge.png
    ├── washing_machine.png
    ├── microwave.png
    ├── printer.png
    ├── audio.png
    ├── laptop.png
    ├── camera.png
    └── more.png
```

## Quick Setup Commands

### 1. Create Firestore Collection (Firebase Console)
1. Go to Firestore Database
2. Click "Start collection"
3. Collection ID: `categories`
4. Add documents using the sample data above

### 2. Upload Icons to Firebase Storage
1. Go to Firebase Storage
2. Create folder: `category_icons`
3. Upload icon images (PNG, 512x512 recommended)
4. Make files public or use Firebase Storage URLs

### 3. Get Storage URLs
```bash
# For each icon, get the download URL from Firebase Console
# Or use Firebase Admin SDK to generate URLs
```

## Testing Data

To quickly populate Firestore, use Firebase Console or run this script:

```javascript
// Run in Firebase Console > Firestore > Add Document
const categories = [
  { title: "Television Protection Plan", iconUrl: "URL_HERE", order: 1, enabled: true, isNew: false },
  { title: "AC Protection Plan", iconUrl: "URL_HERE", order: 2, enabled: true, isNew: true },
  // ... add all categories
];

// Batch write
categories.forEach(cat => {
  db.collection('categories').add(cat);
});
```
