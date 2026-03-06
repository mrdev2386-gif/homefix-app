# Migrating Existing Pages to New UI

## 📋 Overview

This guide helps you update existing admin pages to use the new UI foundation components.

---

## 🎯 Migration Steps

### Step 1: Update Imports

**Before:**
```tsx
import { useState } from 'react';
```

**After:**
```tsx
'use client';

import { useState } from 'react';
import { PageHeader, StatCard, DataTable, StatusBadge, Column } from '@/components/ui';
```

---

### Step 2: Add Page Container

**Before:**
```tsx
export default function YourPage() {
  return (
    <div>
      <h1>Page Title</h1>
      {/* content */}
    </div>
  );
}
```

**After:**
```tsx
export default function YourPage() {
  return (
    <div className="space-y-6">
      <PageHeader title="Page Title" description="Optional description" />
      {/* content */}
    </div>
  );
}
```

---

### Step 3: Replace Custom Stats with StatCard

**Before:**
```tsx
<div className="grid grid-cols-4 gap-4">
  <div className="bg-white p-4 rounded">
    <h3>Total</h3>
    <p className="text-2xl">1,234</p>
  </div>
</div>
```

**After:**
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <StatCard
    title="Total"
    value="1,234"
    icon={Users}
    color="blue"
    trend={{ value: "+12%", isPositive: true }}
  />
</div>
```

---

### Step 4: Replace Custom Tables with DataTable

**Before:**
```tsx
<table>
  <thead>
    <tr>
      <th>ID</th>
      <th>Name</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    {items.map(item => (
      <tr key={item.id}>
        <td>{item.id}</td>
        <td>{item.name}</td>
        <td>{item.status}</td>
      </tr>
    ))}
  </tbody>
</table>
```

**After:**
```tsx
const columns: Column[] = [
  { key: 'id', label: 'ID', sortable: true },
  { key: 'name', label: 'Name', sortable: true },
  {
    key: 'status',
    label: 'Status',
    render: (item) => <StatusBadge status={item.status} variant="success" />
  }
];

<DataTable
  columns={columns}
  data={items}
  loading={isLoading}
  pagination={{
    currentPage: page,
    totalPages: totalPages,
    onPageChange: setPage
  }}
/>
```

---

### Step 5: Replace Status Indicators with StatusBadge

**Before:**
```tsx
<span className={`px-2 py-1 rounded ${
  status === 'approved' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
}`}>
  {status}
</span>
```

**After:**
```tsx
<StatusBadge 
  status={status} 
  variant={status === 'approved' ? 'success' : 'error'} 
/>
```

---

### Step 6: Update Card Styling

**Before:**
```tsx
<div className="bg-white p-4 rounded shadow">
  <h3>Section Title</h3>
  {/* content */}
</div>
```

**After:**
```tsx
<div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">
  <h3 className="text-lg font-semibold text-gray-900 mb-4">Section Title</h3>
  {/* content */}
</div>
```

---

## 📄 Page-by-Page Migration

### Dashboard Page ✅
- Status: **Complete**
- File: `app/(admin)/dashboard/page.tsx`
- Changes: Added StatCards, updated layout

### Bookings Page
- Status: **Pending**
- File: `app/(admin)/bookings/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for booking metrics
  3. Replace table with DataTable
  4. Use StatusBadge for booking status

**Example:**
```tsx
'use client';

import { PageHeader, StatCard, DataTable, StatusBadge, Column } from '@/components/ui';
import { Calendar, Clock, CheckCircle, XCircle } from 'lucide-react';

export default function BookingsPage() {
  const columns: Column[] = [
    { key: 'id', label: 'Booking ID', sortable: true },
    { key: 'customer', label: 'Customer', sortable: true },
    { key: 'service', label: 'Service' },
    {
      key: 'status',
      label: 'Status',
      render: (item) => {
        const variantMap = {
          completed: 'success',
          pending: 'warning',
          cancelled: 'error',
        };
        return <StatusBadge status={item.status} variant={variantMap[item.status]} />;
      }
    },
    { key: 'date', label: 'Date' },
    { key: 'amount', label: 'Amount', align: 'right' },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Bookings" description="Manage all customer bookings" />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Total Bookings" value="456" icon={Calendar} color="blue" />
        <StatCard title="Completed" value="389" icon={CheckCircle} color="green" />
        <StatCard title="Pending" value="23" icon={Clock} color="orange" />
        <StatCard title="Cancelled" value="44" icon={XCircle} color="red" />
      </div>

      <DataTable columns={columns} data={bookings} loading={loading} />
    </div>
  );
}
```

---

