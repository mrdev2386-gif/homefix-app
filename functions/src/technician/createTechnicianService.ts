/**
 * Technician Service Creation Cloud Function
 * 
 * Creates a new service listing for a technician (YouTube-style service listing)
 * All writes go through this callable function with server-side validation
 * 
 * Collection: technician_services/{serviceId}
 */

import { onCall } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as https from "firebase-functions/v2/https";

const db = admin.firestore();

/**
 * Tag normalization for search optimization
 * - Lowercase
 * - Trim spaces
 * - Remove duplicates
 * - Max 10 tags
 * 
 * Debug log: [TECH_SERVICE_TAGS_NORMALIZED]
 */
function normalizeTags(tags: string[]): string[] {
    console.log(`[TECH_SERVICE_TAGS_NORMALIZE] Input tags: ${JSON.stringify(tags)}`);

    if (!tags || !Array.isArray(tags)) {
        console.log(`[TECH_SERVICE_TAGS_NORMALIZE] No tags provided, returning empty array`);
        return [];
    }

    // Normalize: lowercase, trim, filter empty
    const normalized = tags
        .map(tag => tag.toLowerCase().trim())
        .filter(tag => tag.length > 0);

    // Remove duplicates using Set
    const unique = [...new Set(normalized)];

    // Max 10 tags
    const limited = unique.slice(0, 10);

    console.log(`[TECH_SERVICE_TAGS_NORMALIZED] Output tags: ${JSON.stringify(limited)}`);
    return limited;
}

/**
 * Generate search keywords from service data for fast customer search
 * Combines and tokenizes from: title, tags, category name
 * 
 * Process:
 * - lowercase
 * - split by space
 * - remove duplicates
 * - remove words length < 2
 * - max 30 keywords
 * 
 * Debug log: [TECH_SERVICE_KEYWORDS_GENERATED]
 */
function generateSearchKeywords(
    title: string,
    tags: string[],
    categoryName?: string
): string[] {
    console.log(`[TECH_SERVICE_KEYWORDS_GENERATED] Generating keywords for: ${title}`);

    const keywords = new Set<string>();

    // Add title words
    if (title) {
        const titleWords = title.toLowerCase()
            .split(/\s+/)
            .filter(word => word.length >= 2);
        titleWords.forEach(word => keywords.add(word));
    }

    // Add tags
    if (tags && Array.isArray(tags)) {
        tags.forEach(tag => {
            const tagWords = tag.toLowerCase()
                .split(/\s+/)
                .filter(word => word.length >= 2);
            tagWords.forEach(word => keywords.add(word));
        });
    }

    // Add category name words
    if (categoryName) {
        const categoryWords = categoryName.toLowerCase()
            .split(/\s+/)
            .filter(word => word.length >= 2);
        categoryWords.forEach(word => keywords.add(word));
    }

    // Convert to array and limit to max 30
    const result = [...keywords].slice(0, 30);

    console.log(`[TECH_SERVICE_KEYWORDS_GENERATED] Generated ${result.length} keywords: ${JSON.stringify(result)}`);
    return result;
}

/**
 * Validate service input data with content quality guard
 * 
 * Quality rules:
 * - title length >= 5
 * - description length >= 20
 * - tags count <= 10
 * - no duplicate title by same technician (checked separately)
 * - no keyword stuffing (same tag repeated > 2 times)
 * - serviceId must exist if provided
 * - subServiceId must exist if provided
 * 
 * Debug log: [TECH_SERVICE_QUALITY_REJECT]
 */
