# HomeFix Admin Panel UI Foundation

## Overview

Modern, production-ready admin panel UI with a clean SaaS dashboard design. All components follow consistent design patterns with white backgrounds, soft shadows, and rounded corners.

---

## 🎨 Design System

### Colors
- **Primary**: Indigo (#4F46E5)
- **Background**: Gray-50 (#F9FAFB)
- **Card Background**: White
- **Border**: Gray-200
- **Text Primary**: Gray-900
- **Text Secondary**: Gray-600

### Spacing
- Container padding: `p-6`
- Card padding: `p-6`
- Section gaps: `space-y-6`

### Borders & Shadows
- Border radius: `rounded-xl` (12px)
- Border: `border border-gray-200`
- Shadow: `shadow-sm`

---

## 📁 Component Structure

```
components/
├── AdminLayout.tsx          # Main layout wrapper
├── Sidebar.tsx              # Navigation sidebar
├── Topbar.tsx               # Top header bar
└── ui/
    ├── StatCard.tsx         # Dashboard statistics
    ├── DataTable.tsx        # Enhanced data table
    ├── Table.tsx            # Base table component
    ├── StatusBadge.tsx      # Status indicators
    ├── PageHeader.tsx       # Page title + actions
    └── index.ts             # Exports
```

---

## 🧩 Core Components

### 1. AdminLayout

**Purpose**: Wraps all admin pages with sidebar and topbar

**Features**:
- Fixed sidebar with collapse support
- Sticky topbar
- Auto-detects page title from route
- Responsive layout

**Usage**:
```tsx
// Already applied in app/(admin)/layout.tsx
// All pages under (admin) automatically use this layout
```

**Page Title Mapping**:
The layout automatically sets page titles based on the current route:
- `/dashboard` → "Dashboard"
- `/bookings` → "Bookings"
- `/custom-requests` → "Custom Requests"
- etc.

---

### 2. Sidebar

**Features**:
- Fixed vertical navigation
- Collapsible (toggle via topbar menu button)
- Active page highlighting
- Icon-based navigation
- Smooth transitions

**Navigation Items**:
1. Dashboard
2. Bookings
3. Custom Requests
4. Technician Applications
5. Technicians
6. Customers
7. Services
8. Reviews
9. Disputes
10. Risk
11. Finance
12. Booking Payouts
13. Wallet Payouts
14. Audit Logs
15. Settings

**Styling**:
- Active: `bg-indigo-50 text-indigo-600`
- Hover: `hover:bg-gray-50`
- Collapsed width: `w-20`
- Expanded width: `w-64`

---

### 3. Topbar

**Features**:
- Sticky header
- Page title display
- Sidebar toggle button
- Notification bell with badge
- Admin profile dropdown

**Profile Dropdown**:
- Settings link
- Logout button

---

### 4. StatCard

**Purpose**: Display dashboard statistics

**Props**:
```tsx
interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  trend?: {
    value: string;
    isPositive: boolean;
  };
  color?: 'blue' | 'green' | 'orange' | 'red';
}
```

**Usage**:
```tsx
import { Users } from 'lucide-react';
import { StatCard } from '@/components/ui';

<StatCard
  title="Total Customers"
  value="1,234"
  icon={Users}
  color="blue"
  trend={{ value: "+12%", isPositive: true }}
/>
```

**Example Layout**:
```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <StatCard title="Total Bookings" value="456" icon={Calendar} color="blue" />
  <StatCard title="Active Technicians" value="89" icon={Users} color="green" />
  <StatCard title="Pending Requests" value="23" icon={Clock} color="orange" />
  <StatCard title="Revenue" value="₹45,678" icon={DollarSign} color="green" />
</div>
```

---

### 5. DataTable / Table

**Purpose**: Display tabular data with sorting and pagination

**Props**:
```tsx
interface Column {
  key: string;
  label: string;
  render?: (item: any, index: number) => React.ReactNode;
  sortable?: boolean;
  align?: 'left' | 'center' | 'right';
}

interface TableProps {
  columns: Column[];
  data: any[];
  loading?: boolean;
  pagination?: {
    currentPage: number;
    totalPages: number;
    onPageChange: (page: number) => void;
  };
  onSort?: (key: string) => void;
  sortConfig?: { key: string; direction: 'asc' | 'desc' };
  emptyMessage?: string;
}
```

**Usage**:
```tsx
import { DataTable, Column } from '@/components/ui';

const columns: Column[] = [
  { key: 'id', label: 'ID', sortable: true },
  { key: 'name', label: 'Name', sortable: true },
  { 
    key: 'status', 
    label: 'Status',
    render: (item) => <StatusBadge status={item.status} variant="success" />
  },
  {
    key: 'actions',
    label: 'Actions',
    align: 'right',
    render: (item) => (
      <button className="text-indigo-600 hover:text-indigo-800">
        View
      </button>
    )
  }
];

<DataTable
  columns={columns}
  data={bookings}
  loading={isLoading}
  pagination={{
    currentPage: 1,
    totalPages: 10,
    onPageChange: (page) => setPage(page)
  }}
/>
```

---

### 6. StatusBadge

**Purpose**: Display status indicators

**Props**:
```tsx
interface StatusBadgeProps {
  status: string;
  variant?: 'success' | 'warning' | 'error' | 'info' | 'default';
}
```

**Usage**:
```tsx
import { StatusBadge } from '@/components/ui';

<StatusBadge status="Approved" variant="success" />
<StatusBadge status="Pending" variant="warning" />
<StatusBadge status="Rejected" variant="error" />
<StatusBadge status="In Review" variant="info" />
```

**Variants**:
- `success`: Green (approved, completed, active)
- `warning`: Yellow (pending, in progress)
- `error`: Red (rejected, failed, cancelled)
- `info`: Blue (new, scheduled)
- `default`: Gray (inactive, draft)

---

### 7. PageHeader

**Purpose**: Consistent page titles with optional action buttons

**Props**:
```tsx
interface PageHeaderProps {
  title: string;
  description?: string;
  action?: ReactNode;
}
```

**Usage**:
```tsx
import { PageHeader } from '@/components/ui';
import { Button } from '@/components/ui';

<PageHeader
  title="Bookings"
  description="Manage all customer bookings"
  action={
    <Button>
      <Plus size={16} />
      New Booking
    </Button>
  }
/>
```

---

## 📄 Page Template

Here's a complete page template using all components:

```tsx
'use client';

import { useState } from 'react';
import { PageHeader, StatCard, DataTable, StatusBadge, Column } from '@/components/ui';
import { Calendar, Users, Clock, DollarSign } from 'lucide-react';

export default function BookingsPage() {
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(false);

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
        return (
          <StatusBadge 
            status={item.status} 
            variant={variantMap[item.status] || 'default'} 
          />
        );
      }
    },
    { key: 'amount', label: 'Amount', align: 'right' },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Bookings"
        description="Manage all customer bookings"
      />

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Total Bookings" value="456" icon={Calendar} color="blue" />
        <StatCard title="Completed" value="389" icon={Users} color="green" />
        <StatCard title="Pending" value="23" icon={Clock} color="orange" />
        <StatCard title="Revenue" value="₹45,678" icon={DollarSign} color="green" />
      </div>

      {/* Table */}
      <DataTable
        columns={columns}
        data={bookings}
        loading={loading}
        emptyMessage="No bookings found"
      />
    </div>
  );
}
```

---

## 🎯 Best Practices

### 1. Consistent Spacing
```tsx
// Page container
<div className="space-y-6">
  <PageHeader />
  <StatsGrid />
  <DataTable />
</div>
```

### 2. Grid Layouts
```tsx
// Responsive stats grid
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <StatCard />
  <StatCard />
  <StatCard />
  <StatCard />
</div>
```

### 3. Card Containers
```tsx
// White card with border
<div className="bg-white rounded-xl border border-gray-200 p-6">
  <h3 className="text-lg font-semibold mb-4">Section Title</h3>
  {/* Content */}
</div>
```

### 4. Action Buttons
```tsx
import { Button } from '@/components/ui';

// Primary action
<Button className="bg-indigo-600 hover:bg-indigo-700 text-white">
  Save Changes
</Button>

// Secondary action
<Button variant="outline">
  Cancel
</Button>
```

---

## 🚀 Quick Start

### Creating a New Admin Page

1. **Create page file**: `app/(admin)/your-page/page.tsx`

2. **Use the template**:
```tsx
'use client';

import { PageHeader } from '@/components/ui';

export default function YourPage() {
  return (
    <div className="space-y-6">
      <PageHeader title="Your Page" />
      {/* Your content */}
    </div>
  );
}
```

3. **Add to sidebar** (if needed): Edit `components/Sidebar.tsx`

4. **Add page title mapping**: Edit `components/AdminLayout.tsx`

---

## 📦 Component Exports

All UI components are exported from `@/components/ui`:

```tsx
import {
  StatCard,
  DataTable,
  Table,
  StatusBadge,
  PageHeader,
  Button,
  Card,
  Input,
  Badge,
  FilterBar,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  LoadingState,
} from '@/components/ui';
```

---

## 🎨 Tailwind Classes Reference

### Common Patterns

**Container**:
```tsx
className="space-y-6"
```

**Card**:
```tsx
className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm"
```

**Button Primary**:
```tsx
className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
```

**Button Secondary**:
```tsx
className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
```

**Text Heading**:
```tsx
className="text-2xl font-bold text-gray-900"
```

**Text Body**:
```tsx
className="text-sm text-gray-600"
```

---

## ✅ Implementation Checklist

- [x] AdminLayout component with sidebar and topbar
- [x] Sidebar with all navigation items
- [x] Topbar with notifications and profile dropdown
- [x] StatCard component for dashboard metrics
- [x] Table component with sorting and pagination
- [x] DataTable wrapper component
- [x] StatusBadge for status indicators
- [x] PageHeader for consistent page titles
- [x] Modern SaaS design with clean styling
- [x] Responsive layout support
- [x] Collapsible sidebar
- [x] Auto page title detection
- [x] Component documentation

---

## 🔄 Next Steps

1. **Implement page content**: Use the components to build actual admin pages
2. **Add data fetching**: Connect to Firebase/API
3. **Add filters**: Use FilterBar component for data filtering
4. **Add forms**: Create forms for data entry
5. **Add modals**: Use ConfirmDialog for confirmations
6. **Add loading states**: Use LoadingState component

---

## 📞 Support

For questions or issues with the UI components, refer to:
- Component source code in `components/` directory
- Existing page implementations in `app/(admin)/` directory
- This documentation file

---

**Last Updated**: 2024
**Version**: 1.0.0
