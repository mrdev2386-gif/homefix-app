/**
 * Technician Services Management - Production Ready
 * 
 * ARCHITECTURE:
 * - Single Source of Truth: technicians/{technicianId}/services/{serviceId}
 * - ALL writes via Cloud Functions (no direct Firestore writes)
 * - District auto-injected from technician profile (server-side)
 * - Customer App reads via collection group query filtered by district
 * - Server-side validation and security
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";
import { sanitizeString } from '../shared/security';

const db = admin.firestore();

// Total onboarding steps: basic, professional, kyc, portfolio
const TOTAL_ONBOARDING_STEPS = 4;

// Helper function to calculate profile completion from stepsCompleted
// NORMALIZED: Only count required steps: personalDetails, serviceCategories, portfolio, verification
function calculateProfileCompletion(technician: any): number {
  // SECURITY: Always calculate dynamically, never trust stored values
  
  const stepsCompleted = technician.stepsCompleted || {};
  let completedRequiredSteps = 0;
  const totalRequiredSteps = 4; // personalDetails, serviceCategories, portfolio, verification
  
  // Check required steps only - NORMALIZED FIELD NAMES
  if (stepsCompleted.personalDetails === true) {
    completedRequiredSteps++;
  }
  
  if (stepsCompleted.serviceCategories === true) {
    completedRequiredSteps++;
  }
  
  if (stepsCompleted.portfolio === true) {
    completedRequiredSteps++;
  }
  
  if (stepsCompleted.verification === true) {
    completedRequiredSteps++;
  }
  
  const completion = Math.round((completedRequiredSteps / totalRequiredSteps) * 100);
  console.log(`[PROFILE COMPLETION] Calculated: ${completion}% (${completedRequiredSteps}/${totalRequiredSteps})`);
  return completion;
}

interface ServiceInput {
  name: string;
  price: number;
  imageUrl: string;
  category: string;
  description?: string;
  // Urgent Booking Feature
  urgentBooking?: {
    enabled: boolean;
    arrivalTime?: string;
    urgentFee?: number;
  };
  // Night Service Feature
  nightService?: {
    enabled: boolean;
    nightCharge?: number;
  };
}

interface UpdateServiceInput {
  serviceId: string;
  name?: string;
  price?: number;
  imageUrl?: string;
  category?: string;
  description?: string;
  // Urgent Booking Feature
  urgentBooking?: {
    enabled?: boolean;
    arrivalTime?: string;
    urgentFee?: number;
  };
  // Night Service Feature
  nightService?: {
    enabled?: boolean;
    nightCharge?: number;
  };
}

/**
 * Add Technician Service
 * Creates service under technicians/{technicianId}/services/{serviceId}
 * DISTRICT-SAFE: District auto-injected from technician profile
 */