async function validateServiceInput(data: any): Promise<{ valid: boolean; error?: string }> {
    // Required fields check
    if (!data.categoryId || typeof data.categoryId !== 'string') {
        return { valid: false, error: 'Category is required' };
    }

    // Validate serviceId if provided
    if (data.serviceId) {
        if (typeof data.serviceId !== 'string') {
            return { valid: false, error: 'Invalid serviceId format' };
        }
        
        try {
            const serviceDoc = await db.collection('services').doc(data.serviceId).get();
            if (!serviceDoc.exists) {
                return { valid: false, error: 'Service not found' };
            }
            
            const serviceData = serviceDoc.data();
            if (serviceData && serviceData.categoryId !== data.categoryId) {
                return { valid: false, error: 'Service does not belong to selected category' };
            }
            
            if (serviceData && serviceData.isActive === false) {
                return { valid: false, error: 'Service is not active' };
            }
        } catch (error) {
            console.error('[TECH_SERVICE] Error validating serviceId:', error);
            return { valid: false, error: 'Failed to validate service' };
        }
    }

    // Validate subServiceId if provided
    if (data.subServiceId) {
        if (typeof data.subServiceId !== 'string') {
            return { valid: false, error: 'Invalid subServiceId format' };
        }
        
        if (!data.serviceId) {
            return { valid: false, error: 'serviceId is required when subServiceId is provided' };
        }
        
        try {
            const subServiceDoc = await db
                .collection('services')
                .doc(data.serviceId)
                .collection('subServices')
                .doc(data.subServiceId)
                .get();
            
            if (!subServiceDoc.exists) {
                return { valid: false, error: 'SubService not found' };
            }
            
            const subServiceData = subServiceDoc.data();
            if (subServiceData && subServiceData.isActive === false) {
                return { valid: false, error: 'SubService is not active' };
            }
        } catch (error) {
            console.error('[TECH_SERVICE] Error validating subServiceId:', error);
            return { valid: false, error: 'Failed to validate subservice' };
        }
    }

    // Content Quality Guard: title length >= 5
    if (!data.title || typeof data.title !== 'string' || data.title.trim().length < 5) {
        console.log(`[TECH_SERVICE_QUALITY_REJECT] Title too short: ${data.title?.length || 0}`);
        return { valid: false, error: 'Title must be at least 5 characters' };
    }

    // Content Quality Guard: description length >= 20
    if (!data.description || typeof data.description !== 'string' || data.description.trim().length < 20) {
        console.log(`[TECH_SERVICE_QUALITY_REJECT] Description too short: ${data.description?.length || 0}`);
        return { valid: false, error: 'Description must be at least 20 characters' };
    }

    // Content Quality Guard: tags count <= 10
    if (data.tags && Array.isArray(data.tags) && data.tags.length > 10) {
        console.log(`[TECH_SERVICE_QUALITY_REJECT] Too many tags: ${data.tags.length}`);
        return { valid: false, error: 'Maximum 10 tags allowed' };
    }

    // Content Quality Guard: keyword stuffing detection (same tag repeated > 2 times)
    if (data.tags && Array.isArray(data.tags)) {
        const tagCounts = new Map<string, number>();
        data.tags.forEach((tag: string) => {
            const normalizedTag = tag.toLowerCase().trim();
            tagCounts.set(normalizedTag, (tagCounts.get(normalizedTag) || 0) + 1);
        });

        for (const [tag, count] of tagCounts) {
            if (count > 2) {
                console.log(`[TECH_SERVICE_QUALITY_REJECT] Keyword stuffing detected: ${tag} repeated ${count} times`);
                return { valid: false, error: `Tag '${tag}' repeated too many times (max 2)` };
            }
        }
    }

    if (data.price === undefined || data.price === null || typeof data.price !== 'number') {
        return { valid: false, error: 'Price is required and must be a number' };
    }

    if (data.price <= 0) {
        return { valid: false, error: 'Price must be greater than 0' };
    }

    if (data.price > 1000000) {
        return { valid: false, error: 'Price exceeds maximum allowed value' };
    }

    if (data.durationMinutes === undefined || data.durationMinutes === null || typeof data.durationMinutes !== 'number') {
        return { valid: false, error: 'Duration is required' };
    }

    if (data.durationMinutes <= 0) {
        return { valid: false, error: 'Duration must be greater than 0' };
    }

    if (data.durationMinutes > 1440) {
        // Max 24 hours
        return { valid: false, error: 'Duration cannot exceed 24 hours (1440 minutes)' };
    }

    if (!data.imageUrl || typeof data.imageUrl !== 'string') {
        return { valid: false, error: 'Service image is required' };
    }

    // Validate image URL format
    if (!data.imageUrl.startsWith('http')) {
        return { valid: false, error: 'Invalid image URL format' };
    }

    // Validate square image requirement
    // Check for Firebase Storage URLs with dimensions or common square image patterns
    const isSquareImage = await verifySquareImage(data.imageUrl);
    if (!isSquareImage.valid) {
        return { valid: false, error: isSquareImage.error };
    }

    return { valid: true };
}

