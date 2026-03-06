# Admin Panel UI - Quick Reference Card

## 🚀 Quick Start

### Import Components
```tsx
import { 
  PageHeader, 
  StatCard, 
  DataTable, 
  StatusBadge,
  Column 
} from '@/components/ui';
```

### Page Template
```tsx
'use client';

export default function YourPage() {
  return (
    <div className="space-y-6">
      <PageHeader title="Page Title" />
      {/* Your content */}
    </div>
  );
}
```

---

## 📦 Components

### PageHeader
```tsx
<PageHeader
  title="Bookings"
  description="Manage all bookings"
  action={<Button>New Booking</Button>}
/>
```

### StatCard
```tsx
<StatCard
  title="Total Users"
  value="1,234"
  icon={Users}
  color="blue"
  trend={{ value: "+12%", isPositive: true }}
/>
```

### DataTable
```tsx
const columns: Column[] = [
  { key: 'id', label: 'ID', sortable: true },
  { key: 'name', label: 'Name' },
  {
    key: 'status',
    label: 'Status',
    render: (item) => <StatusBadge status={item.status} variant="success" />
  }
];

<DataTable columns={columns} data={items} loading={false} />
```

### StatusBadge
```tsx
<StatusBadge status="Approved" variant="success" />
<StatusBadge status="Pending" variant="warning" />
<StatusBadge status="Rejected" variant="error" />
```

---

## 🎨 Common Layouts

### Stats Grid
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <StatCard />
  <StatCard />
  <StatCard />
  <StatCard />
</div>
```

### Two Column
```tsx
<div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
  <div className="bg-white rounded-xl border border-gray-200 p-6">
    {/* Left content */}
  </div>
  <div className="bg-white rounded-xl border border-gray-200 p-6">
    {/* Right content */}
  </div>
</div>
```

### Card Container
```tsx
<div className="bg-white rounded-xl border border-gray-200 p-6">
  <h3 className="text-lg font-semibold text-gray-900 mb-4">Title</h3>
  {/* Content */}
</div>
```

---

## 🎨 Styling Classes

### Container
```tsx
className="space-y-6"
```

### Card
```tsx
className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm"
```

### Button Primary
```tsx
className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
```

### Button Secondary
```tsx
className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
```

### Heading
```tsx
className="text-2xl font-bold text-gray-900"
```

### Body Text
```tsx
className="text-sm text-gray-600"
```

---

## 🎯 Status Badge Variants

| Variant | Use Case | Color |
|---------|----------|-------|
| `success` | Approved, Completed, Active | Green |
| `warning` | Pending, In Progress | Yellow |
| `error` | Rejected, Failed, Cancelled | Red |
| `info` | New, Scheduled | Blue |
| `default` | Inactive, Draft | Gray |

---

## 📊 StatCard Colors

| Color | Use Case |
|-------|----------|
| `blue` | General metrics, counts |
| `green` | Positive metrics, revenue |
| `orange` | Warnings, pending items |
| `red` | Errors, critical items |

---

## 🔗 Navigation Routes

| Route | Page Title |
|-------|-----------|
| `/dashboard` | Dashboard |
| `/bookings` | Bookings |
| `/custom-requests` | Custom Requests |
| `/applications` | Technician Applications |
| `/technicians` | Technicians |
| `/customers` | Customers |
| `/services` | Services |
| `/reviews` | Reviews |
| `/disputes` | Disputes |
| `/risk` | Risk Management |
| `/finance` | Finance Overview |
| `/finance/booking-payouts` | Booking Payouts |
| `/finance/wallet-withdrawals` | Wallet Payouts |
| `/audit-logs` | Audit Logs |
| `/settings` | Settings |

---

## 💡 Tips

1. **Always use `space-y-6`** for page containers
2. **Use grid layouts** for responsive design
3. **Import from `@/components/ui`** for all UI components
4. **Follow the page template** for consistency
5. **Use StatusBadge** for all status displays
6. **Use StatCard** for metrics
7. **Use DataTable** for all tables
8. **Use PageHeader** for all page titles

---

## 📚 Documentation

- Full Guide: `ADMIN_UI_FOUNDATION.md`
- Implementation Summary: `ADMIN_UI_IMPLEMENTATION_SUMMARY.md`
- Component Source: `src/components/ui/`

---

## ✅ Checklist for New Pages

- [ ] Create page in `app/(admin)/your-page/page.tsx`
- [ ] Add `'use client';` directive
- [ ] Import components from `@/components/ui`
- [ ] Use `<div className="space-y-6">` container
- [ ] Add `<PageHeader />` at top
- [ ] Use grid layouts for responsive design
- [ ] Follow consistent spacing (gap-6)
- [ ] Test on mobile and desktop

---

**Quick Access**: Keep this card handy while building admin pages!