export const addTechnicianService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 60 },
  async (request: CallableRequest<ServiceInput>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    const technicianId = request.auth.uid;
    const { name, price, imageUrl, category, description, urgentBooking, nightService } = request.data;

    // SECURITY FIX: Sanitize inputs
    const sanitizedName = sanitizeString(name || '', 200);
    const sanitizedCategory = sanitizeString(category || '', 100);
    const sanitizedDescription = sanitizeString(description || '', 1000);

    // Validation
    if (!sanitizedName || sanitizedName.length < 3) {
      throw new https.HttpsError("invalid-argument", "Service name must be at least 3 characters");
    }
    if (!price || price <= 0) {
      throw new https.HttpsError("invalid-argument", "Price must be greater than 0");
    }
    if (!imageUrl?.trim()) {
      throw new https.HttpsError("invalid-argument", "Image is required");
    }
    if (!sanitizedCategory) {
      throw new https.HttpsError("invalid-argument", "Category is required");
    }

    // CRITICAL: Fetch technician profile to get district AND state AND validate approval
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
      throw new https.HttpsError("not-found", "Technician profile not found");
    }

    const techData = techDoc.data()!;
    
    // APPROVAL VALIDATION: Check profile completion and approval status
    const profileCompletion = calculateProfileCompletion(techData);
    
    console.log(`[TECH STATUS] ${techData.status}`);
    console.log(`[PROFILE COMPLETION] ${profileCompletion}`);
    console.log(`[SERVICE ALLOWED] ${techData.status === 'approved'}`);
    
    if (profileCompletion < 100) {
      throw new https.HttpsError(
        "failed-precondition",
        "Please complete your profile to 100% before listing services."
      );
    }
    
    // Use consistent approval check: status == "approved" ONLY
    const isApproved = techData.status === "approved";
    
    if (!isApproved) {
      if (techData.profileRejected) {
        throw new https.HttpsError(
          "failed-precondition",
          "Your profile was rejected. Please update your information and resubmit."
        );
      }
      throw new https.HttpsError(
        "failed-precondition",
        "Complete profile and wait for admin approval."
      );
    }
    
    const district = techData.district || techData.districtNormalized;
    const state = techData.state || techData.stateNormalized;

    if (!district) {
      throw new https.HttpsError(
        "failed-precondition",
        "Your profile must have a district set. Please update your profile."
      );
    }
    
    if (!state) {
      throw new https.HttpsError(
        "failed-precondition",
        "Your profile must have a state set. Please update your profile."
      );
    }

    const serviceId = db.collection('technician_services').doc().id;
    const now = admin.firestore.Timestamp.now();

    // CRITICAL FIX: Services must start as PENDING for admin approval
    const serviceData: any = {
      id: serviceId,
      name: sanitizedName,
      price,
      imageUrl: imageUrl.trim(),
      category: sanitizedCategory,
      description: sanitizedDescription,
      district: district, // SERVER-INJECTED
      state: state, // SERVER-INJECTED (FIX #3)
      averageRating: techData.averageRating || 0, // FROM TECHNICIAN
      totalReviews: techData.totalReviews || 0, // FROM TECHNICIAN
      technicianName: techData.fullName || techData.name || 'Unknown',
      technicianPhoto: techData.profilePhoto || techData.photoUrl || '',
      status: 'pending', // CRITICAL: Requires admin approval
      isActive: false, // CRITICAL: Inactive until approved
      isDeleted: false,
      technicianId,
      createdAt: now,
      updatedAt: now,
    };

    // Add urgent booking configuration if provided
    if (urgentBooking) {
      serviceData.urgentBooking = {
        enabled: urgentBooking.enabled || false,
        arrivalTime: urgentBooking.arrivalTime || null,
        urgentFee: urgentBooking.urgentFee || 0,
      };
    } else {
      // Default structure for new services
      serviceData.urgentBooking = {
        enabled: false,
        arrivalTime: null,
        urgentFee: 0,
      };
    }

    // Add night service configuration if provided
    if (nightService) {
      serviceData.nightService = {
        enabled: nightService.enabled || false,
        nightCharge: nightService.nightCharge || 0,
      };
    } else {
      // Default structure for new services
      serviceData.nightService = {
        enabled: false,
        nightCharge: 0,
      };
    }

    await db.collection('technician_services').doc(serviceId).set(serviceData);

    // ENHANCED DEBUG LOGGING
    console.log(`[SERVICE_ADD] ✅ Service ${serviceId} created for technician ${technicianId}`);
    console.log(`[SERVICE_ADD] 📍 Location: ${district}, ${state}`);
    console.log(`[SERVICE_ADD] 📊 Status: ${serviceData.status}, isActive: ${serviceData.isActive}`);
    console.log(`[SERVICE_ADD] 📝 Document written to: technician_services/${serviceId}`);

    return {
      success: true,
      serviceId,
      message: "Service added successfully",
    };
  }
);

/**
 * Update Technician Service
 * Only owner can update
 * PROTECTED: Cannot update district, technicianId, or rating fields
 */