/**
 * Check for duplicate/spam services
 * Prevents technician from creating too many services in a short time
 */
async function checkDuplicateSpam(technicianId: string): Promise<{ allowed: boolean; error?: string }> {
    const now = admin.firestore.Timestamp.now();
    const oneHourAgo = new Date(now.toDate().getTime() - 60 * 60 * 1000);

    // Check for services created in the last hour
    const recentServices = await db.collection('technician_services')
        .where('technicianId', '==', technicianId)
        .where('createdAt', '>', admin.firestore.Timestamp.fromDate(oneHourAgo))
        .limit(5)
        .get();

    if (recentServices.size >= 5) {
        return {
            allowed: false,
            error: 'Too many services created. Please wait before creating more.'
        };
    }

    return { allowed: true };
}

/**
 * Check for duplicate title by same technician (case insensitive)
 * Part of content quality guard
 * 
 * Debug log: [TECH_SERVICE_QUALITY_REJECT]
 */
async function checkDuplicateTitle(
    technicianId: string,
    title: string
): Promise<{ allowed: boolean; error?: string }> {
    const normalizedTitle = title.toLowerCase().trim();

    // Check for existing active services with same title
    const existingServices = await db.collection('technician_services')
        .where('technicianId', '==', technicianId)
        .where('isActive', '==', true)
        .get();

    for (const doc of existingServices.docs) {
        const existingTitle = doc.data().title?.toLowerCase().trim();
        if (existingTitle === normalizedTitle) {
            console.log(`[TECH_SERVICE_QUALITY_REJECT] Duplicate title found: "${title}"`);
            return {
                allowed: false,
                error: 'You already have a service with this title. Please use a different title.'
            };
        }
    }

    return { allowed: true };
}

/**
 * Verify category exists
 */
async function verifyCategory(categoryId: string): Promise<{ valid: boolean; error?: string }> {
    try {
        // Check category exists and is active
        const categoryDoc = await db.collection('categories').doc(categoryId).get();
        if (!categoryDoc.exists) {
            return { valid: false, error: 'Invalid category' };
        }

        const categoryData = categoryDoc.data();
        if (categoryData && categoryData.isActive === false) {
            return { valid: false, error: 'Category is not active' };
        }

        return { valid: true };
    } catch (error) {
        console.error('[TECH_SERVICE] Error verifying category:', error);
        return { valid: false, error: 'Failed to verify category' };
    }
}

/**
 * Verify image exists in Firebase Storage
 */
async function verifyImageExists(imageUrl: string): Promise<{ valid: boolean; error?: string }> {
    try {
        // Extract bucket and path from URL
        // Expected format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?token=...
        const urlMatch = imageUrl.match(/firebasestorage\.googleapis\.com\/.*\/b\/([^/]+)\/o\/([^?]+)/);

        if (!urlMatch) {
            // Not a Firebase Storage URL, allow it but log warning
            console.log('[TECH_SERVICE] Non-Firebase Storage URL:', imageUrl);
            return { valid: true };
        }

        const bucket = urlMatch[1];
        const encodedPath = urlMatch[2];
        const path = decodeURIComponent(encodedPath);

        // Check if file exists in storage
        const bucket_obj = admin.storage().bucket(bucket);
        const file = bucket_obj.file(path);

        const [exists] = await file.exists();
        if (!exists) {
            return { valid: false, error: 'Image file not found in storage' };
        }

        // Check file size
        const [metadata] = await file.getMetadata();
        const size = parseInt(String(metadata.size || '0'), 10);

        if (size > 10 * 1024 * 1024) {
            return { valid: false, error: 'Image file too large (max 10MB)' };
        }

        return { valid: true };
    } catch (error) {
        console.error('[TECH_SERVICE] Error verifying image:', error);
        // Don't block on verification errors, just log
        return { valid: true };
    }
}