### Custom Requests Page
- Status: **Pending**
- File: `app/(admin)/custom-requests/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for request metrics
  3. Replace table with DataTable
  4. Use StatusBadge for request status

---

### Technician Applications Page
- Status: **Pending**
- File: `app/(admin)/applications/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for application metrics
  3. Replace table with DataTable
  4. Use StatusBadge for application status
  5. Add action buttons for approve/reject

---

### Technicians Page
- Status: **Pending**
- File: `app/(admin)/technicians/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for technician metrics
  3. Replace table with DataTable
  4. Use StatusBadge for technician status

---

### Customers Page
- Status: **Pending**
- File: `app/(admin)/customers/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for customer metrics
  3. Replace table with DataTable
  4. Use StatusBadge for customer status

---

### Services Page
- Status: **Pending**
- File: `app/(admin)/services/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for service metrics
  3. Replace table with DataTable
  4. Use StatusBadge for service status

---

### Reviews Page
- Status: **Pending**
- File: `app/(admin)/reviews/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for review metrics
  3. Replace table with DataTable
  4. Add star rating display

---

### Disputes Page
- Status: **Pending**
- File: `app/(admin)/disputes/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for dispute metrics
  3. Replace table with DataTable
  4. Use StatusBadge for dispute status

---

### Risk Page
- Status: **Pending**
- File: `app/(admin)/risk/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for risk metrics
  3. Replace table with DataTable
  4. Use StatusBadge for risk levels

---

### Finance Page
- Status: **Pending**
- File: `app/(admin)/finance/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for financial metrics
  3. Add charts/graphs
  4. Replace tables with DataTable

---

### Booking Payouts Page
- Status: **Pending**
- File: `app/(admin)/finance/booking-payouts/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for payout metrics
  3. Replace table with DataTable
  4. Use StatusBadge for payout status

---

### Wallet Payouts Page
- Status: **Pending**
- File: `app/(admin)/finance/wallet-withdrawals/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Add StatCards for withdrawal metrics
  3. Replace table with DataTable
  4. Use StatusBadge for withdrawal status

---

### Audit Logs Page
- Status: **Pending**
- File: `app/(admin)/audit-logs/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Replace table with DataTable
  3. Add filters for log types

---

### Settings Page
- Status: **Pending**
- File: `app/(admin)/settings/page.tsx`
- Required Changes:
  1. Add PageHeader
  2. Use Card components for settings sections
  3. Update form styling

---

## 🎨 Common Patterns

### Pattern 1: List Page with Stats
```tsx
<div className="space-y-6">
  <PageHeader title="Title" />
  <StatsGrid />
  <DataTable />
</div>
```

### Pattern 2: Detail Page
```tsx
<div className="space-y-6">
  <PageHeader title="Detail" />
  <div className="grid grid-cols-2 gap-6">
    <Card>Info</Card>
    <Card>Actions</Card>
  </div>
</div>
```

### Pattern 3: Form Page
```tsx
<div className="space-y-6">
  <PageHeader title="Form" />
  <Card>
    <form>
      {/* form fields */}
    </form>
  </Card>
</div>
```

---

## ✅ Migration Checklist

For each page, ensure:

- [ ] Added `'use client';` directive
- [ ] Imported components from `@/components/ui`
- [ ] Wrapped content in `<div className="space-y-6">`
- [ ] Added `<PageHeader />` at top
- [ ] Replaced custom stats with `<StatCard />`
- [ ] Replaced custom tables with `<DataTable />`
- [ ] Replaced status indicators with `<StatusBadge />`
- [ ] Updated card styling to use consistent classes
- [ ] Used responsive grid layouts
- [ ] Tested on mobile and desktop
- [ ] Verified all functionality still works

---

## 🚀 Priority Order

1. **High Priority** (User-facing):
   - Dashboard ✅
   - Bookings
   - Technicians
   - Customers

2. **Medium Priority** (Admin operations):
   - Custom Requests
   - Technician Applications
   - Services
   - Reviews

3. **Low Priority** (Administrative):
   - Disputes
   - Risk
   - Finance pages
   - Audit Logs
   - Settings

---

## 💡 Tips

1. **Start with Dashboard** - Already done, use as reference
2. **One page at a time** - Don't try to migrate everything at once
3. **Test thoroughly** - Ensure all functionality works after migration
4. **Keep backend logic** - Only update UI components
5. **Use existing data** - Don't modify data fetching logic
6. **Follow patterns** - Use the templates provided
7. **Ask for help** - Refer to documentation when stuck

---

## 📚 Resources

- Full Guide: `ADMIN_UI_FOUNDATION.md`
- Quick Reference: `QUICK_REFERENCE.md`
- Visual Summary: `VISUAL_SUMMARY.md`
- Component Source: `src/components/ui/`

---

**Migration Guide Version**: 1.0.0
**Last Updated**: January 2025
