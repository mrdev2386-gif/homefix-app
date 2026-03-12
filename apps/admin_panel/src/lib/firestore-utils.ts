import { db } from './firebase';
import { collection, query, getDocs, limit, orderBy, where, Query, DocumentSnapshot, startAfter } from 'firebase/firestore';

/**
 * Optimized Firestore query utilities for admin panel
 * Prevents blocking navigation with pagination and lazy loading
 */

export interface PaginatedResult<T> {
  data: T[];
  lastVisible: DocumentSnapshot | null;
  hasMore: boolean;
  total: number;
}

/**
 * Fetch paginated data from Firestore
 * Returns immediately with first page, allows lazy loading of subsequent pages
 */
export async function fetchPaginated<T>(
  collectionName: string,
  pageSize: number = 20,
  constraints: any[] = [],
  orderByField: string = 'createdAt',
  orderDirection: 'asc' | 'desc' = 'desc',
  lastVisible?: DocumentSnapshot
): Promise<PaginatedResult<T>> {
  try {
    const q = query(
      collection(db, collectionName),
      ...constraints,
      orderBy(orderByField, orderDirection),
      limit(pageSize + 1),
      ...(lastVisible ? [startAfter(lastVisible)] : [])
    );

    const snapshot = await getDocs(q);
    const docs = snapshot.docs.slice(0, pageSize);
    const hasMore = snapshot.docs.length > pageSize;

    return {
      data: docs.map(doc => ({ id: doc.id, ...doc.data() } as T)),
      lastVisible: docs.length > 0 ? docs[docs.length - 1] : null,
      hasMore,
      total: snapshot.docs.length
    };
  } catch (error) {
    console.error(`Error fetching paginated data from ${collectionName}:`, error);
    return { data: [], lastVisible: null, hasMore: false, total: 0 };
  }
}

/**
 * Fetch single document with lazy resolution
 * Used for resolving related documents (technician, category, etc.)
 */
export async function fetchDocumentLazy<T>(
  collectionName: string,
  docId: string
): Promise<T | null> {
  try {
    const docRef = collection(db, collectionName);
    const q = query(docRef, where('__name__', '==', docId));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) return null;
    return { id: snapshot.docs[0].id, ...snapshot.docs[0].data() } as T;
  } catch (error) {
    console.error(`Error fetching document from ${collectionName}:`, error);
    return null;
  }
}

/**
 * Batch fetch multiple documents efficiently
 * Resolves all documents in parallel
 */
export async function batchFetchDocuments<T>(
  collectionName: string,
  docIds: string[]
): Promise<Map<string, T>> {
  const results = new Map<string, T>();
  
  try {
    const promises = docIds.map(id => fetchDocumentLazy<T>(collectionName, id));
    const docs = await Promise.all(promises);
    
    docIds.forEach((id, index) => {
      if (docs[index]) {
        results.set(id, docs[index]!);
      }
    });
  } catch (error) {
    console.error(`Error batch fetching documents from ${collectionName}:`, error);
  }
  
  return results;
}

/**
 * Get count of documents matching query
 * Lightweight operation for statistics
 */
export async function getDocumentCount(
  collectionName: string,
  constraints: any[] = []
): Promise<number> {
  try {
    const q = query(collection(db, collectionName), ...constraints);
    const snapshot = await getDocs(q);
    return snapshot.size;
  } catch (error) {
    console.error(`Error getting document count from ${collectionName}:`, error);
    return 0;
  }
}
