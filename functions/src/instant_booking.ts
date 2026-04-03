import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { secureCallable } from './shared/security';

const db = admin.firestore();

/**
 * Interface for instant service request
 */
interface InstantServiceRequest {
  city?: string;
  area?: string;
  latitude?: number;
  longitude?: number;
  categoryId?: string;
  availableNow?: boolean;
  sortBy?: 'nearest' | 'topRated' | 'lowestPrice';
  limit?: number;
  pageToken?: string;
}

/**
 * Interface for instant service DTO returned to client
 */
interface InstantServiceDTO {
  serviceId: string;
  serviceName: string;
  technicianId: string;
  technicianName: string;
  rating: number;
  reviewCount: number;
  priceStarting: number;
  imageUrl: string;
  estimatedArrivalMinutes: number;
  isVerified: boolean;
  distanceKm?: number;
}

/**
 * Interface for paginated response
 */
interface InstantServicesResponse {
  services: InstantServiceDTO[];
  nextPageToken: string | null;
}

/**
 * Valid availability status values
 */
const VALID_AVAILABILITY_STATUSES = ['online', 'offline', 'busy'];

/**
 * Get nearby available services for instant booking
 * 
 * This callable function:
 * 1. Verifies Firebase Auth
 * 2. Validates inputs
 * 3. Queries technicians/services with appropriate filters
 * 4. Returns lightweight DTOs (no heavy nested data)
 * 
 * NOTE: For "nearest" sort with true distance, Firestore requires
 * a composite index. For efficient distance sorting, consider using
 * Firebase Extensions for Geospatial queries or Algolia/Elasticsearch.
 */
export const getInstantServices = functions.region('asia-south1').https.onCall(
  secureCallable(async (data: InstantServiceRequest, context: functions.https.CallableContext): Promise<InstantServicesResponse> => {
  // 1. Verify Firebase Auth
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to access instant booking services'
    );
  }

  // 2. Validate and sanitize inputs
  const userId = context.auth.uid;
  const { 
    city, 
    area, 
    latitude, 
    longitude, 
    categoryId, 
    availableNow = false, 
    sortBy = 'nearest', 
    limit = 20, 
    pageToken 
  } = data;

  // Validate limit
  const validatedLimit = Math.min(Math.max(1, limit), 50);

  // 3. Build base query for technicians
  let query: admin.firestore.Query = db.collection('technicians')
    .where('isActive', '==', true)
    .where('isVerified', '==', true);

  // Apply city filter if provided and valid
  if (city && city.trim().length > 0) {
    query = query.where('city', '==', city.trim().toLowerCase());
  }

  // Apply availability filter with enum validation
  if (availableNow) {
    query = query.where('availabilityStatus', '==', 'online');
  }

  // Check if we have valid geolocation for true nearest sort
  const hasValidGeolocation = latitude != null && longitude != null 
    && !isNaN(latitude) && !isNaN(longitude)
    && latitude !== 0 && longitude !== 0;

  // 4. Apply sorting with proper order
  switch (sortBy) {
    case 'topRated':
      query = query.orderBy('rating', 'desc').orderBy('reviewCount', 'desc');
      break;
    case 'lowestPrice':
      query = query.orderBy('priceStarting', 'asc');
      break;
    case 'nearest':
    default:
      if (hasValidGeolocation) {
        // Use geohash-based ordering for efficiency
        // For true distance sorting, a composite index or external service is needed
        query = query.orderBy('geohash', 'asc');
      } else {
        // Fallback to city sort if no geolocation
        query = query.orderBy('city', 'asc').orderBy('rating', 'desc');
      }
      break;
  }

  // Apply pagination
  if (pageToken && pageToken.trim().length > 0) {
    try {
      const lastDoc = await db.collection('technicians').doc(pageToken).get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    } catch (e) {
      // Invalid cursor, ignore
    }
  }

  query = query.limit(validatedLimit);

  try {
    const technicianSnapshot = await query.get();

    if (technicianSnapshot.empty) {
      return {
        services: [],
        nextPageToken: null,
      };
    }

    // 5. Fetch service details for each technician
    const services: InstantServiceDTO[] = [];
    const technicianIds = technicianSnapshot.docs.map(doc => doc.id);

    // Batch fetch services for all technicians
    const servicesQuery = await db.collectionGroup('services')
      .where('technicianId', 'in', technicianIds.length > 0 ? technicianIds.slice(0, 10) : [])
      .where('isActive', '==', true)
      .get();

    // Create maps for efficient lookups
    const technicianDataMap = new Map<string, { data: admin.firestore.DocumentData; doc: admin.firestore.DocumentSnapshot }>();
    technicianSnapshot.docs.forEach(doc => {
      technicianDataMap.set(doc.id, { data: doc.data(), doc });
    });

    // Track processed services
    const processedServiceIds = new Set<string>();

    for (const serviceDoc of servicesQuery.docs) {
      const serviceData = serviceDoc.data();
      const technicianId = serviceData.technicianId;

      // Skip if already processed
      if (processedServiceIds.has(serviceDoc.id)) continue;

      // Check category filter
      if (categoryId) {
        const parentCategoryRef = serviceDoc.ref.parent.parent;
        if (parentCategoryRef && parentCategoryRef.id !== categoryId) {
          continue;
        }
      }

      const technicianInfo = technicianDataMap.get(technicianId);
      if (!technicianInfo) continue;

      const technicianData = technicianInfo.data;

      // Calculate distance if geolocation available
      let distanceKm: number | undefined;
      if (hasValidGeolocation && technicianData.lastKnownLatitude && technicianData.lastKnownLongitude) {
        distanceKm = _calculateDistance(
          latitude!,
          longitude!,
          technicianData.lastKnownLatitude,
          technicianData.lastKnownLongitude
        );
        
        // Optional: Filter by radius
        const MAX_RADIUS_KM = 30;
        if (distanceKm > MAX_RADIUS_KM) {
          continue; // Skip if outside radius
        }
      }

      // Build DTO - only return required fields, no heavy nested data
      const dto: InstantServiceDTO = {
        serviceId: serviceDoc.id,
        serviceName: serviceData.name || serviceData.title || 'Service',
        technicianId: technicianId,
        technicianName: technicianData.name || 'Technician',
        rating: _safeParseNumber(technicianData.rating, 0),
        reviewCount: _safeParseNumber(technicianData.reviewCount, 0),
        priceStarting: _safeParseNumber(serviceData.priceStarting || serviceData.price, 0),
        imageUrl: serviceData.imageUrl || serviceData.image || '',
        estimatedArrivalMinutes: _calculateEstimatedArrival(technicianData, latitude, longitude),
        isVerified: technicianData.isVerified === true,
        distanceKm: distanceKm,
      };

      services.push(dto);
      processedServiceIds.add(serviceDoc.id);
    }

    // 6. Final client-side sort for nearest (distance-based)
    let sortedServices = services;
    if (sortBy === 'nearest' && hasValidGeolocation) {
      sortedServices = services.sort((a, b) => {
        const distA = a.distanceKm ?? Infinity;
        const distB = b.distanceKm ?? Infinity;
        return distA - distB;
      });
    }

    // 7. Get next page token
    const lastTechnicianDoc = technicianSnapshot.docs[technicianSnapshot.docs.length - 1];
    const nextPageToken = technicianSnapshot.docs.length === validatedLimit 
      ? lastTechnicianDoc.id 
      : null;

    return {
      services: sortedServices,
      nextPageToken,
    };

  } catch (error) {
    functions.logger.error('Error fetching instant services:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to fetch instant services'
    );
  }
})
);

