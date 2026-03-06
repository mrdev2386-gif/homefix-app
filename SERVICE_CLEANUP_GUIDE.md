# Service Catalog Cleanup - Complete Guide

## Overview

This guide provides instructions for cleaning up the HomeFix service catalog by removing invalid, outdated, or placeholder services from Firestore.

## What Gets Removed

Services are marked as invalid if they have ANY of the following:

1. **Missing or Zero Price**
   - `basePrice` is null, undefined, or 0

2. **Missing Duration**
   - `estimatedDuration` is null, undefined, or empty string

3. **Missing Name**
   - `name` is null, undefined, or empty string

4. **Missing Category**
   - `categoryId` is null, undefined, or empty string

5. **Test/Placeholder Data**
   - Name contains: "test", "sample", "demo"
   - Description contains: "placeholder"

## Method 1: Using Admin Panel UI (Recommended)

### Step 1: Access Services Page
1. Login to Admin Panel
2. Navigate to **Services** page from sidebar

### Step 2: Review Invalid Services
- Red alert banner will appear if invalid services are detected
- Invalid services are highlighted in red in the table
- Shows count: Total | Valid | Invalid

### Step 3: Clean Up
1. Click **"Clean Up Invalid Services"** button
2. Review the confirmation dialog
3. Click **"Confirm"** to permanently delete invalid services
4. Services will be removed from Firestore
5. Page will refresh automatically

### Step 4: Verify
- Check that invalid services are removed
- Verify valid services remain intact
- Review service statistics

## Method 2: Using Cleanup Script

### Prerequisites
```bash
npm install firebase-admin
```

### Run Script
```bash
cd scripts
node cleanup-services.js
```

### Script Output
```
🧹 Starting service catalog cleanup...

📊 Total services found: 45

✅ Valid services: 38
❌ Invalid services to remove: 7

📋 Invalid services identified:

  - Test Service (abc123)
    Price: ₹0
    Duration: N/A
    Category: N/A

  - Sample Plumbing (def456)
    Price: ₹0
    Duration: 30 mins
    Category: plumbing

🗑️  Deleting invalid services...

✅ Invalid services deleted successfully!

📊 Valid services summary:

  ac-repair: 8 services
  plumbing: 12 services
  electrical: 10 services
  carpentry: 8 services

✅ Cleanup complete!
```

## Method 3: Manual Firestore Cleanup

### Using Firebase Console

1. Go to Firebase Console → Firestore Database
2. Navigate to `services` collection
3. Manually identify and delete invalid services:
   - Filter by `basePrice == 0`
   - Filter by `estimatedDuration == ""`
   - Search for test/sample services
4. Delete each invalid document

## Valid Service Structure

A valid service must have:

```typescript
{
  id: string;                    // Auto-generated
  name: string;                  // Non-empty, no test/sample
  description: string;           // Non-empty, no placeholder
  categoryId: string;            // Valid category reference
  basePrice: number;             // > 0
  estimatedDuration: string;     // e.g., "30 mins", "1-2 hours"
  isActive: boolean;             // true/false
  imageUrl?: string;             // Optional
  tags?: string[];               // Optional
  createdAt: Timestamp;          // Auto-generated
  updatedAt: Timestamp;          // Auto-generated
}
```

## Example Valid Services

### AC Repair Services
```json
{
  "name": "AC Installation",
  "categoryId": "ac-repair",
  "basePrice": 2500,
  "estimatedDuration": "2-3 hours",
  "description": "Professional AC installation service",
  "isActive": true
}
```

### Plumbing Services
```json
{
  "name": "Tap Repair",
  "categoryId": "plumbing",
  "basePrice": 150,
  "estimatedDuration": "30 mins",
  "description": "Fix leaking or damaged taps",
  "isActive": true
}
```

## Post-Cleanup Verification

### Check Service Count
```javascript
// In Firebase Console
db.collection('services').get().then(snap => {
  console.log('Total services:', snap.size);
});
```

### Verify No Invalid Services
```javascript
// Check for zero-price services
db.collection('services')
  .where('basePrice', '==', 0)
  .get()
  .then(snap => {
    console.log('Services with price 0:', snap.size);
  });
```

### Check Category Distribution
```javascript
// Group by category
db.collection('services').get().then(snap => {
  const categories = {};
  snap.forEach(doc => {
    const catId = doc.data().categoryId;
    categories[catId] = (categories[catId] || 0) + 1;
  });
  console.log('Services by category:', categories);
});
```

## Troubleshooting

### Issue: Cleanup button not appearing
**Solution:** Refresh the page. The system scans for invalid services on load.

### Issue: Services not deleting
**Solution:** 
1. Check Firestore security rules allow admin deletion
2. Verify you're logged in as admin
3. Check browser console for errors

### Issue: Valid services marked as invalid
**Solution:** 
1. Review the service data in Firestore
2. Ensure all required fields are present
3. Check for typos in field names

## Security Rules

Ensure Firestore rules allow admin deletion:

```javascript
match /services/{serviceId} {
  allow read: if true;
  allow write: if request.auth != null && 
    get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
  allow delete: if request.auth != null && 
    get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
}
```

## Backup Before Cleanup

### Export Services Collection
```bash
firebase firestore:export gs://your-bucket/backups/services-$(date +%Y%m%d)
```

### Restore if Needed
```bash
firebase firestore:import gs://your-bucket/backups/services-20240101
```

## Maintenance Schedule

Recommended cleanup frequency:
- **Weekly**: Review for test/placeholder services
- **Monthly**: Full audit of all services
- **Quarterly**: Verify pricing and duration accuracy

## Files Modified

1. `apps/admin_panel/src/app/(admin)/services/page.tsx`
   - Added invalid service detection
   - Added cleanup functionality
   - Added visual indicators for invalid services
   - Added delete button for individual services

2. `scripts/cleanup-services.js`
   - Standalone cleanup script
   - Can be run independently
   - Provides detailed logging

## Summary

✅ Invalid services are automatically detected
✅ One-click cleanup from admin panel
✅ Visual indicators for invalid data
✅ Confirmation dialog prevents accidents
✅ Automatic refresh after cleanup
✅ Detailed statistics and reporting

The service catalog is now clean and contains only valid, production-ready services!
