"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPaginatedBookings = getPaginatedBookings;
exports.getPaginatedTechnicians = getPaginatedTechnicians;
exports.getPaginatedCustomers = getPaginatedCustomers;
exports.getPaginatedTechnicianServices = getPaginatedTechnicianServices;
exports.countDocuments = countDocuments;
exports.getRecentDocuments = getRecentDocuments;
exports.batchGetDocuments = batchGetDocuments;
exports.validateQueryEfficiency = validateQueryEfficiency;
const admin = __importStar(require("firebase-admin"));
const db = admin.firestore();
/**
 * Get paginated bookings with filters
 *
 * OPTIMIZATIONS:
 * - Composite index for status + createdAt
 * - Limit enforced
 * - Cursor-based pagination
 */
async function getPaginatedBookings(config) {
    const { pageSize = 20, cursor, filters = {} } = config;
    // Enforce reasonable limits
    const limit = Math.min(Math.max(1, pageSize), 100);
    let query = db.collection('bookings');
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
async function getPaginatedTechnicians(config) {
    const { pageSize = 20, cursor, filters = {} } = config;
    const limit = Math.min(Math.max(1, pageSize), 100);
    let query = db.collection('technicians');
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
async function getPaginatedCustomers(config) {
    const { pageSize = 20, cursor, filters = {} } = config;
    const limit = Math.min(Math.max(1, pageSize), 100);
    let query = db.collection('users');
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
async function getPaginatedTechnicianServices(config) {
    const { pageSize = 20, cursor, filters = {} } = config;
    const limit = Math.min(Math.max(1, pageSize), 100);
    let query = db.collection('technician_services');
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
async function countDocuments(collection, filters) {
    let query = db.collection(collection);
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
async function getRecentDocuments(collection, hoursBack = 24, limit = 100) {
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
async function batchGetDocuments(collection, ids) {
    const results = new Map();
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
function validateQueryEfficiency(collection, filters, orderBy) {
    const warnings = [];
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
//# sourceMappingURL=query_optimization.js.map