/**
 * Calculate estimated arrival time based on technician location
 */
function _calculateEstimatedArrival(
  technicianData: admin.firestore.DocumentData,
  customerLatitude?: number,
  customerLongitude?: number
): number {
  const defaultMinutes = 45;

  // Validate availability status with fallback
  const availabilityStatus = technicianData.availabilityStatus;
  if (!VALID_AVAILABILITY_STATUSES.includes(availabilityStatus)) {
    // Default to offline behavior if status is invalid
    return defaultMinutes;
  }

  // If technician is not online, return default
  if (availabilityStatus !== 'online') {
    return defaultMinutes;
  }

  // Calculate distance if geolocation data available
  if (customerLatitude != null && customerLongitude != null && 
      technicianData.lastKnownLatitude && technicianData.lastKnownLongitude) {
    const distance = _calculateDistance(
      customerLatitude,
      customerLongitude,
      technicianData.lastKnownLatitude,
      technicianData.lastKnownLongitude
    );

    // Assume average speed of 30 km/h in city
    // Add 10 minutes for preparation
    const estimatedMinutes = Math.round((distance / 30) * 60) + 10;

    // Cap at 60 minutes
    return Math.min(estimatedMinutes, 60);
  }

  return defaultMinutes;
}

/**
 * Calculate distance between two coordinates using Haversine formula
 */
function _calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth's radius in km
  const dLat = _toRad(lat2 - lat1);
  const dLon = _toRad(lon2 - lon1);
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(_toRad(lat1)) * Math.cos(_toRad(lat2)) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((R * c).toFixed(2)); // Return in km with 2 decimal places
}

function _toRad(deg: number): number {
  return deg * (Math.PI / 180);
}

/**
 * Safely parse a number from any type
 */
function _safeParseNumber(value: any, defaultValue: number): number {
  if (value == null) return defaultValue;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const parsed = parseFloat(value);
    return isNaN(parsed) ? defaultValue : parsed;
  }
  return defaultValue;
}
