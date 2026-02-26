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

const db = admin.firestore();

interface ServiceInput {
  name: string;
  price: number;
  imageUrl: string;
  category: string;
  description?: string;
}

interface UpdateServiceInput {
  serviceId: string;
  name?: string;
  price?: number;
  imageUrl?: string;
  category?: string;
  description?: string;
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
    const { name, price, imageUrl, category, description } = request.data;

    // Validation
    if (!name?.trim() || name.trim().length < 3) {
      throw new https.HttpsError("invalid-argument", "Service name must be at least 3 characters");
    }
    if (!price || price <= 0) {
      throw new https.HttpsError("invalid-argument", "Price must be greater than 0");
    }
    if (!imageUrl?.trim()) {
      throw new https.HttpsError("invalid-argument", "Image is required");
    }
    if (!category?.trim()) {
      throw new https.HttpsError("invalid-argument", "Category is required");
    }

    // CRITICAL: Fetch technician profile to get district
    const techDoc = await db.collection('technicians').doc(technicianId).get();
    if (!techDoc.exists) {
      throw new https.HttpsError("not-found", "Technician profile not found");
    }

    const techData = techDoc.data()!;
    const district = techData.district || techData.districtNormalized;

    if (!district) {
      throw new https.HttpsError(
        "failed-precondition",
        "Your profile must have a district set. Please update your profile."
      );
    }

    const serviceId = db.collection(`technicians/${technicianId}/services`).doc().id;
    const now = admin.firestore.Timestamp.now();

    const serviceData = {
      id: serviceId,
      name: name.trim(),
      price,
      imageUrl: imageUrl.trim(),
      category: category.trim(),
      description: description?.trim() || "",
      district: district, // SERVER-INJECTED
      averageRating: 0, // DEFAULT
      totalReviews: 0, // DEFAULT
      isActive: true,
      isDeleted: false,
      technicianId,
      createdAt: now,
      updatedAt: now,
    };

    await db.doc(`technicians/${technicianId}/services/${serviceId}`).set(serviceData);

    console.log(`[SERVICE_ADD] Service ${serviceId} created for technician ${technicianId} in district ${district}`);

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

    const serviceRef = db.doc(`technicians/${technicianId}/services/${serviceId}`);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    // Validation
    const updateData: any = { updatedAt: admin.firestore.Timestamp.now() };

    if (updates.name !== undefined) {
      if (!updates.name.trim() || updates.name.trim().length < 3) {
        throw new https.HttpsError("invalid-argument", "Service name must be at least 3 characters");
      }
      updateData.name = updates.name.trim();
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
      if (!updates.category.trim()) {
        throw new https.HttpsError("invalid-argument", "Category cannot be empty");
      }
      updateData.category = updates.category.trim();
    }

    if (updates.description !== undefined) {
      updateData.description = updates.description.trim();
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

    const serviceRef = db.doc(`technicians/${technicianId}/services/${serviceId}`);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
    }

    const currentStatus = serviceDoc.data()?.isActive ?? true;
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

    const serviceRef = db.doc(`technicians/${technicianId}/services/${serviceId}`);
    const serviceDoc = await serviceRef.get();

    if (!serviceDoc.exists) {
      throw new https.HttpsError("not-found", "Service not found");
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