export const updateTechnicianService = onCall(
  { region: "us-central1", memory: "256MiB", timeoutSeconds: 60 },
  async (request: CallableRequest<UpdateServiceInput>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    const technicianId = request.auth.uid;
    const { serviceId, ...updates } = request.data;

    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    // Security check - only owner can update
    const serviceData = serviceDoc.data()!;
    if (serviceData.technicianId !== technicianId) {
      throw new https.HttpsError("permission-denied", "You can only update your own services");
    }

    // Validation
    const updateData: any = { updatedAt: admin.firestore.Timestamp.now() };

    if (updates.name !== undefined) {
      const sanitizedName = sanitizeString(updates.name, 200);
      if (!sanitizedName || sanitizedName.length < 3) {
        throw new https.HttpsError("invalid-argument", "Service name must be at least 3 characters");
      }
      updateData.name = sanitizedName;
    }

    if (updates.price !== undefined) {
      if (updates.price <= 0) {
        throw new https.HttpsError("invalid-argument", "Price must be greater than 0");
      }
      updateData.price = updates.price;
    }

    if (updates.imageUrl !== undefined) {
      if (!updates.imageUrl.trim()) {
        throw new https.HttpsError("invalid-argument", "Image is required");
      }
      updateData.imageUrl = updates.imageUrl.trim();
    }

    if (updates.category !== undefined) {
      const sanitizedCategory = sanitizeString(updates.category, 100);
      if (!sanitizedCategory) {
        throw new https.HttpsError("invalid-argument", "Category cannot be empty");
      }
      updateData.category = sanitizedCategory;
    }

    if (updates.description !== undefined) {
      updateData.description = sanitizeString(updates.description, 1000);
    }

    // Urgent Booking Feature updates
    if (updates.urgentBooking !== undefined) {
      updateData.urgentBooking = {
        enabled: updates.urgentBooking.enabled ?? false,
        arrivalTime: updates.urgentBooking.arrivalTime ?? null,
        urgentFee: updates.urgentBooking.urgentFee ?? 0,
      };
    }

    // Night Service Feature updates
    if (updates.nightService !== undefined) {
      updateData.nightService = {
        enabled: updates.nightService.enabled ?? false,
        nightCharge: updates.nightService.nightCharge ?? 0,
      };
    }

    // PROTECTED: Do NOT allow updates to:
    // - district (server-managed)
    // - technicianId (immutable)
    // - averageRating (calculated)
    // - totalReviews (calculated)

    await serviceRef.update(updateData);

    console.log(`[SERVICE_UPDATE] Service ${serviceId} updated for technician ${technicianId}`);

    return {
      success: true,
      serviceId,
      message: "Service updated successfully",
    };
  }
);

/**
 * Toggle Service Status
 * Flips isActive between true/false
 */
export const toggleTechnicianServiceStatus = onCall(
  { region: "us-central1", memory: "128MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    const technicianId = request.auth.uid;
    const { serviceId } = request.data;

    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    // Security check - only owner can toggle
    const serviceData = serviceDoc.data()!;
    if (serviceData.technicianId !== technicianId) {
      throw new https.HttpsError("permission-denied", "You can only toggle your own services");
    }

    const currentStatus = serviceData.isActive ?? true;
    const newStatus = !currentStatus;

    await serviceRef.update({
      isActive: newStatus,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`[SERVICE_TOGGLE] Service ${serviceId} toggled to ${newStatus}`);

    return {
      success: true,
      serviceId,
      isActive: newStatus,
      message: newStatus ? "Service activated" : "Service deactivated",
    };
  }
);

/**
 * Delete Service (Soft Delete)
 * Sets isDeleted = true, isActive = false
 */
export const deleteTechnicianService = onCall(
  { region: "us-central1", memory: "128MiB", timeoutSeconds: 30 },
  async (request: CallableRequest<{ serviceId: string }>) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Authentication required");
    }

    const technicianId = request.auth.uid;
    const { serviceId } = request.data;

    if (!serviceId) {
      throw new https.HttpsError("invalid-argument", "Service ID is required");
    }

    const serviceRef = db.collection('technician_services').doc(serviceId);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    // Security check - only owner can delete
    const serviceData = serviceDoc.data()!;
    if (serviceData.technicianId !== technicianId) {
      throw new https.HttpsError("permission-denied", "You can only delete your own services");
    }

    await serviceRef.update({
      isDeleted: true,
      isActive: false,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    console.log(`[SERVICE_DELETE] Service ${serviceId} soft deleted`);

    return {
      success: true,
      serviceId,
      message: "Service deleted successfully",
    };
  }
);