/**
 * Verify image is square (aspect ratio 1:1)
 * Makes a HEAD request to get image dimensions
 */
async function verifySquareImage(imageUrl: string): Promise<{ valid: boolean; error?: string }> {
    try {
        // For Firebase Storage URLs, we can get metadata which includes contentLength
        // But for actual dimensions, we need to make a request
        // Using a lightweight approach - check if URL contains size parameters

        // Check for common Firebase Storage resize parameters that ensure square
        // Format: .../o/imageName?alt=media&width=500&height=500
        const hasSquareParams = /[?&](width|height)=(\d+)/i.test(imageUrl);

        if (hasSquareParams) {
            // Check if width equals height
            const widthMatch = imageUrl.match(/[?&]width=(\d+)/i);
            const heightMatch = imageUrl.match(/[?&]height=(\d+)/i);

            if (widthMatch && heightMatch) {
                const width = parseInt(widthMatch[1], 10);
                const height = parseInt(heightMatch[1], 10);

                if (width !== height) {
                    return { valid: false, error: 'Image must be square (width must equal height)' };
                }
            }
        }

        // For non-resize URLs, try to fetch image headers to verify dimensions
        // This is optional - we log a warning but allow it
        try {
            // Using fetch to get image headers (if the server supports HEAD)
            // Note: This may not work for all image hosting services
            const response = await fetch(imageUrl, { method: 'HEAD' });

            if (response.ok) {
                const contentType = response.headers.get('content-type') || '';
                if (!contentType.startsWith('image/')) {
                    return { valid: false, error: 'URL must point to an image file' };
                }

                // Try to get dimensions from custom headers (if set by image service)
                const imageWidth = response.headers.get('x-image-width') || response.headers.get('x-img-width');
                const imageHeight = response.headers.get('x-image-height') || response.headers.get('x-img-height');

                if (imageWidth && imageHeight) {
                    const width = parseInt(imageWidth, 10);
                    const height = parseInt(imageHeight, 10);

                    if (width !== height) {
                        return { valid: false, error: 'Image must be square (width must equal height)' };
                    }
                }
                // Note: Most image services don't provide dimension headers
                // In production, you might want to use an image processing service
                // or require specific upload patterns
            }
        } catch (fetchError) {
            // Allow if we can't verify - this is a best-effort check
            console.log('[TECH_SERVICE] Could not verify image dimensions:', fetchError);
        }

        console.log('[TECH_SERVICE] Square image validation: passed (best-effort)');
        return { valid: true };
    } catch (error) {
        console.error('[TECH_SERVICE] Error verifying square image:', error);
        // Allow for now but log warning
        return { valid: true };
    }
}

export interface TechnicianServiceData {
    categoryId: string;
    serviceId?: string;
    subServiceId?: string;
    title: string;
    description: string;
    tags?: string[];
    price: number;
    durationMinutes: number;
    imageUrl: string;
}

/**
 * Create Technician Service - Callable Cloud Function
 * 
 * This is the secure entry point for creating technician services.
 * All validation happens server-side.
 */
