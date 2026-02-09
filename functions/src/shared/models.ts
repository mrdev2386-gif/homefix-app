
import { firestore } from 'firebase-admin';

// --- SERVICE CATALOG ---

/**
 * Main Service Category (e.g., AC, Fridge, Fan)
 * Platform-controlled, admin-only editable
 */
export interface Service {
    id: string;
    name: string; // e.g., "Air Conditioner", "Refrigerator"
    slug: string; // e.g., "ac", "fridge"
    category: string; // e.g., "Appliances", "Electronics"
    icon: string; // Icon URL or name
    imageUrl?: string; // Service image
    description: string;
    isActive: boolean;
    isFeatured: boolean; // Show on homepage
    order: number; // Display order

    // Inspection configuration
    requiresInspection: boolean; // Does this service category require inspection?
    inspectionCharge: number; // Fixed inspection charge (0 if no inspection)
    inspectionDuration: number; // Estimated inspection time in minutes

    // Metadata (auto-calculated)
    metadata: {
        totalSubServices: number;
        activeSubServices: number;
        activeTechnicians: number;
        avgRating: number;
        totalBookings: number;
    };

    // Admin tracking
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    createdBy?: string; // Admin UID
    updatedBy?: string; // Admin UID
}

/**
 * Sub-Service (specific repair/task under a service)
 * Example: "Gas Refill" under "AC"
 * Pricing is FIXED and ADMIN-CONTROLLED ONLY
 */
export interface SubService {
    id: string;
    serviceId: string; // Parent service ID
    serviceName: string; // Denormalized for quick access

    name: string; // e.g., "Gas Refill", "Capacitor Replacement"
    slug: string; // e.g., "gas-refill", "capacitor-replacement"
    description: string;
    detailedDescription?: string; // Longer description for detail page

    isActive: boolean;

    // PRICING - Platform controlled, immutable by technicians/customers
    fixedPrice: number; // The ONLY price for this sub-service
    currency: string; // Default: "INR"

    // Service details
    estimatedDuration: number; // In minutes
    warrantyDays?: number; // Warranty period if applicable

    // Requirements
    requiredTools: string[]; // Tools needed
    requiredCertifications: string[]; // Certifications needed
    skillLevel: 'basic' | 'intermediate' | 'advanced'; // Skill level required

    // Inspection
    requiresInspection: boolean; // Override service-level inspection requirement
    canBeAddedAfterInspection: boolean; // Can tech add this during inspection?

    // Display
    order: number; // Display order within service
    imageUrl?: string; // Sub-service image
    tags?: string[]; // Searchable tags

    // Metadata (auto-calculated)
    metadata: {
        totalBookings: number;
        avgRating: number;
        completionRate: number;
    };

    // Admin tracking
    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    createdBy?: string; // Admin UID
    updatedBy?: string; // Admin UID
    priceHistory?: PriceHistoryEntry[]; // Track price changes
}

/**
 * Price History Entry
 * Tracks all price changes for audit and transparency
 */
export interface PriceHistoryEntry {
    oldPrice: number;
    newPrice: number;
    changedAt: firestore.Timestamp;
    changedBy: string; // Admin UID
    reason?: string; // Optional reason for price change
}

/**
 * Global Pricing Configuration
 * Stored in app_config/pricing
 */
export interface PricingConfig {
    // Global inspection settings
    defaultInspectionCharge: number;
    inspectionChargeRefundable: boolean; // If customer proceeds with repair

    // Platform fees
    platformFeePercentage: number; // % of booking value
    gstPercentage: number; // GST %

    // Payment settings
    currency: string; // Default: "INR"
    minBookingAmount: number;
    maxBookingAmount: number;

    // Pricing rules
    allowDynamicPricing: boolean; // Future: surge pricing
    allowDiscounts: boolean; // Can admins create discount codes?

    updatedAt: firestore.Timestamp;
    updatedBy: string; // Admin UID
}

// --- TECHNICIAN APPLICATION ---

export interface TechnicianApplication {
    id: string; // Same as auth UID
    phone: string;
    status: 'draft' | 'phone_verified' | 'kyc_submitted' | 'kyc_verified' | 'skills_verified' | 'submitted' | 'approved' | 'rejected';
    currentStep: number;

    personalDetails?: {
        name: string;
        dob: firestore.Timestamp;
        gender: string;
        photoUrl: string;
        address: string;
        coordinates: firestore.GeoPoint;
        city: string;
        serviceRadius: number;
    };

    kyc?: {
        idType: 'aadhaar' | 'pan' | 'driving_license';
        frontUrl: string;
        backUrl: string;
        selfieUrl: string;
        status: 'pending' | 'approved' | 'rejected';
        submittedAt: firestore.Timestamp;
        approvedAt?: firestore.Timestamp;
        approvedBy?: string;
        rejectionReason?: string;
        extractedData?: any;
    };

    skills?: {
        [serviceId: string]: {
            serviceId: string;
            serviceName: string;
            subServiceIds: string[];
            addedAt: firestore.Timestamp;
        };
    };

    experience?: {
        [serviceId: string]: {
            years: number;
            tools: string[];
            brands: string[];
            certifications: string[];
        };
    };

    availability?: {
        workingDays: number[]; // 1=Mon, 7=Sun
        startTime: string; // HH:mm
        endTime: string; // HH:mm
        emergencyAvailable: boolean;
        nightShift: boolean;
    };

    serviceArea?: {
        pinCodes: string[];
        radius: number;
        coordinates?: firestore.GeoPoint; // Center point
    };

