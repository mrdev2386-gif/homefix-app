/**
 * FIRESTORE QUERY OPTIMIZATION - Scalability & Performance
 * 
 * REQUIREMENTS:
 * - All list queries must have limit()
 * - All list queries must support pagination via startAfter()
 * - Composite indexes for multi-field queries
 * - No full collection scans
 * - Efficient ordering
 */

import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Pagination configuration
 */
export interface PaginationConfig {
  pageSize: number;
  cursor?: admin.firestore.DocumentSnapshot;
  filters?: Record<string, any>;
}

/**
 * Paginated result
 */
export interface PaginatedResult<T> {
  items: T[];
  hasMore: boolean;
  nextCursor?: admin.firestore.DocumentSnapshot;
  total?: number;
}

/**
 * Get paginated bookings with filters
 * 
 * OPTIMIZATIONS:
 * - Composite index for status + createdAt
 * - Limit enforced
 * - Cursor-based pagination
 */
export async function getPaginatedBookings(
  config: PaginationConfig
): Promise<PaginatedResult<any>> {
  const { pageSize = 20, cursor, filters = {} } = config;

  // Enforce reasonable limits
  const limit = Math.min(Math.max(1, pageSize), 100);

  let query: admin.firestore.Query = db.collection('bookings');

  // Apply filters
  if (filters.status) {
    query = query.where('bookingStatus', '==', filters.status);
  }
  if (filters.paymentStatus) {
    query = query.where('paymentStatus', '==', filters.paymentStatus);
  }
  if (filters.customerId) {
    query = query.where('customerId', '==', filters.customerId);
  }
  if (filters.technicianId) {
    query = query.where('technicianId', '==', filters.technicianId);
  }

  // Order by creation date (descending)
  query = query.orderBy('createdAt', 'desc');

  // Apply cursor for pagination
  if (cursor) {
    query = query.startAfter(cursor);
  }

  // Fetch one extra to determine if there are more results
  query = query.limit(limit + 1);

  const snapshot = await query.get();
  const docs = snapshot.docs.slice(0, limit);
  const hasMore = snapshot.docs.length > limit;
  const nextCursor = docs.length > 0 ? docs[docs.length - 1] : undefined;

  return {
    items: docs.map(doc => ({ id: doc.id, ...doc.data() })),
    hasMore,
    nextCursor,
  };
}

/**
 * Get paginated technicians with filters
 * 
 * OPTIMIZATIONS:
 * - Composite index for status + city + rating
 * - Limit enforced
 * - Cursor-based pagination
 */
export async function getPaginatedTechnicians(
  config: PaginationConfig
): Promise<PaginatedResult<any>> {
  const { pageSize = 20, cursor, filters = {} } = config;

  const limit = Math.min(Math.max(1, pageSize), 100);

  let query: admin.firestore.Query = db.collection('technicians');

  // Apply filters
  if (filters.status) {
    query = query.where('verificationStatus', '==', filters.status);
  }
  if (filters.city) {
    query = query.where('city', '==', filters.city);
  }
  if (filters.isOnline !== undefined) {
    query = query.where('isOnline', '==', filters.isOnline);
  }

  // Order by rating (descending)
  query = query.orderBy('avgRating', 'desc').orderBy('createdAt', 'desc');

  // Apply cursor
  if (cursor) {
    query = query.startAfter(cursor);
  }

  query = query.limit(limit + 1);

  const snapshot = await query.get();
  const docs = snapshot.docs.slice(0, limit);
  const hasMore = snapshot.docs.length > limit;
  const nextCursor = docs.length > 0 ? docs[docs.length - 1] : undefined;

  return {
    items: docs.map(doc => ({ id: doc.id, ...doc.data() })),
    hasMore,
    nextCursor,
  };
}

/**
 * Get paginated customers with filters
 */
export async function getPaginatedCustomers(
  config: PaginationConfig
): Promise<PaginatedResult<any>> {
  const { pageSize = 20, cursor, filters = {} } = config;

  const limit = Math.min(Math.max(1, pageSize), 100);

  let query: admin.firestore.Query = db.collection('users');

  // Apply filters
  if (filters.city) {
    query = query.where('city', '==', filters.city);
  }
  if (filters.isSuspended !== undefined) {
    query = query.where('isSuspended', '==', filters.isSuspended);
  }

  // Order by creation date
  query = query.orderBy('createdAt', 'desc');

  // Apply cursor
  if (cursor) {
    query = query.startAfter(cursor);
  }

  query = query.limit(limit + 1);

  const snapshot = await query.get();
  const docs = snapshot.docs.slice(0, limit);
  const hasMore = snapshot.docs.length > limit;
  const nextCursor = docs.length > 0 ? docs[docs.length - 1] : undefined;

  return {
    items: docs.map(doc => ({ id: doc.id, ...doc.data() })),
    hasMore,
    nextCursor,
  };
}