export const createTechnicianService = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 60,
        maxInstances: 5
    },
    async (request: CallableRequest<TechnicianServiceData>) => {
        // 1. Authentication check
        if (!request.auth) {
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated to create a service"
            );
        }

        const technicianId = request.auth.uid;
        const data = request.data;

        // 1.1 Check if technician is approved AND has admin approval for service management
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists) {
            throw new https.HttpsError(
                "not-found",
                "Technician profile not found"
            );
        }
        const techData = techDoc.data()!;

        // CRITICAL: Both isApproved AND adminApproved must be true for service management
        const isApproved = techData.isApproved || false;
        const adminApproved = techData.adminApproved || false;

        if (!isApproved || !adminApproved) {
            throw new https.HttpsError(
                "permission-denied",
                "You must be fully approved by admin to create services. Please wait for admin approval."
            );
        }

        console.log(`[TECH_SERVICE] Creating service for technician: ${technicianId}`);
        console.log(`[TECH_SERVICE] Input data: ${JSON.stringify({
            categoryId: data.categoryId,
            title: data.title?.substring(0, 50),
            price: data.price,
            durationMinutes: data.durationMinutes,
            imageUrl: data.imageUrl?.substring(0, 50),
            tags: data.tags
        })}`);

        // 2. Validate input data
        const validation = await validateServiceInput(data);
        if (!validation.valid) {
            console.log(`[TECH_SERVICE] Validation failed: ${validation.error}`);
            throw new https.HttpsError("invalid-argument", validation.error!);
        }

        // 3. Check for duplicate/spam
        const spamCheck = await checkDuplicateSpam(technicianId);
        if (!spamCheck.allowed) {
            console.log(`[TECH_SERVICE] Spam check failed: ${spamCheck.error}`);
            throw new https.HttpsError("resource-exhausted", spamCheck.error!);
        }

        // 4. Content Quality Guard: Check for duplicate title by same technician
        const titleCheck = await checkDuplicateTitle(technicianId, data.title);
        if (!titleCheck.allowed) {
            console.log(`[TECH_SERVICE] Duplicate title check failed: ${titleCheck.error}`);
            throw new https.HttpsError("invalid-argument", titleCheck.error!);
        }

        // 5. Verify category exists
        const categoryCheck = await verifyCategory(data.categoryId);
        if (!categoryCheck.valid) {
            console.log(`[TECH_SERVICE] Category verification failed: ${categoryCheck.error}`);
            throw new https.HttpsError("invalid-argument", categoryCheck.error!);
        }

        // 6. Verify image exists in storage
        const imageCheck = await verifyImageExists(data.imageUrl);
        if (!imageCheck.valid) {
            console.log(`[TECH_SERVICE] Image verification failed: ${imageCheck.error}`);
            throw new https.HttpsError("invalid-argument", imageCheck.error!);
        }

        // 7. Fetch category name for search keywords
        let categoryName = '';

        try {
            const categoryDoc = await db.collection('categories').doc(data.categoryId).get();
            if (categoryDoc.exists) {
                const categoryData = categoryDoc.data();
                categoryName = categoryData?.name || '';
            }
            console.log(`[TECH_SERVICE] Fetched category: "${categoryName}"`);
        } catch (error) {
            console.error('[TECH_SERVICE] Error fetching category name:', error);
            // Continue without category name - not a critical error
        }

        // 8. Normalize tags for search optimization
        const normalizedTags = normalizeTags(data.tags || []);

        // 9. Generate search keywords for fast customer search
        const searchKeywords = generateSearchKeywords(
            data.title,
            normalizedTags,
            categoryName
        );

        // 10. Discovery Score initialization for ranking engine
        // Future-ready fields for complex ranking formula
        const discoveryScoreData = {
            discoveryScore: 100, // Initial score
            ratingWeight: 0,     // Future: weight for rating
            popularityWeight: 0, // Future: weight for bookings count
            recencyWeight: 1     // Future: weight for service freshness
        };
        console.log(`[TECH_SERVICE_DISCOVERY_INIT] Discovery score initialized: ${discoveryScoreData.discoveryScore}`);

        // 11. Create the service document
        const serviceId = db.collection('technician_services').doc().id;
        const now = admin.firestore.Timestamp.now();

        const serviceData = {
            // IDs
            id: serviceId,
            technicianId: technicianId,
            technicianName: techData.name || 'Pro',
            technicianDistrict: techData.district || '',
            technicianDistrictNormalized: techData.districtNormalized || (techData.district ? techData.district.toString().trim().toLowerCase() : ''),
            technicianRating: techData.rating || 5.0,

            // Category & Service Hierarchy
            categoryId: data.categoryId,
            serviceId: data.serviceId || null,
            subServiceId: data.subServiceId || null,

            // Details
            title: data.title.trim(),
            description: data.description.trim(),
            tags: normalizedTags,

            // Search Index - for fast customer search
            // Query: .where('searchKeywords', arrayContains: searchTerm)
            // Note: For complex queries, consider composite index on searchKeywords + isActive
            searchKeywords: searchKeywords,

            // Discovery Score - for ranking engine
            // Initial value: 100
            // Future formula: discoveryScore = 100 + ratingWeight + popularityWeight + recencyWeight
            discoveryScore: discoveryScoreData.discoveryScore,
            ratingWeight: discoveryScoreData.ratingWeight,
            popularityWeight: discoveryScoreData.popularityWeight,
            recencyWeight: discoveryScoreData.recencyWeight,

            // Pricing & Duration
            price: data.price,
            durationMinutes: data.durationMinutes,

            // Media
            imageUrl: data.imageUrl,

            // Status
            isActive: true,
            isPublished: true, // Default to true per "Technician adds service -> appears on home"
            technicianApproved: techData.isApproved || false,
            status: 'active',

            // Timestamps
            createdAt: now,
            updatedAt: now,

            // Metadata
            _createdBy: technicianId,
            _version: 1
        };

        // 8. Save to Firestore
        await db.collection('technician_services').doc(serviceId).set(serviceData);

        console.log(`[TECH_SERVICE] Service created successfully: ${serviceId}`);

        // 9. Return success with service ID
        return {
            success: true,
            serviceId: serviceId,
            message: 'Service created successfully',
            data: {
                id: serviceId,
                title: serviceData.title,
                imageUrl: serviceData.imageUrl,
                price: serviceData.price,
                isActive: true,
                createdAt: now.toDate().toISOString()
            }
        };
    }
);