    bankDetails?: {
        accountNumber: string; // Encrypted
        ifsc: string;
        holderName: string;
        upiId?: string;
        verified: boolean;
    };

    training?: {
        videoWatched: boolean;
        rulesAccepted: boolean;
        completedAt: firestore.Timestamp;
    };

    deviceInfo?: {
        deviceId: string;
        platform: string;
        appVersion: string;
    };

    createdAt: firestore.Timestamp;
    updatedAt: firestore.Timestamp;
    submittedAt?: firestore.Timestamp;
}

// --- TECHNICIAN PROFILE ---

export interface Technician extends Omit<TechnicianApplication, 'id' | 'currentStep' | 'bankDetails' | 'training'> {
    // Fields from application are copied here upon approval

    isActive: boolean; // Technician toggle
    isOnline: boolean; // Real-time toggle
    status: 'active' | 'suspended' | 'pending_verification' | 'approved';

    rating: number;
    totalJobs: number;
    completedJobs: number;
    cancelledJobs: number;

    lastLocation?: firestore.GeoPoint;
    lastSeen?: firestore.Timestamp;
    geohash?: string; // For geo-queries

    fcmToken?: string;
}

// --- BOOKING ---

/**
 * Booking with Urban Company-style inspection and approval flow
 * Pricing is IMMUTABLE once customer approves
 */
export interface Booking {
    id: string;
    bookingNumber: string; // Human-readable booking number (e.g., "BK-2026-0001")

    // Parties
    customerId: string;
    customerName: string; // Denormalized
    customerPhone: string; // Denormalized

    technicianId?: string; // Assigned technician
    technicianName?: string; // Denormalized
    technicianPhone?: string; // Denormalized

    // Service
    serviceId: string;
    serviceName: string; // Denormalized

    // Location
    location: {
        address: string;
        coordinates: firestore.GeoPoint;
        pinCode?: string;
        city?: string;
    };

    // Booking flow status
    status:
    | 'pending'              // Created, waiting for tech assignment
    | 'assigned'             // Tech assigned, not yet accepted
    | 'accepted'             // Tech accepted
    | 'inspection_scheduled' // Inspection scheduled
    | 'inspection_in_progress' // Tech is inspecting
    | 'awaiting_approval'    // Waiting for customer approval of quote
    | 'approved'             // Customer approved quote
    | 'in_progress'          // Work in progress
    | 'completed'            // Work completed
    | 'cancelled'            // Cancelled by customer/tech/admin
    | 'rejected';            // Tech rejected or customer rejected quote

    // Inspection flow
    requiresInspection: boolean;
    inspectionCharge: number; // Locked at booking creation
    inspectionCompleted: boolean;
    inspectionCompletedAt?: firestore.Timestamp;
    inspectionNotes?: string; // Tech's inspection notes
    inspectionImages?: string[]; // Images from inspection

    // Pricing - IMMUTABLE after customer approval
    pricing: {
        // Inspection
        inspectionCharge: number;

        // Sub-services (itemized)
        subServices: BookingSubService[];

        // Calculations
        subtotal: number; // Sum of all sub-service prices
        platformFee: number;
        gst: number;
        total: number;

        // Pricing snapshot (locked at approval)
        pricingLockedAt?: firestore.Timestamp;
        pricingApprovedBy?: string; // Customer UID
    };

    // Customer approval
    customerApproval?: {
        approved: boolean;
        approvedAt: firestore.Timestamp;
        rejectedReason?: string; // If rejected
        approvalMethod: 'app' | 'sms' | 'call'; // How they approved
    };

    // Scheduling
    scheduledTime?: firestore.Timestamp;
    preferredTimeSlot?: string; // e.g., "morning", "afternoon", "evening"

    // Timestamps
    createdAt: firestore.Timestamp;
    assignedAt?: firestore.Timestamp;
    acceptedAt?: firestore.Timestamp;
    startedAt?: firestore.Timestamp;
    completedAt?: firestore.Timestamp;
    cancelledAt?: firestore.Timestamp;

    // Payment
    paymentStatus: 'pending' | 'inspection_paid' | 'partially_paid' | 'paid' | 'refunded';
    paymentMethod?: 'cash' | 'online' | 'wallet';
    razorpayOrderId?: string;
    razorpayPaymentId?: string;

    // Cancellation
    cancellationReason?: string;
    cancelledBy?: 'customer' | 'technician' | 'admin' | 'system';
    refundAmount?: number;
    refundStatus?: 'pending' | 'processed' | 'failed';

    // Rating & Feedback
    rating?: number;
    feedback?: string;
    ratedAt?: firestore.Timestamp;

    // Admin notes
    adminNotes?: string;
    flagged?: boolean;
    flagReason?: string;
}

/**
 * Sub-service item in a booking
 * Pricing is locked from the master catalog at the time of selection
 */
export interface BookingSubService {
    subServiceId: string;
    subServiceName: string;
    description: string;

    // Price locked from catalog
    fixedPrice: number;
    quantity: number; // Usually 1, but can be more (e.g., 2 fans)
    totalPrice: number; // fixedPrice * quantity

    // Metadata
    addedBy: 'customer' | 'technician'; // Who added this item
    addedAt: firestore.Timestamp;
    addedDuringInspection: boolean; // Was this added after inspection?

    // Completion tracking
    completed: boolean;
    completedAt?: firestore.Timestamp;
    warrantyDays?: number;
    warrantyExpiresAt?: firestore.Timestamp;
}
