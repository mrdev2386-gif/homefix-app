# Admin Pages Update Template - Copy & Paste Ready

## 🎯 PATTERN FOR ALL PAGES

Use this pattern to update all 12 remaining admin pages.

---

## TEMPLATE: Paginated Admin Page

```typescript
'use client';

import { useState, useEffect } from 'react';
import { PageHeader, DataTable, StatusBadge, Column } from '@/components/ui';
import { Search, X } from 'lucide-react';
import { db } from '@/lib/firebase';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit as firestoreLimit,
  getDocs,
  DocumentSnapshot
} from 'firebase/firestore';

interface PageItem {
  id: string;
  [key: string]: any;
}

interface PaginatedResult {
  docs: PageItem[];
  hasMore: boolean;
  nextCursor?: DocumentSnapshot;
}

export default function PageName() {
  const [items, setItems] = useState<PageItem[]>([])
  const [filteredItems, setFilteredItems] = useState<PageItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [lastCursor, setLastCursor] = useState<DocumentSnapshot | undefined>();
  const [hasMore, setHasMore] = useState(false);

  // Initial load
  useEffect(() => {
    fetchInitialData();
  }, []);

  // Filter when data or filters change
  useEffect(() => {
    filterItems();
  }, [items, searchTerm, statusFilter]);

  // Fetch first page
  const fetchInitialData = async () => {
    try {
      setLoading(true);
      const result = await getPaginatedItems(20, undefined, { status: statusFilter });
      setItems(result.docs);
      setLastCursor(result.nextCursor);
      setHasMore(result.hasMore);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Fetch next page
  const handleLoadMore = async () => {
    try {
      const result = await getPaginatedItems(20, lastCursor, { status: statusFilter });
      setItems([...items, ...result.docs]);
      setLastCursor(result.nextCursor);
      setHasMore(result.hasMore);
    } catch (error) {
      console.error('Error loading more:', error);
    }
  };

  // Filter items locally
  const filterItems = () => {
    let filtered = [...items];

    if (statusFilter !== 'all') {
      filtered = filtered.filter(item => item.status === statusFilter);
    }

    if (searchTerm) {
      filtered = filtered.filter(item =>
        item.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        item.id?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredItems(filtered);
  };

  // Define columns
  const columns: Column[] = [
    { 
      key: 'id', 
      label: 'ID',
      render: (item) => <span className="text-sm font-mono">{item.id.substring(0, 8)}</span>
    },
    { 
      key: 'name', 
      label: 'Name',
      render: (item) => <span className="text-sm">{item.name || 'N/A'}</span>
    },
    {
      key: 'status',
      label: 'Status',
      render: (item) => <StatusBadge status={item.status} variant="info" />
    },
    {
      key: 'actions',
      label: 'Actions',
      align: 'right',
      render: (item) => (
        <button className="px-3 py-1 text-xs bg-gray-100 rounded hover:bg-gray-200">
          View
        </button>
      )
    },
  ];

  return (
    <div className="space-y-6">
      <PageHeader title="Page Title" description="Page description" />

      {/* Filters */}
      <div className="bg-white rounded-lg border border-gray-200 p-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            {searchTerm && (
              <button onClick={() => setSearchTerm('')} className="absolute right-3 top-1/2 -translate-y-1/2">
                <X size={18} />
              </button>
            )}
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
          </select>

          <div className="flex items-center justify-end">
            <span className="text-sm text-gray-600">
              Showing {filteredItems.length} of {items.length}
            </span>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <DataTable 
          columns={columns} 
          data={filteredItems} 
          loading={loading} 
          emptyMessage="No items found" 
        />
      </div>

      {/* Load More */}
      {hasMore && (
        <div className="flex justify-center">
          <button
            onClick={handleLoadMore}
            className="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700"
          >
            Load More
          </button>
        </div>
      )}
    </div>
  );
}

// Pagination function
async function getPaginatedItems(
  pageSize: number = 20,
  cursor?: DocumentSnapshot,
  filters?: { status?: string }
): Promise<PaginatedResult> {
  try {
    const constraints = [
      orderBy('createdAt', 'desc'),
      firestoreLimit(pageSize + 1),
    ];

    if (filters?.status && filters.status !== 'all') {
      constraints.push(where('status', '==', filters.status));
    }

    if (cursor) {
      constraints.push(startAfter(cursor));
    }

    const q = query(collection(db, 'collectionName'), ...constraints);
    const snapshot = await getDocs(q);

    const docs = snapshot.docs.slice(0, pageSize).map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    const hasMore = snapshot.docs.length > pageSize;
    const nextCursor = docs.length > 0 ? snapshot.docs[pageSize] : undefined;

    return { docs, hasMore, nextCursor };
  } catch (error) {
    console.error('Error fetching paginated items:', error);
    throw error;
  }
}
```

---

## 📋 PAGES TO UPDATE & COLLECTION NAMES

| Page | File | Collection | Status Filter |
|------|------|-----------|---|
| Dashboard | `dashboard/page.tsx` | bookings | N/A |
| Bookings | `bookings/page.tsx` | bookings | status |
| Booking Approvals | `booking-approvals/page.tsx` | bookings | pending_admin |
| Custom Requests | `custom-requests/page.tsx` | custom_requests | status |
| Technicians | `technicians/page.tsx` | technicians | status |
| Technician Approvals | `technician-approvals/page.tsx` | technicians | pending |
| Service Approvals | `service-approvals/page.tsx` | services | pending |
| Applications | `applications/page.tsx` | technicianApplications | status |
| Customers | `customers/page.tsx` | users | N/A |
| Services | `services/page.tsx` | services | status |
| Reviews | `reviews/page.tsx` | reviews | N/A |
| Disputes | `disputes/page.tsx` | disputes | status |

---

## 🔄 QUICK UPDATE STEPS

For each page:

1. **Replace collection name**:
   ```typescript
   collection(db, 'collectionName') // ← Change this
   ```

2. **Update filters** (if needed):
   ```typescript
   if (filters?.status && filters.status !== 'all') {
     constraints.push(where('status', '==', filters.status));
   }
   ```

3. **Update columns** to match data structure

4. **Test locally** - verify <500ms load

---

## ✅ VERIFICATION

After updating each page:

```bash
# 1. Open DevTools Network tab
# 2. Click menu item
# 3. Check load time < 500ms
# 4. Check Firestore reads < 50
# 5. Verify data displays correctly
```

---

## 🚀 DEPLOYMENT

After all pages updated:

```bash
# 1. Test all pages locally
npm run dev

# 2. Build for production
npm run build

# 3. Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## 📊 EXPECTED RESULTS

✅ All pages load <500ms
✅ Firestore reads < 50 per page
✅ Memory usage < 100MB
✅ Smooth infinite scroll
✅ Responsive UI
✅ 95% cost reduction

---

**Time to Complete**: 2-3 hours
**Difficulty**: Easy (copy-paste template)
**Impact**: Critical performance improvement