/**
 * Update Technician Service
 * Allows technicians to update their own services
 */
export const updateTechnicianService = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 60,
        maxInstances: 5
    },
    async (request: CallableRequest<{
        serviceId: string;
        title?: string;
        description?: string;
        tags?: string[];
        price?: number;
        durationMinutes?: number;
        imageUrl?: string;
        masterServiceId?: string;
        subServiceId?: string;
    }>) => {
        // 1. Authentication check
        if (!request.auth) {
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated to update a service"
            );
        }

        const technicianId = request.auth.uid;
        const { serviceId, ...updates } = request.data;

        if (!serviceId) {
            throw new https.HttpsError("invalid-argument", "Service ID is required");
        }

        console.log(`[TECH_SERVICE] Updating service ${serviceId} for technician: ${technicianId}`);

        // 1.1 Check if technician has admin approval for service management
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists) {
            throw new https.HttpsError(
                "not-found",
                "Technician profile not found"
            );
        }
        const techData = techDoc.data()!;

        // CRITICAL: Both isApproved AND adminApproved must be true for service management
        const isApproved = techData.isApproved || false;
        const adminApproved = techData.adminApproved || false;

        if (!isApproved || !adminApproved) {
            throw new https.HttpsError(
                "permission-denied",
                "You must be fully approved by admin to update services. Please wait for admin approval."
            );
        }

        // 2. Get the existing service
        const serviceDoc = await db.collection('technician_services').doc(serviceId).get();

        if (!serviceDoc.exists) {
            throw new https.HttpsError("not-found", "Service not found");
        }

        const serviceData = serviceDoc.data()!;

        // 3. Security check - only owner can update
        if (serviceData.technicianId !== technicianId) {
            console.log(`[TECH_SERVICE] Unauthorized update attempt by ${technicianId}`);
            throw new https.HttpsError(
                "permission-denied",
                "You can only update your own services"
            );
        }

        // 4. Validate updates
        if (updates.title !== undefined) {
            if (typeof updates.title !== 'string' || updates.title.trim().length < 3) {
                throw new https.HttpsError("invalid-argument", "Title must be at least 3 characters");
            }
        }

        if (updates.description !== undefined) {
            if (typeof updates.description !== 'string' || updates.description.trim().length < 20) {
                throw new https.HttpsError("invalid-argument", "Description must be at least 20 characters");
            }
        }

        if (updates.price !== undefined) {
            if (typeof updates.price !== 'number' || updates.price <= 0) {
                throw new https.HttpsError("invalid-argument", "Price must be greater than 0");
            }
            if (updates.price > 1000000) {
                throw new https.HttpsError("invalid-argument", "Price exceeds maximum allowed value");
            }
        }

        if (updates.durationMinutes !== undefined) {
            if (typeof updates.durationMinutes !== 'number' || updates.durationMinutes <= 0) {
                throw new https.HttpsError("invalid-argument", "Duration must be greater than 0");
            }
            if (updates.durationMinutes > 1440) {
                throw new https.HttpsError("invalid-argument", "Duration cannot exceed 24 hours");
            }
        }

        // 5. Prepare update data
        const updateData: any = {
            updatedAt: admin.firestore.Timestamp.now(),
            _version: (serviceData._version || 1) + 1
        };

        if (updates.title !== undefined) updateData.title = updates.title.trim();
        if (updates.description !== undefined) updateData.description = updates.description.trim();
        if (updates.price !== undefined) updateData.price = updates.price;
        if (updates.durationMinutes !== undefined) updateData.durationMinutes = updates.durationMinutes;
        if (updates.imageUrl !== undefined) updateData.imageUrl = updates.imageUrl;
        if (updates.masterServiceId !== undefined) updateData.serviceId = updates.masterServiceId;
        if (updates.subServiceId !== undefined) updateData.subServiceId = updates.subServiceId;

        if (updates.tags !== undefined) {
            // Normalize tags for search
            updateData.tags = normalizeTags(updates.tags);
        }

        // Regenerate search keywords if title or tags changed
        const shouldUpdateKeywords =
            updates.title !== undefined ||
            updates.tags !== undefined;

        if (shouldUpdateKeywords) {
            const currentTitle = updates.title !== undefined ? updates.title : serviceData.title;
            const currentTags = updates.tags !== undefined ? normalizeTags(updates.tags) : serviceData.tags;
            // Get category info from existing service data
            const categoryId = serviceData.categoryId;

            let categoryName = '';

            try {
                const categoryDoc = await db.collection('categories').doc(categoryId).get();
                if (categoryDoc.exists) {
                    const categoryData = categoryDoc.data();
                    categoryName = categoryData?.name || '';
                }
            } catch (error) {
                console.error('[TECH_SERVICE] Error fetching category name for update:', error);
            }

            updateData.searchKeywords = generateSearchKeywords(
                currentTitle,
                currentTags,
                categoryName
            );
            console.log(`[TECH_SERVICE_KEYWORDS_GENERATED] Keywords regenerated on update: ${updateData.searchKeywords.length} keywords`);
        }

        // 6. Update in Firestore
        await db.collection('technician_services').doc(serviceId).update(updateData);

        console.log(`[TECH_SERVICE] Service updated successfully: ${serviceId}`);

        return {
            success: true,
            serviceId: serviceId,
            message: 'Service updated successfully'
        };
    }
);