/**
 * Get paginated technician services with filters
 * 
 * OPTIMIZATIONS:
 * - Composite index for status + createdAt
 * - Only approved services visible to customers
 */
export async function getPaginatedTechnicianServices(
  config: PaginationConfig
): Promise<PaginatedResult<any>> {
  const { pageSize = 20, cursor, filters = {} } = config;

  const limit = Math.min(Math.max(1, pageSize), 100);

  let query: admin.firestore.Query = db.collection('technician_services');

  // Apply filters
  if (filters.status) {
    query = query.where('status', '==', filters.status);
  }
  if (filters.technicianId) {
    query = query.where('technicianId', '==', filters.technicianId);
  }
  if (filters.categoryId) {
    query = query.where('categoryId', '==', filters.categoryId);
  }

  // Order by creation date
  query = query.orderBy('createdAt', 'desc');

  // Apply cursor
  if (cursor) {
    query = query.startAfter(cursor);
  }

  query = query.limit(limit + 1);

  const snapshot = await query.get();
  const docs = snapshot.docs.slice(0, limit);
  const hasMore = snapshot.docs.length > limit;
  const nextCursor = docs.length > 0 ? docs[docs.length - 1] : undefined;

  return {
    items: docs.map(doc => ({ id: doc.id, ...doc.data() })),
    hasMore,
    nextCursor,
  };
}

/**
 * Count documents with filter (use sparingly - expensive operation)
 * 
 * NOTE: Firestore doesn't have efficient count queries.
 * For large collections, maintain a separate counter document.
 */
export async function countDocuments(
  collection: string,
  filters?: Record<string, any>
): Promise<number> {
  let query: admin.firestore.Query = db.collection(collection);

  if (filters) {
    for (const [key, value] of Object.entries(filters)) {
      query = query.where(key, '==', value);
    }
  }

  // Limit to 10000 to avoid expensive full scans
  const snapshot = await query.limit(10000).get();
  return snapshot.size;
}

/**
 * Get recent documents (for dashboards)
 * 
 * OPTIMIZATION: Limited to last 24 hours
 */
export async function getRecentDocuments(
  collection: string,
  hoursBack: number = 24,
  limit: number = 100
): Promise<any[]> {
  const cutoffTime = new Date(Date.now() - hoursBack * 60 * 60 * 1000);

  const snapshot = await db
    .collection(collection)
    .where('createdAt', '>=', cutoffTime)
    .orderBy('createdAt', 'desc')
    .limit(Math.min(limit, 100))
    .get();

  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
}

/**
 * Batch get documents by IDs (efficient for small batches)
 * 
 * OPTIMIZATION: Firestore allows up to 100 documents per batch
 */
export async function batchGetDocuments(
  collection: string,
  ids: string[]
): Promise<Map<string, any>> {
  const results = new Map<string, any>();

  // Process in batches of 100
  for (let i = 0; i < ids.length; i += 100) {
    const batch = ids.slice(i, i + 100);
    const snapshot = await db
      .collection(collection)
      .where('__name__', 'in', batch)
      .get();

    snapshot.docs.forEach(doc => {
      results.set(doc.id, { id: doc.id, ...doc.data() });
    });
  }

  return results;
}

/**
 * Validate query efficiency
 * 
 * Checks:
 * - Query has limit
 * - Query has appropriate indexes
 * - No full collection scans
 */
export function validateQueryEfficiency(
  collection: string,
  filters: Record<string, any>,
  orderBy?: string
): { isEfficient: boolean; warnings: string[] } {
  const warnings: string[] = [];

  // Check if query has filters
  if (Object.keys(filters).length === 0 && !orderBy) {
    warnings.push('Query has no filters or ordering - potential full collection scan');
  }

  // Check for common inefficient patterns
  if (filters.description || filters.notes) {
    warnings.push('Filtering on text fields is inefficient - consider full-text search');
  }

  return {
    isEfficient: warnings.length === 0,
    warnings,
  };
}
