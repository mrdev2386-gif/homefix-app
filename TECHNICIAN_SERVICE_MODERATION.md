# Technician Service Listings Moderation Panel

## Overview

The Services page has been converted into a **Technician Service Listings Moderation Panel** where admins review and approve technician-created service listings before they become visible in the customer app.

---

## Firestore Collection Structure

### Collection: `technician_services`

Each document represents a service listing created by a technician.

**Required Fields:**
```typescript
{
  id: string;                    // Auto-generated document ID
  technicianId: string;          // Reference to technician
  technicianName: string;        // Technician's name
  technicianPhone?: string;      // Technician's phone
  technicianRating?: number;     // Technician's rating (0-5)
  
  serviceId: string;             // Reference to service
  serviceName: string;           // Service name
  subServiceId: string;          // Reference to sub-service
  subServiceName: string;        // Sub-service name
  categoryId: string;            // Reference to category
  categoryName: string;          // Category name
  
  title: string;                 // Service listing title
  description?: string;          // Service description
  price: number;                 // Service price
  imageUrl?: string;             // Service image URL
  
  city?: string;                 // Technician's city
  district?: string;             // Technician's district
  
  status: 'pending' | 'approved' | 'rejected' | 'disabled';
  createdAt: Timestamp;          // Creation timestamp
}
```

---

## Moderation Status Flow

### Status Definitions

1. **pending** - Newly created service awaiting admin review
2. **approved** - Admin approved, visible in customer app
3. **rejected** - Admin rejected, not visible
4. **disabled** - Previously approved but now disabled by admin

### Status Transitions

```
Technician creates service → status = 'pending'
                                ↓
Admin reviews → Approve → status = 'approved' (visible in customer app)
             → Reject  → status = 'rejected' (not visible)
                                ↓
Admin can disable → status = 'disabled' (no longer visible)
```

---

## Features Implemented

### 1. Statistics Dashboard
- **Total Listings**: All service listings count
- **Pending Approval**: Services awaiting review
- **Approved Listings**: Active services visible to customers
- **Disabled Listings**: Previously approved but now disabled

### 2. Advanced Filters
- **Status Filter**: All / Pending / Approved / Rejected / Disabled
- **Category Filter**: Filter by service category
- **Search by Title**: Find services by title
- **Search by Technician**: Find services by technician name
- **Clear Filters**: Reset all filters at once

### 3. Service Listings Table

**Columns:**
- Service Image (thumbnail)
- Service Title + Sub Service
- Category
- Service
- Technician Name + Rating
- City / District
- Price
- Created Date
- Status Badge
- Actions (View, Approve, Reject, Disable, Delete)

### 4. Service Details Modal

**Displays:**
- Full service image
- Complete service information
- Category, Service, Sub Service
- Description
- Price
- Technician details (Name, Phone, Rating, Location)
- Created date
- Current status
- Action buttons (Approve/Reject/Disable/Delete)

### 5. Admin Actions

**Available Actions:**
- **View Details**: Opens modal with full service information
- **Approve**: Changes status from `pending` → `approved`
- **Reject**: Changes status from `pending` → `rejected`
- **Disable**: Changes status from `approved` → `disabled`
- **Delete**: Permanently removes the service listing

**Action Visibility:**
- Pending services show: Approve + Reject buttons
- Approved services show: Disable button
- All services show: View + Delete buttons

### 6. Confirmation Dialogs

All actions require confirmation:
- "Approve this service listing?"
- "Reject this service listing?"
- "Disable this service listing?"
- "Delete this service listing?" (danger variant)

### 7. Automatic Refresh

After any action (approve/reject/disable/delete), the table automatically refreshes to show updated data.

---

## Duplicate Prevention

**Rule**: A technician cannot create multiple identical services with the same:
- `technicianId`
- `serviceId`
- `subServiceId`

**Implementation**: This should be enforced in Firestore security rules or backend validation.

**Suggested Firestore Rule:**
```javascript
match /technician_services/{serviceId} {
  allow create: if request.auth != null 
    && !exists(/databases/$(database)/documents/technician_services/$(
      request.auth.uid + '_' + request.resource.data.serviceId + '_' + request.resource.data.subServiceId
    ));
}
```