/**
 * Delete Technician Service
 * Allows technicians to delete their own services
 */
export const deleteTechnicianService = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "128MiB",
        timeoutSeconds: 30,
        maxInstances: 5
    },
    async (request: CallableRequest<{ serviceId: string }>) => {
        // 1. Authentication check
        if (!request.auth) {
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated to delete a service"
            );
        }

        const technicianId = request.auth.uid;
        const { serviceId } = request.data;

        if (!serviceId) {
            throw new https.HttpsError("invalid-argument", "Service ID is required");
        }

        console.log(`[TECH_SERVICE] Deleting service ${serviceId} for technician: ${technicianId}`);

        // 1.1 Check if technician has admin approval for service management
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists) {
            throw new https.HttpsError(
                "not-found",
                "Technician profile not found"
            );
        }
        const techData = techDoc.data()!;

        // CRITICAL: Both isApproved AND adminApproved must be true for service management
        const isApproved = techData.isApproved || false;
        const adminApproved = techData.adminApproved || false;

        if (!isApproved || !adminApproved) {
            throw new https.HttpsError(
                "permission-denied",
                "You must be fully approved by admin to delete services. Please wait for admin approval."
            );
        }

        // 2. Get the existing service
        const serviceDoc = await db.collection('technician_services').doc(serviceId).get();

        if (!serviceDoc.exists) {
            throw new https.HttpsError("not-found", "Service not found");
        }

        const serviceData = serviceDoc.data()!;

        // 3. Security check - only owner can delete
        if (serviceData.technicianId !== technicianId) {
            console.log(`[TECH_SERVICE] Unauthorized delete attempt by ${technicianId}`);
            throw new https.HttpsError(
                "permission-denied",
                "You can only delete your own services"
            );
        }

        // 4. Soft delete - mark as inactive instead of deleting
        await db.collection('technician_services').doc(serviceId).update({
            isActive: false,
            deletedAt: admin.firestore.Timestamp.now(),
            updatedAt: admin.firestore.Timestamp.now()
        });

        console.log(`[TECH_SERVICE] Service deleted (soft) successfully: ${serviceId}`);

        return {
            success: true,
            serviceId: serviceId,
            message: 'Service deleted successfully'
        };
    }
);

