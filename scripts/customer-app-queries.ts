/**
 * Customer App Service Query Example
 * 
 * This shows how the customer app should query only approved services
 * from the technician_services collection
 */

import { collection, query, where, orderBy, getDocs } from 'firebase/firestore';
import { db } from './firebase'; // Your Firebase config

/**
 * Fetch approved technician services for customer app
 * Only shows services that have been approved by admin
 */
export async function getApprovedServices() {
  try {
    console.log('Fetching approved services for customer app...');
    
    // PRODUCTION-READY: Query only approved services
    const servicesQuery = query(
      collection(db, "technician_services"),
      where("status", "==", "approved"),
      orderBy("createdAt", "desc")
    );
    
    const snapshot = await getDocs(servicesQuery);
    console.log(`Found ${snapshot.size} approved services`);
    
    const services = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    return services;
    
  } catch (error) {
    console.error('Error fetching approved services:', error);
    throw error;
  }
}

/**
 * Fetch approved services by technician for profile page
 */
export async function getApprovedServicesByTechnician(technicianId: string) {
  try {
    const servicesQuery = query(
      collection(db, "technician_services"),
      where("technicianId", "==", technicianId),
      where("status", "==", "approved"),
      orderBy("createdAt", "desc")
    );
    
    const snapshot = await getDocs(servicesQuery);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
  } catch (error) {
    console.error('Error fetching technician services:', error);
    throw error;
  }
}