---

## Customer App Integration

### Displaying Approved Services

In the customer app, only show services with `status === 'approved'`:

```dart
// Example Firestore query in Flutter
final approvedServices = await FirebaseFirestore.instance
  .collection('technician_services')
  .where('status', isEqualTo: 'approved')
  .where('district', isEqualTo: userDistrict) // Filter by location
  .get();
```

### Service Visibility Logic

```
Customer App Query:
  - status = 'approved'
  - district matches user's location
  - price > 0
  - Sort by: technicianRating (descending)
```

---

## UI Components Used

- **PageHeader**: Page title and description
- **StatCard**: Statistics cards with icons
- **DataTable**: Service listings table
- **StatusBadge**: Color-coded status indicators
- **Modal**: Service details popup
- **ConfirmDialog**: Action confirmation dialogs

---

## Design Guidelines

### Color Coding
- **Pending**: Blue (info)
- **Approved**: Green (success)
- **Rejected**: Red (error)
- **Disabled**: Orange (warning)

### Button Colors
- **Approve**: Green (`bg-green-600`)
- **Reject**: Red (`bg-red-600`)
- **Disable**: Orange (`bg-orange-600`)
- **Delete**: Red (`bg-red-600`)
- **View**: Gray (`bg-gray-100`)

### Responsive Layout
- Statistics: 1 column (mobile) → 4 columns (desktop)
- Filters: 1 column (mobile) → 2 columns (desktop)
- Table: Horizontal scroll on mobile

---

## Testing Checklist

### Admin Panel
- [ ] Statistics cards display correct counts
- [ ] Status filter works (All/Pending/Approved/Rejected/Disabled)
- [ ] Category filter works
- [ ] Search by title works
- [ ] Search by technician name works
- [ ] Clear filters resets all filters
- [ ] View Details modal opens with correct data
- [ ] Approve button changes status to 'approved'
- [ ] Reject button changes status to 'rejected'
- [ ] Disable button changes status to 'disabled'
- [ ] Delete button removes service
- [ ] Confirmation dialogs appear before actions
- [ ] Table refreshes after actions
- [ ] Service images display correctly
- [ ] Technician ratings display correctly

### Customer App Integration
- [ ] Only approved services are visible
- [ ] Services filtered by user's district
- [ ] Disabled services are hidden
- [ ] Rejected services are hidden
- [ ] Pending services are hidden

### Duplicate Prevention
- [ ] Technician cannot create duplicate service listings
- [ ] Error message shown when attempting duplicate

---

## Future Enhancements

1. **Bulk Actions**: Select multiple services and approve/reject at once
2. **Rejection Reasons**: Add reason field when rejecting services
3. **Edit Service**: Allow admin to edit service details before approval
4. **Notification System**: Notify technicians when their service is approved/rejected
5. **Analytics**: Track approval rates, average review time
6. **Auto-Approval**: Auto-approve services from highly-rated technicians
7. **Image Moderation**: AI-powered image content validation
8. **Price Validation**: Flag services with unusually high/low prices

---

## API Endpoints (Future Backend)

If you add a backend API, consider these endpoints:

```
GET    /api/admin/technician-services          - List all services
GET    /api/admin/technician-services/:id      - Get service details
PATCH  /api/admin/technician-services/:id      - Update service status
DELETE /api/admin/technician-services/:id      - Delete service
POST   /api/admin/technician-services/bulk     - Bulk approve/reject
```

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Technician Services
    match /technician_services/{serviceId} {
      // Technicians can create their own services
      allow create: if request.auth != null 
        && request.auth.uid == request.resource.data.technicianId
        && request.resource.data.status == 'pending';
      
      // Technicians can read their own services
      allow read: if request.auth != null 
        && request.auth.uid == resource.data.technicianId;
      
      // Admins can read/update/delete all services
      allow read, update, delete: if request.auth != null 
        && get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.role == 'admin';
      
      // Customers can only read approved services
      allow read: if request.auth != null 
        && resource.data.status == 'approved';
    }
  }
}
```

---

## Support

For issues or questions, contact: **9508322397**

---

## License

Proprietary - HomeFix © 2026
