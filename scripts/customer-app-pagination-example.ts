/**
 * STEP 6: Customer App Pagination Example
 * 
 * This shows how the customer app should query technician services
 * with pagination for optimal performance.
 */

import { 
  collection, 
  query, 
  where, 
  orderBy, 
  limit, 
  startAfter, 
  getDocs,
  DocumentSnapshot 
} from 'firebase/firestore';

// Customer App Service Query with Pagination
export class CustomerServiceQuery {
  private db: any; // Firestore instance
  private lastVisible: DocumentSnapshot | null = null;
  private hasMore = true;
  private readonly PAGE_SIZE = 20;

  constructor(db: any) {
    this.db = db;
  }

  /**
   * Load approved services with pagination
   * STEP 6: Customer app must paginate services
   */
  async loadServices(loadMore = false): Promise<{
    services: any[];
    hasMore: boolean;
    total: number;
  }> {
    try {
      if (!loadMore) {
        this.lastVisible = null;
        this.hasMore = true;
      }

      // PRODUCTION QUERY: Only approved services with pagination
      let servicesQuery = query(
        collection(this.db, "technician_services"),
        where("status", "==", "approved"),
        orderBy("createdAt", "desc"),
        limit(this.PAGE_SIZE)
      );

      // Add cursor for pagination
      if (loadMore && this.lastVisible) {
        servicesQuery = query(
          collection(this.db, "technician_services"),
          where("status", "==", "approved"),
          orderBy("createdAt", "desc"),
          startAfter(this.lastVisible),
          limit(this.PAGE_SIZE)
        );
      }

      const snapshot = await getDocs(servicesQuery);
      
      // Update pagination state
      if (snapshot.docs.length > 0) {
        this.lastVisible = snapshot.docs[snapshot.docs.length - 1];
        this.hasMore = snapshot.docs.length === this.PAGE_SIZE;
      } else {
        this.hasMore = false;
      }

      const services = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt?.toDate?.()?.toISOString()
      }));

      console.log(`[CUSTOMER_APP] Loaded ${services.length} approved services`);

      return {
        services,
        hasMore: this.hasMore,
        total: services.length
      };

    } catch (error) {
      console.error('[CUSTOMER_APP] Error loading services:', error);
      throw error;
    }
  }

  /**
   * Search services by district with pagination
   */
  async searchByDistrict(district: string, loadMore = false): Promise<{
    services: any[];
    hasMore: boolean;
  }> {
    try {
      if (!loadMore) {
        this.lastVisible = null;
        this.hasMore = true;
      }

      let servicesQuery = query(
        collection(this.db, "technician_services"),
        where("status", "==", "approved"),
        where("technicianDistrictNormalized", "==", district.toLowerCase().trim()),
        orderBy("createdAt", "desc"),
        limit(this.PAGE_SIZE)
      );

      if (loadMore && this.lastVisible) {
        servicesQuery = query(
          collection(this.db, "technician_services"),
          where("status", "==", "approved"),
          where("technicianDistrictNormalized", "==", district.toLowerCase().trim()),
          orderBy("createdAt", "desc"),
          startAfter(this.lastVisible),
          limit(this.PAGE_SIZE)
        );
      }

      const snapshot = await getDocs(servicesQuery);
      
      if (snapshot.docs.length > 0) {
        this.lastVisible = snapshot.docs[snapshot.docs.length - 1];
        this.hasMore = snapshot.docs.length === this.PAGE_SIZE;
      } else {
        this.hasMore = false;
      }

      const services = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      return {
        services,
        hasMore: this.hasMore
      };

    } catch (error) {
      console.error('[CUSTOMER_APP] Error searching services by district:', error);
      throw error;
    }
  }

  /**
   * Reset pagination state
   */
  reset() {
    this.lastVisible = null;
    this.hasMore = true;
  }
}

// Usage Example in Flutter/React Native:
/*
const serviceQuery = new CustomerServiceQuery(db);

// Initial load
const { services, hasMore } = await serviceQuery.loadServices();

// Load more
if (hasMore) {
  const { services: moreServices } = await serviceQuery.loadServices(true);
}

// Search by district
const { services: districtServices } = await serviceQuery.searchByDistrict('Mumbai');
*/

export default CustomerServiceQuery;