/**
 * Get Technician Services
 * Returns all services for the authenticated technician
 */
export const getMyTechnicianServices = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 30,
        maxInstances: 5
    },
    async (request: CallableRequest) => {
        // 1. Authentication check
        if (!request.auth) {
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated"
            );
        }

        const technicianId = request.auth.uid;

        console.log(`[TECH_SERVICE] Fetching services for technician: ${technicianId}`);

        // 2. Get all active services for this technician (including inactive for management)
        const servicesSnapshot = await db.collection('technician_services')
            .where('technicianId', '==', technicianId)
            .orderBy('createdAt', 'desc')
            .get();

        const services = servicesSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                ...data,
                createdAt: data.createdAt?.toDate?.()?.toISOString(),
                updatedAt: data.updatedAt?.toDate?.()?.toISOString()
            };
        });

        console.log(`[TECH_SERVICE] Found ${services.length} services`);

        return {
            success: true,
            services: services,
            count: services.length
        };
    }
);

/**
 * Toggle Technician Service Status
 * Allows technicians to toggle their service active/inactive status
 */
export const toggleTechnicianServiceStatus = onCall(
    {
        region: "us-central1",
        cpu: 1,
        memory: "256MiB",
        timeoutSeconds: 30,
        maxInstances: 5
    },
    async (request: CallableRequest<{
        serviceId: string;
    }>) => {
        // 1. Authentication check
        if (!request.auth) {
            throw new https.HttpsError(
                "unauthenticated",
                "User must be authenticated to toggle service status"
            );
        }

        const technicianId = request.auth.uid;
        const { serviceId } = request.data;

        if (!serviceId) {
            throw new https.HttpsError("invalid-argument", "Service ID is required");
        }

        console.log(`[TECH_SERVICE] Toggling service ${serviceId} for technician: ${technicianId}`);

        // 1.1 Check if technician exists
        const techDoc = await db.collection('technicians').doc(technicianId).get();
        if (!techDoc.exists) {
            throw new https.HttpsError(
                "not-found",
                "Technician profile not found"
            );
        }

        // 2. Get the existing service
        const serviceDoc = await db.collection('technician_services').doc(serviceId).get();

        if (!serviceDoc.exists) {
            throw new https.HttpsError("not-found", "Service not found");
        }

        const serviceData = serviceDoc.data()!;

        // 3. Security check - only owner can toggle
        if (serviceData.technicianId !== technicianId) {
            console.log(`[TECH_SERVICE] Unauthorized toggle attempt by ${technicianId}`);
            throw new https.HttpsError(
                "permission-denied",
                "You can only toggle your own services"
            );
        }

        // 4. Toggle the isActive status
        const currentStatus = serviceData.isActive ?? true;
        const newStatus = !currentStatus;

        await db.collection('technician_services').doc(serviceId).update({
            isActive: newStatus,
            updatedAt: admin.firestore.Timestamp.now()
        });

        console.log(`[TECH_SERVICE] Service ${serviceId} toggled from ${currentStatus} to ${newStatus}`);

        return {
            success: true,
            serviceId: serviceId,
            isActive: newStatus,
            message: newStatus ? 'Service activated' : 'Service deactivated'
        };
    }
);
